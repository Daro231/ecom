package com.ecom.service.impl;

import com.ecom.common.exception.BadRequestException;
import com.ecom.common.exception.PaymentGatewayException;
import com.ecom.common.exception.ResourceNotFoundException;
import com.ecom.common.response.PageResponse;
import com.ecom.config.KhqrProperties;
import com.ecom.model.entity.Order;
import com.ecom.model.entity.Payment;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.PaymentCallbackRequest;
import com.ecom.model.response.KhqrResponse;
import com.ecom.model.response.PaymentResponse;
import com.ecom.repository.OrderRepository;
import com.ecom.repository.PaymentRepository;
import com.ecom.service.*;
import com.ecom.util.PageUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentServiceImpl implements PaymentService {
    private static final int MAX_CONSECUTIVE_FAILURES = 3;

    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;
    private final OrderService orderService;
    private final KhqrGateway khqrGateway;
    private final NotificationService notificationService;
    private final KhqrProperties properties;
    private final KhqrSettlement settlement;

    @Override
    @Transactional
    public KhqrResponse generateKhqr(Long userId, String orderNumber) {
        Order order = orderRepository.findByOrderNumberAndUserId(orderNumber, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found"));
        Payment payment = paymentFor(order);
        if (payment.getMethod() != PaymentMethod.KHQR) {
            throw new BadRequestException("Order was not placed with KHQR payment");
        }
        if (order.getStatus() == OrderStatus.CANCELLED) {
            throw new BadRequestException("Order has been cancelled");
        }
        if (payment.getStatus() == PaymentStatus.FAILED && KhqrSettlement.EXPIRED_REASON.equals(payment.getFailureReason())) {
            payment.setStatus(PaymentStatus.PENDING);
            payment.setFailureReason(null);
        }
        if (payment.getStatus() != PaymentStatus.PENDING) {
            throw new BadRequestException("Payment is already " + payment.getStatus());
        }
        LocalDateTime now = LocalDateTime.now();
        if (payment.getKhqrString() == null || payment.getKhqrExpiresAt() == null || !payment.getKhqrExpiresAt().isAfter(now)) {
            KhqrGateway.KhqrPayload qr = khqrGateway.generate(order.getOrderNumber(), payment.getAmount(),
                    now.plusMinutes(properties.getExpiryMinutes()));
            payment.setKhqrString(qr.qrPayload());
            payment.setKhqrMd5(qr.md5());
            payment.setKhqrExpiresAt(qr.expiresAt());
            payment.setTransactionRef("KHQR-" + qr.md5().substring(0, 12).toUpperCase());
            payment.setLastCheckedAt(null);
        }
        return new KhqrResponse(order.getOrderNumber(), khqrGateway.gatewayAmount(payment.getAmount()), khqrGateway.currency(),
                payment.getKhqrString(), payment.getKhqrString(), payment.getKhqrMd5(), payment.getKhqrExpiresAt(), properties.getMode());
    }

    /** Not transactional on purpose: the Bakong call must not hold a database connection. */
    @Override
    public PaymentResponse status(Long userId, String orderNumber) {
        Payment payment = paymentRepository.findByOrder_OrderNumberAndOrder_User_Id(orderNumber, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found"));
        if (isCheckable(payment) && settlement.claimCheck(payment.getId())) {
            settlement.apply(payment.getId(), khqrGateway.checkStatus(payment.getKhqrMd5()));
            payment = reload(payment.getId());
        }
        return PaymentResponse.from(payment);
    }

    @Override
    public PaymentResponse recheck(String orderNumber) {
        if (!properties.isBakong()) {
            throw new BadRequestException("Re-checking is only available when payment.khqr.mode=bakong");
        }
        Payment payment = paymentRepository.findByOrder_OrderNumber(orderNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found"));
        if (payment.getStatus() == PaymentStatus.PENDING && payment.getKhqrMd5() != null) {
            settlement.apply(payment.getId(), khqrGateway.checkStatus(payment.getKhqrMd5()));
            payment = reload(payment.getId());
        }
        return PaymentResponse.from(payment);
    }

    @Override
    public int reconcilePending() {
        settlement.expireStale();
        int settled = 0;
        int consecutiveFailures = 0;
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(properties.getExpiryGraceMinutes());
        for (Payment payment : paymentRepository.findPendingKhqr(cutoff)) {
            if (!settlement.claimCheck(payment.getId())) {
                continue;
            }
            try {
                KhqrSettlement.Outcome outcome = settlement.apply(payment.getId(), khqrGateway.checkStatus(payment.getKhqrMd5()));
                consecutiveFailures = 0;
                if (outcome == KhqrSettlement.Outcome.CONFIRMED) {
                    settled++;
                }
            } catch (PaymentGatewayException ex) {
                log.warn("KHQR check failed for order {}: {}", payment.getOrder().getOrderNumber(), ex.getMessage());
                if (++consecutiveFailures >= MAX_CONSECUTIVE_FAILURES) {
                    log.warn("Giving up this KHQR reconciliation round after {} failures in a row", consecutiveFailures);
                    break;
                }
            }
        }
        return settled;
    }

    @Override
    public int cancelUnpaidKhqrOrders() {
        if (properties.getAutoCancelMinutes() <= 0) {
            return 0;
        }
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(properties.getAutoCancelMinutes());
        int cancelled = 0;
        for (Long orderId : orderRepository.findUnpaidKhqrOrderIds(cutoff)) {
            try {
                if (settlement.cancelUnpaid(orderId)) {
                    cancelled++;
                }
            } catch (RuntimeException ex) {
                log.warn("Could not auto-cancel order {}: {}", orderId, ex.getMessage());
            }
        }
        return cancelled;
    }

    /** Not transactional: Bakong calls must not hold a database connection. */
    @Override
    public int checkLatePayments() {
        if (!properties.isBakong() || properties.getLatePaymentWatchHours() <= 0) {
            return 0;
        }
        int found = 0;
        int consecutiveFailures = 0;
        for (Payment payment : paymentRepository.findLateWatch(LocalDateTime.now())) {
            if (!settlement.claimLateCheck(payment.getId())) {
                continue;
            }
            try {
                KhqrSettlement.Outcome outcome = settlement.applyLate(payment.getId(), khqrGateway.checkStatus(payment.getKhqrMd5()));
                consecutiveFailures = 0;
                if (outcome == KhqrSettlement.Outcome.CONFIRMED) {
                    found++;
                }
            } catch (PaymentGatewayException ex) {
                log.warn("Late-payment check failed for order {}: {}", payment.getOrder().getOrderNumber(), ex.getMessage());
                if (++consecutiveFailures >= MAX_CONSECUTIVE_FAILURES) {
                    break;
                }
            }
        }
        return found;
    }

    @Override
    @Transactional
    public PaymentResponse refund(String idOrOrderNumber) {
        if (idOrOrderNumber.chars().allMatch(Character::isDigit)) {
            return refund(Long.parseLong(idOrOrderNumber));
        }
        Payment payment = paymentRepository.findByOrder_OrderNumber(idOrOrderNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Payment not found"));
        return refund(payment.getId());
    }

    private boolean isCheckable(Payment payment) {
        return properties.isBakong() && payment.getStatus() == PaymentStatus.PENDING && payment.getKhqrMd5() != null
                && payment.getKhqrExpiresAt() != null
                && payment.getKhqrExpiresAt().plusMinutes(properties.getExpiryGraceMinutes()).isAfter(LocalDateTime.now());
    }

    private Payment reload(Long id) {
        return paymentRepository.findWithOrderById(id).orElseThrow(() -> new ResourceNotFoundException("Payment not found"));
    }

    /** Simulated gateway webhook; real Bakong sends none, so it only exists in mock mode. */
    @Override
    @Transactional
    public PaymentResponse callback(PaymentCallbackRequest request) {
        if (properties.isBakong()) {
            throw new ResourceNotFoundException("Not found");
        }
        Order order = orderService.findOrder(request.orderNumber());
        Payment payment = paymentFor(order);
        if (payment.getStatus() == PaymentStatus.PAID || payment.getStatus() == PaymentStatus.REFUNDED) {
            return PaymentResponse.from(payment);
        }
        if (order.getStatus() == OrderStatus.CANCELLED) {
            throw new BadRequestException("Order has been cancelled");
        }
        switch (request.status()) {
            case PAID -> {
                payment.setStatus(PaymentStatus.PAID);
                payment.setTransactionRef(request.transactionRef());
                payment.setPaidAt(LocalDateTime.now());
                if (order.getStatus() == OrderStatus.PENDING) {
                    orderService.changeStatus(order, OrderStatus.CONFIRMED, null);
                }
                notificationService.notifyUser(order.getUser(), NotificationType.EMAIL, "Payment received",
                        "Payment of $" + payment.getAmount() + " was successful for order " + order.getOrderNumber());
            }
            case FAILED -> {
                payment.setStatus(PaymentStatus.FAILED);
                payment.setTransactionRef(request.transactionRef());
            }
            default -> throw new BadRequestException("Unsupported callback status: " + request.status());
        }
        return PaymentResponse.from(payment);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<PaymentResponse> adminList(PaymentStatus status, int page, int size) {
        Pageable pageable = PageUtil.newestFirst(page, size);
        Page<Payment> result = status == null ? paymentRepository.findAll(pageable) : paymentRepository.findByStatus(status, pageable);
        return PageResponse.of(result, PaymentResponse::from);
    }

    @Override
    @Transactional
    public PaymentResponse refund(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId).orElseThrow(() -> new ResourceNotFoundException("Payment not found"));
        if (payment.getStatus() != PaymentStatus.PAID && payment.getStatus() != PaymentStatus.PAID_AFTER_CANCEL) {
            throw new BadRequestException("Only PAID payments can be refunded");
        }
        payment.setStatus(PaymentStatus.REFUNDED);
        notificationService.notifyUser(payment.getOrder().getUser(), NotificationType.EMAIL, "Payment refunded",
                "Your payment of $" + payment.getAmount() + " for order " + payment.getOrder().getOrderNumber() + " was refunded.");
        return PaymentResponse.from(payment);
    }

    private Payment paymentFor(Order order) {
        return paymentRepository.findByOrderId(order.getId()).orElseThrow(() -> new ResourceNotFoundException("Payment not found"));
    }
}
