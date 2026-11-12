package com.ecom.service;

import com.ecom.common.exception.BadRequestException;
import com.ecom.common.exception.PaymentGatewayException;
import com.ecom.common.exception.ResourceNotFoundException;
import com.ecom.config.KhqrProperties;
import com.ecom.model.entity.Order;
import com.ecom.model.entity.Payment;
import com.ecom.model.entity.User;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.PaymentCallbackRequest;
import com.ecom.model.response.KhqrResponse;
import com.ecom.model.response.PaymentResponse;
import com.ecom.repository.OrderRepository;
import com.ecom.repository.PaymentRepository;
import com.ecom.service.impl.KhqrSettlement;
import com.ecom.service.impl.PaymentServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PaymentServiceTest {
    @Mock
    PaymentRepository paymentRepository;
    @Mock
    OrderRepository orderRepository;
    @Mock
    OrderService orderService;
    @Mock
    KhqrGateway khqrGateway;
    @Mock
    NotificationService notificationService;
    @Mock
    KhqrSettlement settlement;
    @Spy
    KhqrProperties properties = new KhqrProperties();
    @InjectMocks
    PaymentServiceImpl paymentService;

    User user;
    Order order;
    Payment payment;

    @BeforeEach
    void setUp() {
        user = TestData.user(1);
        order = TestData.order(1, user, OrderStatus.PENDING);
        payment = TestData.payment(order, PaymentMethod.KHQR, PaymentStatus.PENDING);
    }

    private void bakongMode() {
        properties.setMode(KhqrMode.BAKONG);
    }

    private void pendingQr(int minutesUntilExpiry) {
        payment.setKhqrString("qr");
        payment.setKhqrMd5("md5-1");
        payment.setKhqrExpiresAt(LocalDateTime.now().plusMinutes(minutesUntilExpiry));
    }

    // ---------- mock callback ----------
    @Test
    void khqrCallbackPaidConfirmsOrderAndNotifiesCustomer() {
        when(orderService.findOrder(order.getOrderNumber())).thenReturn(order);
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));

        PaymentResponse response = paymentService.callback(new PaymentCallbackRequest("TX-1", order.getOrderNumber(), PaymentStatus.PAID));

        assertThat(response.status()).isEqualTo(PaymentStatus.PAID);
        assertThat(payment.getTransactionRef()).isEqualTo("TX-1");
        assertThat(payment.getPaidAt()).isNotNull();
        verify(orderService).changeStatus(order, OrderStatus.CONFIRMED, null);
        verify(notificationService).notifyUser(eq(user), eq(NotificationType.EMAIL), anyString(), contains("$105.00"));
    }

    @Test
    void callbackIsNotFoundInBakongMode() {
        bakongMode();

        assertThatThrownBy(() -> paymentService.callback(new PaymentCallbackRequest("TX", order.getOrderNumber(), PaymentStatus.PAID)))
                .isInstanceOf(ResourceNotFoundException.class);
        verifyNoInteractions(orderService, notificationService);
    }

    @Test
    void callbackIsIdempotentForAlreadyPaidPayments() {
        payment.setStatus(PaymentStatus.PAID);
        when(orderService.findOrder(order.getOrderNumber())).thenReturn(order);
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));

        paymentService.callback(new PaymentCallbackRequest("TX-2", order.getOrderNumber(), PaymentStatus.PAID));

        verify(orderService, never()).changeStatus(any(), any(), any());
        verifyNoInteractions(notificationService);
    }

    @Test
    void callbackPaidDoesNotRepeatConfirmationForConfirmedOrders() {
        order.setStatus(OrderStatus.CONFIRMED);
        when(orderService.findOrder(order.getOrderNumber())).thenReturn(order);
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));

        paymentService.callback(new PaymentCallbackRequest("TX-3", order.getOrderNumber(), PaymentStatus.PAID));

        verify(orderService, never()).changeStatus(any(), any(), any());
    }

    @Test
    void callbackFailedMarksPaymentFailedAndKeepsOrderPending() {
        when(orderService.findOrder(order.getOrderNumber())).thenReturn(order);
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));

        paymentService.callback(new PaymentCallbackRequest("TX-4", order.getOrderNumber(), PaymentStatus.FAILED));

        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.FAILED);
        verify(orderService, never()).changeStatus(any(), any(), any());
    }

    @Test
    void callbackWithUnsupportedStatusIsRejected() {
        when(orderService.findOrder(order.getOrderNumber())).thenReturn(order);
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));

        assertThatThrownBy(() -> paymentService.callback(new PaymentCallbackRequest("TX", order.getOrderNumber(), PaymentStatus.REFUNDED)))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void callbackForCancelledOrderIsRejected() {
        order.setStatus(OrderStatus.CANCELLED);
        when(orderService.findOrder(order.getOrderNumber())).thenReturn(order);
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));

        assertThatThrownBy(() -> paymentService.callback(new PaymentCallbackRequest("TX", order.getOrderNumber(), PaymentStatus.PAID)))
                .isInstanceOf(BadRequestException.class);
    }

    // ---------- QR generation ----------
    private void ownedOrder() {
        when(orderRepository.findByOrderNumberAndUserId(order.getOrderNumber(), 1L)).thenReturn(Optional.of(order));
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));
    }

    @Test
    void khqrIsGeneratedAndStoredForPendingKhqrPayment() {
        ownedOrder();
        when(khqrGateway.generate(eq(order.getOrderNumber()), eq(payment.getAmount()), any(LocalDateTime.class)))
                .thenAnswer(inv -> new KhqrGateway.KhqrPayload("payload", "0123456789abcdef0123456789abcdef", inv.getArgument(2)));
        when(khqrGateway.gatewayAmount(payment.getAmount())).thenReturn(payment.getAmount());
        when(khqrGateway.currency()).thenReturn("USD");

        KhqrResponse response = paymentService.generateKhqr(1L, order.getOrderNumber());

        assertThat(response.qrString()).isEqualTo("payload");
        assertThat(response.qrPayload()).isEqualTo("payload");
        assertThat(response.md5()).hasSize(32);
        assertThat(response.mode()).isEqualTo(KhqrMode.MOCK);
        assertThat(response.currency()).isEqualTo("USD");
        assertThat(response.expiresAt()).isAfter(LocalDateTime.now().plusMinutes(9));
        assertThat(payment.getKhqrMd5()).isEqualTo(response.md5());
        assertThat(payment.getTransactionRef()).startsWith("KHQR-");
    }

    @Test
    void unexpiredQrIsReturnedAgainWithoutCallingTheGateway() {
        ownedOrder();
        pendingQr(5);
        when(khqrGateway.gatewayAmount(payment.getAmount())).thenReturn(payment.getAmount());
        when(khqrGateway.currency()).thenReturn("USD");

        KhqrResponse response = paymentService.generateKhqr(1L, order.getOrderNumber());

        assertThat(response.md5()).isEqualTo("md5-1");
        verify(khqrGateway, never()).generate(any(), any(), any());
    }

    @Test
    void expiredQrIsReplacedByANewOne() {
        ownedOrder();
        pendingQr(-1);
        when(khqrGateway.generate(eq(order.getOrderNumber()), any(), any(LocalDateTime.class)))
                .thenAnswer(inv -> new KhqrGateway.KhqrPayload("new-qr", "ffffffffffffffffffffffffffffffff", inv.getArgument(2)));
        when(khqrGateway.gatewayAmount(payment.getAmount())).thenReturn(payment.getAmount());
        when(khqrGateway.currency()).thenReturn("USD");

        KhqrResponse response = paymentService.generateKhqr(1L, order.getOrderNumber());

        assertThat(response.qrString()).isEqualTo("new-qr");
        assertThat(payment.getKhqrMd5()).isEqualTo("ffffffffffffffffffffffffffffffff");
    }

    @Test
    void paymentFailedBecauseOfExpiryCanGetANewQr() {
        ownedOrder();
        pendingQr(-30);
        payment.setStatus(PaymentStatus.FAILED);
        payment.setFailureReason(KhqrSettlement.EXPIRED_REASON);
        when(khqrGateway.generate(any(), any(), any(LocalDateTime.class)))
                .thenAnswer(inv -> new KhqrGateway.KhqrPayload("again", "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", inv.getArgument(2)));
        when(khqrGateway.gatewayAmount(any())).thenReturn(payment.getAmount());
        when(khqrGateway.currency()).thenReturn("USD");

        paymentService.generateKhqr(1L, order.getOrderNumber());

        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.PENDING);
        assertThat(payment.getFailureReason()).isNull();
    }

    @Test
    void khqrIsRejectedForOtherPaymentMethodsPaidPaymentsAndCancelledOrders() {
        ownedOrder();
        payment.setMethod(PaymentMethod.CASH_ON_DELIVERY);
        assertThatThrownBy(() -> paymentService.generateKhqr(1L, order.getOrderNumber())).isInstanceOf(BadRequestException.class);

        payment.setMethod(PaymentMethod.KHQR);
        payment.setStatus(PaymentStatus.PAID);
        assertThatThrownBy(() -> paymentService.generateKhqr(1L, order.getOrderNumber())).isInstanceOf(BadRequestException.class);

        payment.setStatus(PaymentStatus.PENDING);
        order.setStatus(OrderStatus.CANCELLED);
        assertThatThrownBy(() -> paymentService.generateKhqr(1L, order.getOrderNumber())).isInstanceOf(BadRequestException.class);
    }

    // ---------- status polling ----------
    private void statusLookup() {
        when(paymentRepository.findByOrder_OrderNumberAndOrder_User_Id(order.getOrderNumber(), 1L)).thenReturn(Optional.of(payment));
    }

    @Test
    void statusOfForeignOrderIsNotFound() {
        when(paymentRepository.findByOrder_OrderNumberAndOrder_User_Id("ECOM-X", 9L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> paymentService.status(9L, "ECOM-X")).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void mockModeStatusNeverCallsTheProvider() {
        statusLookup();
        pendingQr(5);

        assertThat(paymentService.status(1L, order.getOrderNumber()).status()).isEqualTo(PaymentStatus.PENDING);
        verifyNoInteractions(settlement, khqrGateway);
    }

    @Test
    void bakongStatusChecksTheProviderAndReturnsTheUpdatedPayment() {
        bakongMode();
        statusLookup();
        pendingQr(5);
        KhqrCheckResult paid = new KhqrCheckResult(KhqrCheckResult.Status.PAID, "h", "a@b", "me@b", new BigDecimal("105.00"), "USD", null);
        when(settlement.claimCheck(1L)).thenReturn(true);
        when(khqrGateway.checkStatus("md5-1")).thenReturn(paid);
        Payment after = TestData.payment(order, PaymentMethod.KHQR, PaymentStatus.PAID);
        when(paymentRepository.findWithOrderById(1L)).thenReturn(Optional.of(after));

        assertThat(paymentService.status(1L, order.getOrderNumber()).status()).isEqualTo(PaymentStatus.PAID);
        verify(settlement).apply(1L, paid);
    }

    @Test
    void bakongStatusIsRateLimitedWhenCheckedRecently() {
        bakongMode();
        statusLookup();
        pendingQr(5);
        when(settlement.claimCheck(1L)).thenReturn(false);

        assertThat(paymentService.status(1L, order.getOrderNumber()).status()).isEqualTo(PaymentStatus.PENDING);
        verify(khqrGateway, never()).checkStatus(any());
    }

    @Test
    void bakongStatusSkipsPaymentsWhoseQrIsLongExpired() {
        bakongMode();
        statusLookup();
        pendingQr(-60);

        paymentService.status(1L, order.getOrderNumber());

        verifyNoInteractions(settlement);
    }

    @Test
    void providerFailureSurfacesAsGatewayException() {
        bakongMode();
        statusLookup();
        pendingQr(5);
        when(settlement.claimCheck(1L)).thenReturn(true);
        when(khqrGateway.checkStatus("md5-1")).thenThrow(new PaymentGatewayException("token", HttpStatus.BAD_GATEWAY));

        assertThatThrownBy(() -> paymentService.status(1L, order.getOrderNumber()))
                .isInstanceOf(PaymentGatewayException.class).extracting(e -> ((PaymentGatewayException) e).getStatus()).isEqualTo(HttpStatus.BAD_GATEWAY);
    }

    // ---------- admin recheck / reconcile ----------
    @Test
    void recheckIsOnlyAvailableInBakongMode() {
        assertThatThrownBy(() -> paymentService.recheck(order.getOrderNumber())).isInstanceOf(BadRequestException.class);
    }

    @Test
    void recheckAsksTheProviderIgnoringTheRateLimit() {
        bakongMode();
        pendingQr(5);
        when(paymentRepository.findByOrder_OrderNumber(order.getOrderNumber())).thenReturn(Optional.of(payment));
        when(khqrGateway.checkStatus("md5-1")).thenReturn(KhqrCheckResult.notFound());
        when(paymentRepository.findWithOrderById(1L)).thenReturn(Optional.of(payment));

        assertThat(paymentService.recheck(order.getOrderNumber()).status()).isEqualTo(PaymentStatus.PENDING);
        verify(settlement).apply(1L, KhqrCheckResult.notFound());
        verify(settlement, never()).claimCheck(any());
    }

    @Test
    void recheckOfUnknownOrderIsNotFound() {
        bakongMode();
        when(paymentRepository.findByOrder_OrderNumber("NOPE")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> paymentService.recheck("NOPE")).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void reconcileChecksEachPendingPaymentOnceAndCountsConfirmations() {
        bakongMode();
        pendingQr(5);
        Payment second = TestData.payment(TestData.order(2, user, OrderStatus.PENDING), PaymentMethod.KHQR, PaymentStatus.PENDING);
        second.setKhqrMd5("md5-2");
        Payment skipped = TestData.payment(TestData.order(3, user, OrderStatus.PENDING), PaymentMethod.KHQR, PaymentStatus.PENDING);
        skipped.setKhqrMd5("md5-3");
        when(paymentRepository.findPendingKhqr(any(LocalDateTime.class))).thenReturn(List.of(payment, second, skipped));
        when(settlement.claimCheck(1L)).thenReturn(true);
        when(settlement.claimCheck(2L)).thenReturn(true);
        when(settlement.claimCheck(3L)).thenReturn(false);
        KhqrCheckResult paid = new KhqrCheckResult(KhqrCheckResult.Status.PAID, "h", null, null, null, null, null);
        when(khqrGateway.checkStatus("md5-1")).thenReturn(paid);
        when(khqrGateway.checkStatus("md5-2")).thenReturn(KhqrCheckResult.notFound());
        when(settlement.apply(1L, paid)).thenReturn(KhqrSettlement.Outcome.CONFIRMED);
        when(settlement.apply(2L, KhqrCheckResult.notFound())).thenReturn(KhqrSettlement.Outcome.NOT_PAID);

        assertThat(paymentService.reconcilePending()).isEqualTo(1);
        verify(settlement).expireStale();
        verify(khqrGateway, never()).checkStatus("md5-3");
    }

    @Test
    void reconcileSkipsAFailingPaymentButStopsAfterThreeFailuresInARow() {
        bakongMode();
        pendingQr(5);
        Payment second = TestData.payment(TestData.order(2, user, OrderStatus.PENDING), PaymentMethod.KHQR, PaymentStatus.PENDING);
        second.setKhqrMd5("md5-2");
        Payment third = TestData.payment(TestData.order(3, user, OrderStatus.PENDING), PaymentMethod.KHQR, PaymentStatus.PENDING);
        third.setKhqrMd5("md5-3");
        Payment fourth = TestData.payment(TestData.order(4, user, OrderStatus.PENDING), PaymentMethod.KHQR, PaymentStatus.PENDING);
        fourth.setKhqrMd5("md5-4");
        when(paymentRepository.findPendingKhqr(any(LocalDateTime.class))).thenReturn(List.of(payment, second, third, fourth));
        when(settlement.claimCheck(anyLong())).thenReturn(true);
        when(khqrGateway.checkStatus(anyString())).thenThrow(new PaymentGatewayException("down", HttpStatus.GATEWAY_TIMEOUT));

        assertThat(paymentService.reconcilePending()).isZero();
        verify(khqrGateway, times(3)).checkStatus(anyString());
        verify(khqrGateway, never()).checkStatus("md5-4");
    }

    @Test
    void reconcileKeepsGoingAfterASingleFailure() {
        bakongMode();
        pendingQr(5);
        Payment second = TestData.payment(TestData.order(2, user, OrderStatus.PENDING), PaymentMethod.KHQR, PaymentStatus.PENDING);
        second.setKhqrMd5("md5-2");
        KhqrCheckResult paid = new KhqrCheckResult(KhqrCheckResult.Status.PAID, "h", null, null, null, null, null);
        when(paymentRepository.findPendingKhqr(any(LocalDateTime.class))).thenReturn(List.of(payment, second));
        when(settlement.claimCheck(anyLong())).thenReturn(true);
        when(khqrGateway.checkStatus("md5-1")).thenThrow(new PaymentGatewayException("bad", HttpStatus.BAD_GATEWAY));
        when(khqrGateway.checkStatus("md5-2")).thenReturn(paid);
        when(settlement.apply(2L, paid)).thenReturn(KhqrSettlement.Outcome.CONFIRMED);

        assertThat(paymentService.reconcilePending()).isEqualTo(1);
    }

    // ---------- auto-cancel ----------
    @Test
    void autoCancelCountsCancelledOrdersAndSurvivesFailures() {
        when(orderRepository.findUnpaidKhqrOrderIds(any(LocalDateTime.class))).thenReturn(List.of(1L, 2L, 3L));
        when(settlement.cancelUnpaid(1L)).thenReturn(true);
        when(settlement.cancelUnpaid(2L)).thenThrow(new IllegalStateException("boom"));
        when(settlement.cancelUnpaid(3L)).thenReturn(false);

        assertThat(paymentService.cancelUnpaidKhqrOrders()).isEqualTo(1);
    }

    @Test
    void autoCancelUsesTheConfiguredTimeout() {
        properties.setAutoCancelMinutes(45);
        when(orderRepository.findUnpaidKhqrOrderIds(any(LocalDateTime.class))).thenReturn(List.of());
        LocalDateTime before = LocalDateTime.now();

        paymentService.cancelUnpaidKhqrOrders();

        org.mockito.ArgumentCaptor<LocalDateTime> cutoff = org.mockito.ArgumentCaptor.forClass(LocalDateTime.class);
        verify(orderRepository).findUnpaidKhqrOrderIds(cutoff.capture());
        assertThat(cutoff.getValue()).isBetween(before.minusMinutes(45).minusSeconds(1), LocalDateTime.now().minusMinutes(45).plusSeconds(1));
    }

    @Test
    void autoCancelCanBeDisabled() {
        properties.setAutoCancelMinutes(0);

        assertThat(paymentService.cancelUnpaidKhqrOrders()).isZero();
        verifyNoInteractions(orderRepository, settlement);
    }

    // ---------- plain admin ----------
    @Test
    void refundOnlyWorksForPaidPayments() {
        when(paymentRepository.findById(1L)).thenReturn(Optional.of(payment));
        assertThatThrownBy(() -> paymentService.refund(1L)).isInstanceOf(BadRequestException.class);

        payment.setStatus(PaymentStatus.PAID);
        assertThat(paymentService.refund(1L).status()).isEqualTo(PaymentStatus.REFUNDED);
        verify(notificationService).notifyUser(eq(user), eq(NotificationType.EMAIL), anyString(), anyString());
    }

    @Test
    void adminListFiltersByStatus() {
        when(paymentRepository.findByStatus(eq(PaymentStatus.PAID), any(Pageable.class))).thenReturn(new PageImpl<>(List.of(payment)));
        when(paymentRepository.findAll(any(Pageable.class))).thenReturn(new PageImpl<>(List.of(payment, payment)));

        assertThat(paymentService.adminList(PaymentStatus.PAID, 0, 10).content()).hasSize(1);
        assertThat(paymentService.adminList(null, 0, 10).content()).hasSize(2);
    }

    // ---------- late payments after auto-cancel ----------
    @Test
    void lateCheckDoesNothingInMockModeOrWhenDisabled() {
        assertThat(paymentService.checkLatePayments()).isZero();
        bakongMode();
        properties.setLatePaymentWatchHours(0);
        assertThat(paymentService.checkLatePayments()).isZero();
        verifyNoInteractions(paymentRepository, khqrGateway, settlement);
    }

    @Test
    void lateCheckAsksBakongAboutEveryWatchedPaymentAndCountsPaidOnes() {
        bakongMode();
        order.setStatus(OrderStatus.CANCELLED);
        payment.setKhqrMd5("md5-1");
        Order order2 = TestData.order(2, user, OrderStatus.CANCELLED);
        Payment second = TestData.payment(order2, PaymentMethod.KHQR, PaymentStatus.FAILED);
        second.setKhqrMd5("md5-2");
        when(paymentRepository.findLateWatch(any(LocalDateTime.class))).thenReturn(List.of(payment, second));
        when(settlement.claimLateCheck(anyLong())).thenReturn(true);
        KhqrCheckResult paid = new KhqrCheckResult(KhqrCheckResult.Status.PAID, "h", "b", "s", java.math.BigDecimal.ONE, "USD", null);
        when(khqrGateway.checkStatus("md5-1")).thenReturn(paid);
        when(khqrGateway.checkStatus("md5-2")).thenReturn(KhqrCheckResult.notFound());
        when(settlement.applyLate(1L, paid)).thenReturn(KhqrSettlement.Outcome.CONFIRMED);
        when(settlement.applyLate(2L, KhqrCheckResult.notFound())).thenReturn(KhqrSettlement.Outcome.NOT_PAID);

        assertThat(paymentService.checkLatePayments()).isEqualTo(1);
    }

    @Test
    void lateCheckSkipsRateLimitedPaymentsAndGivesUpAfterRepeatedGatewayFailures() {
        bakongMode();
        payment.setKhqrMd5("md5-1");
        when(paymentRepository.findLateWatch(any(LocalDateTime.class))).thenReturn(List.of(payment, payment, payment, payment));
        when(settlement.claimLateCheck(1L)).thenReturn(false, true, true, true);
        when(khqrGateway.checkStatus(any())).thenThrow(new PaymentGatewayException("down", org.springframework.http.HttpStatus.BAD_GATEWAY));

        assertThat(paymentService.checkLatePayments()).isZero();

        verify(khqrGateway, times(3)).checkStatus("md5-1");
    }

    @Test
    void paidAfterCancelPaymentsCanBeRefundedByIdOrOrderNumber() {
        payment.setStatus(PaymentStatus.PAID_AFTER_CANCEL);
        when(paymentRepository.findById(1L)).thenReturn(Optional.of(payment));
        when(paymentRepository.findByOrder_OrderNumber(order.getOrderNumber())).thenReturn(Optional.of(payment));

        assertThat(paymentService.refund(order.getOrderNumber()).status()).isEqualTo(PaymentStatus.REFUNDED);

        payment.setStatus(PaymentStatus.PAID_AFTER_CANCEL);
        assertThat(paymentService.refund("1").status()).isEqualTo(PaymentStatus.REFUNDED);
        verify(notificationService, times(2)).notifyUser(eq(user), eq(NotificationType.EMAIL), anyString(), anyString());
    }

    @Test
    void refundByUnknownOrderNumberIsNotFound() {
        when(paymentRepository.findByOrder_OrderNumber("ECOM-NOPE")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> paymentService.refund("ECOM-NOPE")).isInstanceOf(ResourceNotFoundException.class);
    }
}
