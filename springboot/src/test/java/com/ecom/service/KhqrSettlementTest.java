package com.ecom.service;

import com.ecom.common.exception.ResourceNotFoundException;
import com.ecom.config.KhqrProperties;
import com.ecom.model.entity.Order;
import com.ecom.model.entity.Payment;
import com.ecom.model.entity.User;
import com.ecom.model.enumerate.NotificationType;
import com.ecom.model.enumerate.OrderStatus;
import com.ecom.model.enumerate.PaymentMethod;
import com.ecom.model.enumerate.PaymentStatus;
import com.ecom.repository.OrderRepository;
import com.ecom.repository.PaymentRepository;
import com.ecom.service.impl.KhqrSettlement;
import com.ecom.service.impl.KhqrSettlement.Outcome;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class KhqrSettlementTest {
    @Mock
    PaymentRepository paymentRepository;
    @Mock
    OrderRepository orderRepository;
    @Mock
    OrderService orderService;
    @Mock
    NotificationService notificationService;
    @Mock
    KhqrGateway gateway;
    @Spy
    KhqrProperties properties = new KhqrProperties();
    @InjectMocks
    KhqrSettlement settlement;

    User user;
    Order order;
    Payment payment;

    @BeforeEach
    void setUp() {
        user = TestData.user(1);
        order = TestData.order(1, user, OrderStatus.PENDING);
        payment = TestData.payment(order, PaymentMethod.KHQR, PaymentStatus.PENDING);
        payment.setKhqrMd5("md5-1");
        lenient().when(gateway.currency()).thenReturn("USD");
        lenient().when(gateway.accountId()).thenReturn("shop@bank");
        lenient().when(gateway.gatewayAmount(any())).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(paymentRepository.findWithOrderById(1L)).thenReturn(Optional.of(payment));
    }

    private KhqrCheckResult paid(String amount, String currency, String to) {
        return new KhqrCheckResult(KhqrCheckResult.Status.PAID, "hash-1", "buyer@bank", to,
                amount == null ? null : new BigDecimal(amount), currency, LocalDateTime.now());
    }

    @Test
    void matchingTransactionMarksPaidConfirmsOrderAndNotifiesOnce() {
        when(paymentRepository.markPaidIfPending(eq(1L), any(), eq("hash-1"), eq("hash-1"), eq("buyer@bank"))).thenReturn(1);

        Outcome outcome = settlement.apply(1L, paid("105.00", "USD", "shop@bank"));

        assertThat(outcome).isEqualTo(Outcome.CONFIRMED);
        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.PAID);
        assertThat(payment.getBakongHash()).isEqualTo("hash-1");
        assertThat(payment.getFromAccountId()).isEqualTo("buyer@bank");
        verify(orderService).changeStatus(order, OrderStatus.CONFIRMED, null);
        verify(notificationService).notifyUser(eq(user), eq(NotificationType.EMAIL), eq("Payment received"), contains("$105.00"));
    }

    @Test
    void amountWithDifferentScaleStillMatches() {
        when(paymentRepository.markPaidIfPending(eq(1L), any(), any(), any(), any())).thenReturn(1);

        assertThat(settlement.apply(1L, paid("105", "usd", "SHOP@bank"))).isEqualTo(Outcome.CONFIRMED);
    }

    @Test
    void confirmingTwiceRunsTheSideEffectsOnlyOnce() {
        when(paymentRepository.markPaidIfPending(eq(1L), any(), any(), any(), any())).thenReturn(1, 0);

        assertThat(settlement.apply(1L, paid("105.00", "USD", "shop@bank"))).isEqualTo(Outcome.CONFIRMED);
        // a concurrent caller loaded the payment before the first commit but loses the conditional update
        payment.setStatus(PaymentStatus.PENDING);
        assertThat(settlement.apply(1L, paid("105.00", "USD", "shop@bank"))).isEqualTo(Outcome.ALREADY_DONE);

        verify(orderService, times(1)).changeStatus(any(), any(), any());
        verify(notificationService, times(1)).notifyUser(any(), any(), any(), any());
    }

    @Test
    void alreadyPaidPaymentIsLeftAlone() {
        payment.setStatus(PaymentStatus.PAID);

        assertThat(settlement.apply(1L, paid("105.00", "USD", "shop@bank"))).isEqualTo(Outcome.ALREADY_DONE);
        verify(paymentRepository, never()).markPaidIfPending(any(), any(), any(), any(), any());
    }

    @Test
    void amountMismatchFailsThePaymentAndAlertsAdmins() {
        when(paymentRepository.markFailedIfPending(eq(1L), contains("Amount mismatch"))).thenReturn(1);

        assertThat(settlement.apply(1L, paid("100.00", "USD", "shop@bank"))).isEqualTo(Outcome.REJECTED);

        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.FAILED);
        assertThat(payment.getFailureReason()).contains("expected 105.00 USD").contains("received 100.00");
        verify(notificationService).notifyAdmins(eq(NotificationType.EMAIL), anyString(), contains(order.getOrderNumber()));
        verify(paymentRepository, never()).markPaidIfPending(any(), any(), any(), any(), any());
        verifyNoInteractions(orderService);
    }

    @Test
    void missingAmountIsAMismatch() {
        when(paymentRepository.markFailedIfPending(eq(1L), contains("received none"))).thenReturn(1);

        assertThat(settlement.apply(1L, paid(null, "USD", "shop@bank"))).isEqualTo(Outcome.REJECTED);
    }

    @Test
    void currencyMismatchFailsThePayment() {
        when(paymentRepository.markFailedIfPending(eq(1L), contains("Currency mismatch"))).thenReturn(1);

        assertThat(settlement.apply(1L, paid("105.00", "KHR", "shop@bank"))).isEqualTo(Outcome.REJECTED);
        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.FAILED);
        verifyNoInteractions(orderService);
    }

    @Test
    void wrongReceivingAccountFailsThePayment() {
        when(paymentRepository.markFailedIfPending(eq(1L), contains("Receiving account"))).thenReturn(1);

        assertThat(settlement.apply(1L, paid("105.00", "USD", "someone-else@bank"))).isEqualTo(Outcome.REJECTED);
        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.FAILED);
    }

    @Test
    void rejectionIsReportedOnlyByTheCallerThatWinsTheUpdate() {
        when(paymentRepository.markFailedIfPending(eq(1L), anyString())).thenReturn(0);

        assertThat(settlement.apply(1L, paid("1.00", "USD", "shop@bank"))).isEqualTo(Outcome.REJECTED);
        verifyNoInteractions(notificationService);
    }

    @Test
    void unpaidResultsChangeNothing() {
        assertThat(settlement.apply(1L, KhqrCheckResult.notFound())).isEqualTo(Outcome.NOT_PAID);
        assertThat(settlement.apply(1L, KhqrCheckResult.failed())).isEqualTo(Outcome.NOT_PAID);
        verifyNoInteractions(paymentRepository, orderService);
    }

    @Test
    void unknownPaymentIsNotFound() {
        when(paymentRepository.findWithOrderById(9L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> settlement.apply(9L, paid("1", "USD", "shop@bank"))).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void alreadyConfirmedOrderIsNotConfirmedAgain() {
        order.setStatus(OrderStatus.CONFIRMED);
        when(paymentRepository.markPaidIfPending(eq(1L), any(), any(), any(), any())).thenReturn(1);

        assertThat(settlement.apply(1L, paid("105.00", "USD", "shop@bank"))).isEqualTo(Outcome.CONFIRMED);
        verify(orderService, never()).changeStatus(any(), any(), any());
    }

    @Test
    void claimCheckUsesTheConfiguredInterval() {
        when(paymentRepository.claimCheck(eq(1L), any(LocalDateTime.class), any(LocalDateTime.class))).thenReturn(1, 0);

        assertThat(settlement.claimCheck(1L)).isTrue();
        assertThat(settlement.claimCheck(1L)).isFalse();
    }

    @Test
    void expireStaleFailsEveryExpiredPendingPayment() {
        when(paymentRepository.findExpiredPendingKhqrIds(any(LocalDateTime.class))).thenReturn(List.of(1L, 2L));
        when(paymentRepository.markFailedIfPending(anyLong(), eq(KhqrSettlement.EXPIRED_REASON))).thenReturn(1);

        assertThat(settlement.expireStale()).isEqualTo(2);
    }

    // ---------- auto-cancel of unpaid KHQR orders ----------
    private void unpaidOrder() {
        when(orderRepository.findById(1L)).thenReturn(Optional.of(order));
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));
    }

    @Test
    void unpaidOrderIsCancelledWithTheTimeoutReasonAndItsPaymentFailed() {
        unpaidOrder();
        when(paymentRepository.markFailedIfPending(1L, KhqrSettlement.TIMEOUT_REASON)).thenReturn(1);

        assertThat(settlement.cancelUnpaid(1L)).isTrue();

        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.FAILED);
        assertThat(payment.getFailureReason()).isEqualTo("KHQR payment timeout");
        verify(orderService).changeStatus(order, OrderStatus.CANCELLED, "KHQR payment timeout");
    }

    @Test
    void orderWhoseQrExpiredEarlierIsStillCancelled() {
        unpaidOrder();
        payment.setStatus(PaymentStatus.FAILED);
        payment.setFailureReason(KhqrSettlement.EXPIRED_REASON);

        assertThat(settlement.cancelUnpaid(1L)).isTrue();

        verify(paymentRepository, never()).markFailedIfPending(any(), any());
        verify(orderService).changeStatus(order, OrderStatus.CANCELLED, "KHQR payment timeout");
    }

    @Test
    void paymentConfirmedAMomentAgoWinsTheRace() {
        unpaidOrder();
        when(paymentRepository.markFailedIfPending(1L, KhqrSettlement.TIMEOUT_REASON)).thenReturn(0);

        assertThat(settlement.cancelUnpaid(1L)).isFalse();

        verifyNoInteractions(orderService);
        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.PENDING);
    }

    @Test
    void paidOrdersAndOrdersPastPendingAreNeverCancelled() {
        unpaidOrder();
        payment.setStatus(PaymentStatus.PAID);
        assertThat(settlement.cancelUnpaid(1L)).isFalse();

        payment.setStatus(PaymentStatus.PENDING);
        order.setStatus(OrderStatus.CONFIRMED);
        assertThat(settlement.cancelUnpaid(1L)).isFalse();

        when(orderRepository.findById(2L)).thenReturn(Optional.empty());
        assertThat(settlement.cancelUnpaid(2L)).isFalse();
        verifyNoInteractions(orderService);
    }

    @Test
    void orderWithoutPaymentIsLeftAlone() {
        when(orderRepository.findById(1L)).thenReturn(Optional.of(order));
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.empty());

        assertThat(settlement.cancelUnpaid(1L)).isFalse();
    }

    // ---------- late payments after auto-cancel ----------
    private void cancelledAndWatched() {
        order.setStatus(OrderStatus.CANCELLED);
        payment.setStatus(PaymentStatus.FAILED);
        payment.setFailureReason(KhqrSettlement.TIMEOUT_REASON);
        payment.setLateWatchUntil(LocalDateTime.now().plusHours(24));
    }

    @Test
    void autoCancelInBakongModeStartsTheLatePaymentWatch() {
        properties.setMode(com.ecom.model.enumerate.KhqrMode.BAKONG);
        unpaidOrder();
        when(paymentRepository.markFailedIfPending(1L, KhqrSettlement.TIMEOUT_REASON)).thenReturn(1);

        assertThat(settlement.cancelUnpaid(1L)).isTrue();

        assertThat(payment.getLateWatchUntil()).isBetween(LocalDateTime.now().plusHours(24).minusMinutes(1),
                LocalDateTime.now().plusHours(24).plusMinutes(1));
    }

    @Test
    void watchWindowFollowsTheConfiguredHours() {
        properties.setMode(com.ecom.model.enumerate.KhqrMode.BAKONG);
        properties.setLatePaymentWatchHours(2);
        unpaidOrder();
        when(paymentRepository.markFailedIfPending(1L, KhqrSettlement.TIMEOUT_REASON)).thenReturn(1);

        settlement.cancelUnpaid(1L);

        assertThat(payment.getLateWatchUntil()).isBefore(LocalDateTime.now().plusHours(2).plusMinutes(1));
    }

    @Test
    void noWatchInMockModeOrWhenDisabledOrWithoutAQr() {
        unpaidOrder();
        when(paymentRepository.markFailedIfPending(1L, KhqrSettlement.TIMEOUT_REASON)).thenReturn(1);
        settlement.cancelUnpaid(1L); // mock mode
        assertThat(payment.getLateWatchUntil()).isNull();

        properties.setMode(com.ecom.model.enumerate.KhqrMode.BAKONG);
        properties.setLatePaymentWatchHours(0);
        payment.setStatus(PaymentStatus.PENDING);
        order.setStatus(OrderStatus.PENDING);
        settlement.cancelUnpaid(1L);
        assertThat(payment.getLateWatchUntil()).isNull();
    }

    @Test
    void latePaymentMarksPaidAfterCancelKeepsOrderCancelledAndAlertsAdminsWithHighPriority() {
        cancelledAndWatched();
        when(paymentRepository.markPaidAfterCancel(eq(1L), any(), eq("hash-1"), eq("hash-1"), eq("buyer@bank"),
                eq(KhqrSettlement.LATE_PAYMENT_REASON))).thenReturn(1);

        assertThat(settlement.applyLate(1L, paid("105.00", "USD", "shop@bank"))).isEqualTo(Outcome.CONFIRMED);

        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.PAID_AFTER_CANCEL);
        assertThat(payment.getLateWatchUntil()).isNull();
        assertThat(order.getStatus()).isEqualTo(OrderStatus.CANCELLED);
        verify(notificationService).notifyAdmins(eq(NotificationType.EMAIL), eq(com.ecom.model.enumerate.NotificationPriority.HIGH),
                eq("Customer paid after cancel - refund or restore order"), contains(order.getOrderNumber()));
        verifyNoInteractions(orderService); // stock is NOT re-reserved automatically
    }

    @Test
    void latePaymentIsOnlyReportedByTheCallerThatWinsTheUpdate() {
        cancelledAndWatched();
        when(paymentRepository.markPaidAfterCancel(any(), any(), any(), any(), any(), any())).thenReturn(0);

        assertThat(settlement.applyLate(1L, paid("105.00", "USD", "shop@bank"))).isEqualTo(Outcome.ALREADY_DONE);
        verifyNoInteractions(notificationService);
    }

    @Test
    void mismatchingLatePaymentStopsTheWatchAndAlertsOnce() {
        cancelledAndWatched();
        when(paymentRepository.stopLateWatch(1L)).thenReturn(1);

        assertThat(settlement.applyLate(1L, paid("1.00", "USD", "shop@bank"))).isEqualTo(Outcome.REJECTED);

        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.FAILED);
        verify(notificationService).notifyAdmins(eq(NotificationType.EMAIL), eq(com.ecom.model.enumerate.NotificationPriority.HIGH),
                eq("KHQR payment needs attention"), contains("Amount mismatch"));
        verify(paymentRepository, never()).markPaidAfterCancel(any(), any(), any(), any(), any(), any());
    }

    @Test
    void wrongAccountOrCurrencyOnALatePaymentIsAlsoRejected() {
        cancelledAndWatched();
        when(paymentRepository.stopLateWatch(1L)).thenReturn(1);

        assertThat(settlement.applyLate(1L, paid("105.00", "KHR", "shop@bank"))).isEqualTo(Outcome.REJECTED);
        assertThat(settlement.applyLate(1L, paid("105.00", "USD", "other@bank"))).isEqualTo(Outcome.REJECTED);
    }

    @Test
    void latePaymentIsIgnoredWhenNotPaidOrNotBeingWatched() {
        cancelledAndWatched();
        assertThat(settlement.applyLate(1L, KhqrCheckResult.notFound())).isEqualTo(Outcome.NOT_PAID);
        verifyNoInteractions(paymentRepository, notificationService);

        payment.setLateWatchUntil(null);
        assertThat(settlement.applyLate(1L, paid("105.00", "USD", "shop@bank"))).isEqualTo(Outcome.ALREADY_DONE);
        payment.setLateWatchUntil(LocalDateTime.now().plusHours(1));
        order.setStatus(OrderStatus.CONFIRMED);
        assertThat(settlement.applyLate(1L, paid("105.00", "USD", "shop@bank"))).isEqualTo(Outcome.ALREADY_DONE);
        verifyNoInteractions(notificationService);
    }

    @Test
    void unknownPaymentOnLateCheckIsNotFound() {
        when(paymentRepository.findWithOrderById(9L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> settlement.applyLate(9L, paid("1", "USD", "shop@bank"))).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void claimLateCheckUsesTheRateLimit() {
        when(paymentRepository.claimLateCheck(eq(1L), any(LocalDateTime.class), any(LocalDateTime.class))).thenReturn(1, 0);

        assertThat(settlement.claimLateCheck(1L)).isTrue();
        assertThat(settlement.claimLateCheck(1L)).isFalse();
    }
}
