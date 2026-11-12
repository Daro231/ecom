package com.ecom.service;

import com.ecom.common.exception.BadRequestException;
import com.ecom.common.exception.InsufficientStockException;
import com.ecom.common.exception.ResourceNotFoundException;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.CheckoutRequest;
import com.ecom.model.response.OrderResponse;
import com.ecom.repository.*;
import com.ecom.service.impl.OrderServiceImpl;
import com.ecom.util.OrderNumberGenerator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {
    @Mock
    OrderRepository orderRepository;
    @Mock
    PaymentRepository paymentRepository;
    @Mock
    ShipmentRepository shipmentRepository;
    @Mock
    CartRepository cartRepository;
    @Mock
    UserRepository userRepository;
    @Mock
    AddressRepository addressRepository;
    @Mock
    CouponService couponService;
    @Mock
    InventoryService inventoryService;
    @Mock
    NotificationService notificationService;
    @Mock
    OrderNumberGenerator orderNumberGenerator;
    @InjectMocks
    OrderServiceImpl orderService;

    User user;
    Product laptop;
    Cart cart;
    Address address;

    @BeforeEach
    void setUp() {
        user = TestData.user(1);
        laptop = TestData.product(5, "500.00", 10);
        cart = Cart.builder().user(user).build();
        address = Address.builder().user(user).receiverName("Dara").phone("012345678").line1("Street 1").city("Phnom Penh").build();
        address.setId(3L);
    }

    private void stubCheckoutBasics() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(cartRepository.findByUserId(1L)).thenReturn(Optional.of(cart));
        when(addressRepository.findByIdAndUserId(3L, 1L)).thenReturn(Optional.of(address));
    }

    private void addCartItem(Product product, int quantity) {
        cart.getItems().add(CartItem.builder().cart(cart).product(product).quantity(quantity).build());
    }

    private CheckoutRequest request(String coupon) {
        return new CheckoutRequest(3L, ShippingMethod.STANDARD, PaymentMethod.KHQR, coupon, "leave at door");
    }

    @Test
    void checkoutCreatesOrderDeductsStockUsesCouponAndClearsCart() {
        stubCheckoutBasics();
        addCartItem(laptop, 2);
        Coupon coupon = TestData.coupon(DiscountType.PERCENT, "10");
        when(couponService.evaluate("WELCOME10", new BigDecimal("1000.00")))
                .thenReturn(new CouponService.CouponResult(coupon, new BigDecimal("100.00")));
        when(orderNumberGenerator.next()).thenReturn("ECOM-20261025-0001");
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
        when(paymentRepository.save(any(Payment.class))).thenAnswer(inv -> inv.getArgument(0));
        when(shipmentRepository.save(any(Shipment.class))).thenAnswer(inv -> inv.getArgument(0));

        OrderResponse response = orderService.checkout(1L, request("WELCOME10"));

        assertThat(response.orderNumber()).isEqualTo("ECOM-20261025-0001");
        assertThat(response.status()).isEqualTo(OrderStatus.PENDING);
        assertThat(response.subtotal()).isEqualByComparingTo("1000.00");
        assertThat(response.discountAmount()).isEqualByComparingTo("100.00");
        assertThat(response.shippingFee()).isEqualByComparingTo("0.00");
        assertThat(response.total()).isEqualByComparingTo("900.00");
        assertThat(response.couponCode()).isEqualTo("CODE");
        assertThat(response.items()).hasSize(1);
        assertThat(response.items().get(0).lineTotal()).isEqualByComparingTo("1000.00");
        assertThat(response.payment().status()).isEqualTo(PaymentStatus.PENDING);
        assertThat(response.shipment().status()).isEqualTo(ShipmentStatus.PREPARING);
        verify(couponService).consume(coupon);
        verify(inventoryService).applyChange(eq(laptop), eq(-2), eq(InventoryReason.ORDER), eq(1L), anyString());
        verify(notificationService).notifyUser(eq(user), eq(NotificationType.EMAIL), eq("Order placed"), contains("ECOM-20261025-0001"));
        assertThat(cart.getItems()).isEmpty();
        assertThat(laptop.getSoldCount()).isEqualTo(2);
    }

    @Test
    void checkoutChargesShippingBelowFreeShippingThreshold() {
        stubCheckoutBasics();
        addCartItem(laptop, 1);
        when(orderNumberGenerator.next()).thenReturn("ECOM-20261025-0002");
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
        when(paymentRepository.save(any(Payment.class))).thenAnswer(inv -> inv.getArgument(0));
        when(shipmentRepository.save(any(Shipment.class))).thenAnswer(inv -> inv.getArgument(0));

        OrderResponse response = orderService.checkout(1L, new CheckoutRequest(3L, ShippingMethod.EXPRESS, PaymentMethod.CASH_ON_DELIVERY, null, null));

        assertThat(response.shippingFee()).isEqualByComparingTo("15.00");
        assertThat(response.total()).isEqualByComparingTo("515.00");
        verifyNoInteractions(couponService);
    }

    @Test
    void checkoutSnapshotsAddressCoordinates() {
        stubCheckoutBasics();
        address.setLatitude(new BigDecimal("11.556374"));
        address.setLongitude(new BigDecimal("104.928207"));
        addCartItem(laptop, 1);
        when(orderNumberGenerator.next()).thenReturn("ECOM-20261025-0003");
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
        when(paymentRepository.save(any(Payment.class))).thenAnswer(inv -> inv.getArgument(0));
        when(shipmentRepository.save(any(Shipment.class))).thenAnswer(inv -> inv.getArgument(0));

        OrderResponse response = orderService.checkout(1L, request(null));

        assertThat(response.deliveryLatitude()).isEqualByComparingTo("11.556374");
        assertThat(response.deliveryLongitude()).isEqualByComparingTo("104.928207");
        address.setLatitude(new BigDecimal("1")); // later edits must not leak into the snapshot
        assertThat(response.deliveryLatitude()).isEqualByComparingTo("11.556374");
    }

    @Test
    void checkoutWithoutAddressCoordinatesLeavesSnapshotNull() {
        stubCheckoutBasics();
        addCartItem(laptop, 1);
        when(orderNumberGenerator.next()).thenReturn("ECOM-20261025-0004");
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
        when(paymentRepository.save(any(Payment.class))).thenAnswer(inv -> inv.getArgument(0));
        when(shipmentRepository.save(any(Shipment.class))).thenAnswer(inv -> inv.getArgument(0));

        OrderResponse response = orderService.checkout(1L, request(null));

        assertThat(response.deliveryLatitude()).isNull();
        assertThat(response.deliveryLongitude()).isNull();
    }

    @Test
    void checkoutWithEmptyCartFails() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(cartRepository.findByUserId(1L)).thenReturn(Optional.of(cart));

        assertThatThrownBy(() -> orderService.checkout(1L, request(null)))
                .isInstanceOf(BadRequestException.class).hasMessageContaining("empty");
    }

    @Test
    void checkoutWithoutCartFails() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(cartRepository.findByUserId(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> orderService.checkout(1L, request(null))).isInstanceOf(BadRequestException.class);
    }

    @Test
    void checkoutWithInsufficientStockFailsWithoutChangingStock() {
        stubCheckoutBasics();
        addCartItem(laptop, 11);

        assertThatThrownBy(() -> orderService.checkout(1L, request(null))).isInstanceOf(InsufficientStockException.class);
        verifyNoInteractions(inventoryService);
        verify(orderRepository, never()).save(any());
    }

    @Test
    void checkoutWithInactiveProductFails() {
        stubCheckoutBasics();
        laptop.setActive(false);
        addCartItem(laptop, 1);

        assertThatThrownBy(() -> orderService.checkout(1L, request(null))).isInstanceOf(BadRequestException.class);
    }

    @Test
    void checkoutWithForeignAddressIsNotFound() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(cartRepository.findByUserId(1L)).thenReturn(Optional.of(cart));
        addCartItem(laptop, 1);
        when(addressRepository.findByIdAndUserId(3L, 1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> orderService.checkout(1L, request(null))).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void cancelRestoresStockAndRefundsPaidPayment() {
        Order order = TestData.order(1, user, OrderStatus.CONFIRMED);
        TestData.item(order, laptop, 2);
        laptop.setSoldCount(5);
        Payment payment = TestData.payment(order, PaymentMethod.KHQR, PaymentStatus.PAID);
        when(orderRepository.findByOrderNumberAndUserId(order.getOrderNumber(), 1L)).thenReturn(Optional.of(order));
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));
        when(shipmentRepository.findByOrderId(1L)).thenReturn(Optional.empty());

        OrderResponse response = orderService.cancel(1L, order.getOrderNumber(), "changed my mind");

        assertThat(response.status()).isEqualTo(OrderStatus.CANCELLED);
        assertThat(response.cancelledReason()).isEqualTo("changed my mind");
        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.REFUNDED);
        assertThat(laptop.getSoldCount()).isEqualTo(3);
        verify(inventoryService).applyChange(eq(laptop), eq(2), eq(InventoryReason.CANCEL), eq(1L), anyString());
    }

    @Test
    void cancellingPendingOrderMarksUnpaidPaymentFailed() {
        Order order = TestData.order(1, user, OrderStatus.PENDING);
        TestData.item(order, laptop, 1);
        Payment payment = TestData.payment(order, PaymentMethod.CASH_ON_DELIVERY, PaymentStatus.PENDING);
        when(orderRepository.findByOrderNumberAndUserId(order.getOrderNumber(), 1L)).thenReturn(Optional.of(order));
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));
        when(shipmentRepository.findByOrderId(1L)).thenReturn(Optional.empty());

        orderService.cancel(1L, order.getOrderNumber(), "no longer needed");

        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.FAILED);
    }

    @Test
    void shippedOrderCannotBeCancelled() {
        Order order = TestData.order(1, user, OrderStatus.SHIPPED);
        when(orderRepository.findByOrderNumberAndUserId(order.getOrderNumber(), 1L)).thenReturn(Optional.of(order));

        assertThatThrownBy(() -> orderService.cancel(1L, order.getOrderNumber(), "late"))
                .isInstanceOf(BadRequestException.class);
        verifyNoInteractions(inventoryService);
    }

    @Test
    void cancellingSomeoneElsesOrderIsNotFound() {
        when(orderRepository.findByOrderNumberAndUserId("ECOM-X", 2L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> orderService.cancel(2L, "ECOM-X", "reason")).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void invalidStatusTransitionsAreRejected() {
        Order delivered = TestData.order(1, user, OrderStatus.DELIVERED);
        assertThatThrownBy(() -> orderService.changeStatus(delivered, OrderStatus.PENDING, null))
                .isInstanceOf(BadRequestException.class).hasMessageContaining("DELIVERED");

        Order pending = TestData.order(2, user, OrderStatus.PENDING);
        assertThatThrownBy(() -> orderService.changeStatus(pending, OrderStatus.SHIPPED, null)).isInstanceOf(BadRequestException.class);

        Order cancelled = TestData.order(3, user, OrderStatus.CANCELLED);
        assertThatThrownBy(() -> orderService.changeStatus(cancelled, OrderStatus.CONFIRMED, null)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void validForwardTransitionsAreApplied() {
        Order order = TestData.order(1, user, OrderStatus.PENDING);
        orderService.changeStatus(order, OrderStatus.CONFIRMED, null);
        orderService.changeStatus(order, OrderStatus.PROCESSING, null);
        assertThat(order.getStatus()).isEqualTo(OrderStatus.PROCESSING);
    }

    @Test
    void shipRequiresProcessingStatus() {
        Order order = TestData.order(1, user, OrderStatus.CONFIRMED);
        when(orderRepository.findByOrderNumber(order.getOrderNumber())).thenReturn(Optional.of(order));

        assertThatThrownBy(() -> orderService.ship(order.getOrderNumber(), "TRK1")).isInstanceOf(BadRequestException.class);
    }

    @Test
    void shipSetsTrackingAndNotifiesCustomer() {
        Order order = TestData.order(1, user, OrderStatus.PROCESSING);
        Shipment shipment = TestData.shipment(order, ShipmentStatus.PREPARING);
        when(orderRepository.findByOrderNumber(order.getOrderNumber())).thenReturn(Optional.of(order));
        when(shipmentRepository.findByOrderId(1L)).thenReturn(Optional.of(shipment));
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.empty());

        OrderResponse response = orderService.ship(order.getOrderNumber(), "TRK-123");

        assertThat(response.status()).isEqualTo(OrderStatus.SHIPPED);
        assertThat(shipment.getStatus()).isEqualTo(ShipmentStatus.IN_TRANSIT);
        assertThat(shipment.getTrackingNumber()).isEqualTo("TRK-123");
        assertThat(shipment.getShippedAt()).isNotNull();
        verify(notificationService).notifyUser(eq(user), eq(NotificationType.PUSH), eq("Order shipped"), contains("TRK-123"));
    }

    @Test
    void cashOnDeliveryPaymentBecomesPaidWhenOrderIsDelivered() {
        Order order = TestData.order(1, user, OrderStatus.SHIPPED);
        order.setPaymentMethod(PaymentMethod.CASH_ON_DELIVERY);
        Payment payment = TestData.payment(order, PaymentMethod.CASH_ON_DELIVERY, PaymentStatus.PENDING);
        Shipment shipment = TestData.shipment(order, ShipmentStatus.IN_TRANSIT);
        when(orderRepository.findByOrderNumber(order.getOrderNumber())).thenReturn(Optional.of(order));
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));
        when(shipmentRepository.findByOrderId(1L)).thenReturn(Optional.of(shipment));

        orderService.adminChangeStatus(order.getOrderNumber(), OrderStatus.DELIVERED, null);

        assertThat(order.getStatus()).isEqualTo(OrderStatus.DELIVERED);
        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.PAID);
        assertThat(payment.getPaidAt()).isNotNull();
        assertThat(shipment.getStatus()).isEqualTo(ShipmentStatus.DELIVERED);
        verify(notificationService).notifyUser(eq(user), eq(NotificationType.PUSH), eq("Order delivered"), contains("review"));
    }

    @Test
    void onlinePaymentStaysUntouchedOnDelivery() {
        Order order = TestData.order(1, user, OrderStatus.SHIPPED);
        Payment payment = TestData.payment(order, PaymentMethod.KHQR, PaymentStatus.PAID);
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));
        when(shipmentRepository.findByOrderId(1L)).thenReturn(Optional.empty());

        orderService.changeStatus(order, OrderStatus.DELIVERED, null);

        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.PAID);
        assertThat(payment.getPaidAt()).isNull();
    }

    @Test
    void invoiceContainsTotalsAndPayment() {
        Order order = TestData.order(1, user, OrderStatus.CONFIRMED);
        TestData.item(order, laptop, 1);
        Payment payment = TestData.payment(order, PaymentMethod.KHQR, PaymentStatus.PAID);
        when(orderRepository.findByOrderNumberAndUserId(order.getOrderNumber(), 1L)).thenReturn(Optional.of(order));
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(payment));

        var invoice = orderService.invoice(1L, order.getOrderNumber());

        assertThat(invoice.invoiceNumber()).isEqualTo("INV-" + order.getOrderNumber());
        assertThat(invoice.total()).isEqualByComparingTo("105.00");
        assertThat(invoice.items()).hasSize(1);
        assertThat(invoice.payment().status()).isEqualTo(PaymentStatus.PAID);
    }

    @Test
    void myOrdersAreReturnedWithPaymentAndShipment() {
        Order order = TestData.order(1, user, OrderStatus.PENDING);
        TestData.item(order, laptop, 1);
        when(orderRepository.findByUserId(eq(1L), any(org.springframework.data.domain.Pageable.class)))
                .thenReturn(new org.springframework.data.domain.PageImpl<>(List.of(order)));
        when(paymentRepository.findByOrderIn(List.of(order))).thenReturn(List.of(TestData.payment(order, PaymentMethod.KHQR, PaymentStatus.PENDING)));
        when(shipmentRepository.findByOrderIn(List.of(order))).thenReturn(List.of(TestData.shipment(order, ShipmentStatus.PREPARING)));

        var page = orderService.myOrders(1L, 0, 10);

        assertThat(page.content()).hasSize(1);
        assertThat(page.content().get(0).payment()).isNotNull();
        assertThat(page.content().get(0).shipment().status()).isEqualTo(ShipmentStatus.PREPARING);
    }

    @Test
    void adminSearchConvertsDatesToHalfOpenRange() {
        when(orderRepository.findAll(any(org.springframework.data.jpa.domain.Specification.class), any(org.springframework.data.domain.Pageable.class)))
                .thenReturn(new org.springframework.data.domain.PageImpl<>(List.of()));

        var page = orderService.adminSearch(OrderStatus.PENDING, LocalDate.now().minusDays(1), LocalDate.now(), "dara", 0, 10);

        assertThat(page.content()).isEmpty();
        verify(paymentRepository, never()).findByOrderIn(anyCollection());
    }

    // ---------- restore after a late payment ----------
    private Order cancelledPaidLate(Payment[] holder) {
        Order order = TestData.order(1, user, OrderStatus.CANCELLED);
        order.setCancelledReason("KHQR payment timeout");
        TestData.item(order, laptop, 2);
        laptop.setSoldCount(3);
        holder[0] = TestData.payment(order, PaymentMethod.KHQR, PaymentStatus.PAID_AFTER_CANCEL);
        when(orderRepository.findByOrderNumber(order.getOrderNumber())).thenReturn(Optional.of(order));
        when(paymentRepository.findByOrderId(1L)).thenReturn(Optional.of(holder[0]));
        return order;
    }

    @Test
    void restoreAfterPaymentReReservesStockConfirmsOrderAndMarksPaymentPaid() {
        Payment[] p = new Payment[1];
        Order order = cancelledPaidLate(p);
        when(shipmentRepository.findByOrderId(1L)).thenReturn(Optional.empty());

        OrderResponse response = orderService.restoreAfterPayment(order.getOrderNumber());

        assertThat(response.status()).isEqualTo(OrderStatus.CONFIRMED);
        assertThat(order.getCancelledReason()).isNull();
        assertThat(p[0].getStatus()).isEqualTo(PaymentStatus.PAID);
        assertThat(laptop.getSoldCount()).isEqualTo(5);
        verify(inventoryService).applyChange(eq(laptop), eq(-2), eq(InventoryReason.ORDER), eq(1L), contains("restored"));
        verify(notificationService).notifyUser(eq(user), eq(NotificationType.EMAIL), eq("Order restored"), contains(order.getOrderNumber()));
    }

    @Test
    void restoreAfterPaymentFailsWithoutChangesWhenStockRanOut() {
        Payment[] p = new Payment[1];
        Order order = cancelledPaidLate(p);
        doThrow(new InsufficientStockException("Insufficient stock")).when(inventoryService)
                .applyChange(eq(laptop), eq(-2), eq(InventoryReason.ORDER), anyLong(), anyString());

        assertThatThrownBy(() -> orderService.restoreAfterPayment(order.getOrderNumber())).isInstanceOf(InsufficientStockException.class);

        assertThat(order.getStatus()).isEqualTo(OrderStatus.CANCELLED);
        assertThat(p[0].getStatus()).isEqualTo(PaymentStatus.PAID_AFTER_CANCEL);
        assertThat(laptop.getSoldCount()).isEqualTo(3);
        verifyNoInteractions(notificationService);
    }

    @Test
    void restoreAfterPaymentOnlyWorksForCancelledOrdersWithALatePayment() {
        Payment[] p = new Payment[1];
        Order order = cancelledPaidLate(p);
        p[0].setStatus(PaymentStatus.FAILED);
        assertThatThrownBy(() -> orderService.restoreAfterPayment(order.getOrderNumber())).isInstanceOf(BadRequestException.class);

        p[0].setStatus(PaymentStatus.PAID_AFTER_CANCEL);
        order.setStatus(OrderStatus.CONFIRMED);
        assertThatThrownBy(() -> orderService.restoreAfterPayment(order.getOrderNumber())).isInstanceOf(BadRequestException.class);
        verifyNoInteractions(inventoryService);
    }

    @Test
    void restoreAfterPaymentForUnknownOrderIsNotFound() {
        when(orderRepository.findByOrderNumber("ECOM-NOPE")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> orderService.restoreAfterPayment("ECOM-NOPE")).isInstanceOf(ResourceNotFoundException.class);
    }
}
