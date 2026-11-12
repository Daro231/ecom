package com.ecom.service.impl;

import com.ecom.common.exception.ResourceNotFoundException;
import com.ecom.config.KhqrProperties;
import com.ecom.model.entity.Order;
import com.ecom.model.entity.Payment;
import com.ecom.model.enumerate.NotificationPriority;
import com.ecom.model.enumerate.NotificationType;
import com.ecom.model.enumerate.OrderStatus;
import com.ecom.model.enumerate.PaymentStatus;
import com.ecom.repository.OrderRepository;
import com.ecom.repository.PaymentRepository;
import com.ecom.service.KhqrCheckResult;
import com.ecom.service.KhqrGateway;
import com.ecom.service.NotificationService;
import com.ecom.service.OrderService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * The transactional steps of KHQR settlement. Kept in its own bean so each step commits on its own, and so the
 * polling endpoint and the scheduled reconciler can race safely: only the caller whose conditional UPDATE
 * (PENDING -> PAID) hits a row confirms the order and sends the notification.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class KhqrSettlement {
    public static final String EXPIRED_REASON = "QR expired";
    public static final String TIMEOUT_REASON = "KHQR payment timeout";
    public static final String LATE_PAYMENT_REASON = "Paid after auto-cancel";
    public static final String LATE_PAYMENT_TITLE = "Customer paid after cancel - refund or restore order";

    public enum Outcome {
        CONFIRMED, ALREADY_DONE, REJECTED, NOT_PAID
    }

    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;
    private final OrderService orderService;
    private final NotificationService notificationService;
    private final KhqrGateway gateway;
    private final KhqrProperties properties;

    /** Reserves the right to call Bakong for this payment (at most one call per min-check-interval). */
    @Transactional
    public boolean claimCheck(Long paymentId) {
        LocalDateTime now = LocalDateTime.now();
        return paymentRepository.claimCheck(paymentId, now, now.minusSeconds(properties.getMinCheckIntervalSeconds())) == 1;
    }

    @Transactional
    public Outcome apply(Long paymentId, KhqrCheckResult result) {
        if (result.status() != KhqrCheckResult.Status.PAID) {
            return Outcome.NOT_PAID;
        }
        Payment payment = paymentRepository.findWithOrderById(paymentId)
                .orElseThrow(() -> new ResourceNotFoundException("Payment not found"));
        if (payment.getStatus() != PaymentStatus.PENDING) {
            return Outcome.ALREADY_DONE;
        }
        Order order = payment.getOrder();

        String mismatch = mismatch(payment, result);
        if (mismatch != null) {
            if (paymentRepository.markFailedIfPending(paymentId, mismatch) == 1) {
                payment.setStatus(PaymentStatus.FAILED);
                payment.setFailureReason(mismatch);
                log.error("KHQR payment for order {} rejected: {}", order.getOrderNumber(), mismatch);
                notificationService.notifyAdmins(NotificationType.EMAIL, "KHQR payment needs attention",
                        "Order " + order.getOrderNumber() + ": " + mismatch + ". Bakong hash: " + result.hash());
            }
            return Outcome.REJECTED;
        }

        String reference = result.hash() != null ? result.hash() : payment.getKhqrMd5();
        LocalDateTime paidAt = result.paidAt() != null ? result.paidAt() : LocalDateTime.now();
        if (paymentRepository.markPaidIfPending(paymentId, paidAt, reference, result.hash(), result.fromAccountId()) == 0) {
            return Outcome.ALREADY_DONE;
        }
        payment.setStatus(PaymentStatus.PAID);
        payment.setPaidAt(paidAt);
        payment.setTransactionRef(reference);
        payment.setBakongHash(result.hash());
        payment.setFromAccountId(result.fromAccountId());

        if (order.getStatus() == OrderStatus.PENDING) {
            orderService.changeStatus(order, OrderStatus.CONFIRMED, null);
        }
        notificationService.notifyUser(order.getUser(), NotificationType.EMAIL, "Payment received",
                "Payment of $" + payment.getAmount() + " was successful for order " + order.getOrderNumber());
        return Outcome.CONFIRMED;
    }

    /**
     * Cancels one KHQR order that was never paid: stock is restored (InventoryLog CANCEL), the payment becomes FAILED and
     * the customer is notified, all through the normal cancel logic. Returns false when the order was left alone.
     */
    @Transactional
    public boolean cancelUnpaid(Long orderId) {
        Order order = orderRepository.findById(orderId).orElse(null);
        if (order == null || order.getStatus() != OrderStatus.PENDING) {
            return false;
        }
        Payment payment = paymentRepository.findByOrderId(orderId).orElse(null);
        if (payment == null || payment.getStatus() == PaymentStatus.PAID || payment.getStatus() == PaymentStatus.REFUNDED) {
            return false;
        }
        if (payment.getStatus() == PaymentStatus.PENDING) {
            // conditional update: if a payment was confirmed a moment ago this affects no row and we back off
            if (paymentRepository.markFailedIfPending(payment.getId(), TIMEOUT_REASON) == 0) {
                return false;
            }
            payment.setStatus(PaymentStatus.FAILED);
            payment.setFailureReason(TIMEOUT_REASON);
            if (properties.isBakong() && properties.getLatePaymentWatchHours() > 0 && payment.getKhqrMd5() != null) {
                payment.setLateWatchUntil(LocalDateTime.now().plusHours(properties.getLatePaymentWatchHours()));
            }
        }
        orderService.changeStatus(order, OrderStatus.CANCELLED, TIMEOUT_REASON);
        log.info("Order {} cancelled: KHQR payment not received in time", order.getOrderNumber());
        return true;
    }

    /** Reserves a Bakong check for an auto-cancelled payment that is still being watched. */
    @Transactional
    public boolean claimLateCheck(Long paymentId) {
        LocalDateTime now = LocalDateTime.now();
        return paymentRepository.claimLateCheck(paymentId, now, now.minusSeconds(properties.getMinCheckIntervalSeconds())) == 1;
    }

    /**
     * A customer paid a KHQR order after it was auto-cancelled. The order stays CANCELLED and stock is NOT re-reserved;
     * the payment becomes PAID_AFTER_CANCEL and admins get a high-priority notification to refund or restore.
     * A paid QR that does not match amount/currency/account stops the watch and alerts admins once.
     */
    @Transactional
    public Outcome applyLate(Long paymentId, KhqrCheckResult result) {
        if (result.status() != KhqrCheckResult.Status.PAID) {
            return Outcome.NOT_PAID;
        }
        Payment payment = paymentRepository.findWithOrderById(paymentId)
                .orElseThrow(() -> new ResourceNotFoundException("Payment not found"));
        if (payment.getStatus() != PaymentStatus.FAILED || payment.getLateWatchUntil() == null
                || payment.getOrder().getStatus() != OrderStatus.CANCELLED) {
            return Outcome.ALREADY_DONE;
        }
        Order order = payment.getOrder();
        String mismatch = mismatch(payment, result);
        if (mismatch != null) {
            if (paymentRepository.stopLateWatch(paymentId) == 1) {
                log.error("Late KHQR payment for cancelled order {} rejected: {}", order.getOrderNumber(), mismatch);
                notificationService.notifyAdmins(NotificationType.EMAIL, NotificationPriority.HIGH, "KHQR payment needs attention",
                        "Cancelled order " + order.getOrderNumber() + " received a Bakong payment that does not match: " + mismatch
                                + ". Bakong hash: " + result.hash());
            }
            return Outcome.REJECTED;
        }
        String reference = result.hash() != null ? result.hash() : payment.getKhqrMd5();
        LocalDateTime paidAt = result.paidAt() != null ? result.paidAt() : LocalDateTime.now();
        if (paymentRepository.markPaidAfterCancel(paymentId, paidAt, reference, result.hash(), result.fromAccountId(),
                LATE_PAYMENT_REASON) == 0) {
            return Outcome.ALREADY_DONE;
        }
        payment.setStatus(PaymentStatus.PAID_AFTER_CANCEL);
        payment.setPaidAt(paidAt);
        payment.setTransactionRef(reference);
        payment.setBakongHash(result.hash());
        payment.setFromAccountId(result.fromAccountId());
        payment.setLateWatchUntil(null);
        payment.setFailureReason(LATE_PAYMENT_REASON);
        notificationService.notifyAdmins(NotificationType.EMAIL, NotificationPriority.HIGH, LATE_PAYMENT_TITLE,
                "Order " + order.getOrderNumber() + " was auto-cancelled, but the customer paid $" + payment.getAmount()
                        + " afterwards (Bakong hash " + result.hash() + "). Restore the order "
                        + "(POST /admin/orders/" + order.getOrderNumber() + "/restore-after-payment) or refund it "
                        + "(POST /admin/payments/" + order.getOrderNumber() + "/refund).");
        return Outcome.CONFIRMED;
    }

    /** Marks KHQR payments FAILED once the QR and its grace period are over; the order stays PENDING. */
    @Transactional
    public int expireStale() {
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(properties.getExpiryGraceMinutes());
        List<Long> ids = paymentRepository.findExpiredPendingKhqrIds(cutoff);
        int expired = 0;
        for (Long id : ids) {
            expired += paymentRepository.markFailedIfPending(id, EXPIRED_REASON);
        }
        return expired;
    }

    private String mismatch(Payment payment, KhqrCheckResult result) {
        String expectedCurrency = gateway.currency();
        if (result.currency() == null || !expectedCurrency.equalsIgnoreCase(result.currency())) {
            return "Currency mismatch: expected " + expectedCurrency + ", received " + result.currency();
        }
        java.math.BigDecimal expected = gateway.gatewayAmount(payment.getAmount());
        if (result.amount() == null || result.amount().compareTo(expected) != 0) {
            return "Amount mismatch: expected " + expected.toPlainString() + " " + expectedCurrency + ", received "
                    + (result.amount() == null ? "none" : result.amount().toPlainString());
        }
        if (result.toAccountId() == null || !result.toAccountId().equalsIgnoreCase(gateway.accountId())) {
            return "Receiving account mismatch: expected " + gateway.accountId() + ", received " + result.toAccountId();
        }
        return null;
    }
}
