package com.ecom.service.impl;

import com.ecom.common.constant.AppConstants;
import com.ecom.common.exception.*;
import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;
import com.ecom.repository.*;
import com.ecom.service.*;
import com.ecom.util.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderServiceImpl implements OrderService {
    private static final Map<OrderStatus, Set<OrderStatus>> ALLOWED = Map.of(
            OrderStatus.PENDING, EnumSet.of(OrderStatus.CONFIRMED, OrderStatus.CANCELLED),
            OrderStatus.CONFIRMED, EnumSet.of(OrderStatus.PROCESSING, OrderStatus.CANCELLED),
            OrderStatus.PROCESSING, EnumSet.of(OrderStatus.SHIPPED, OrderStatus.CANCELLED),
            OrderStatus.SHIPPED, EnumSet.of(OrderStatus.DELIVERED),
            OrderStatus.DELIVERED, EnumSet.noneOf(OrderStatus.class),
            OrderStatus.CANCELLED, EnumSet.noneOf(OrderStatus.class));

    private final OrderRepository orderRepository;
    private final PaymentRepository paymentRepository;
    private final ShipmentRepository shipmentRepository;
    private final CartRepository cartRepository;
    private final UserRepository userRepository;
    private final AddressRepository addressRepository;
    private final CouponService couponService;
    private final InventoryService inventoryService;
    private final NotificationService notificationService;
    private final OrderNumberGenerator orderNumberGenerator;

    @Override
    @Transactional
    public OrderResponse checkout(Long userId, CheckoutRequest r) {
        User user = userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Cart cart = cartRepository.findByUserId(userId).filter(c -> !c.getItems().isEmpty())
                .orElseThrow(() -> new BadRequestException("Cart is empty"));
        Address address = addressRepository.findByIdAndUserId(r.addressId(), userId)
                .orElseThrow(() -> new ResourceNotFoundException("Address not found"));

        BigDecimal subtotal = BigDecimal.ZERO;
        for (CartItem item : cart.getItems()) {
            Product product = item.getProduct();
            if (!product.isActive()) {
                throw new BadRequestException(product.getName() + " is no longer available");
            }
            if (item.getQuantity() > product.getStockQuantity()) {
                throw new InsufficientStockException("Insufficient stock for " + product.getName() + ": requested "
                        + item.getQuantity() + ", available " + product.getStockQuantity());
            }
            subtotal = subtotal.add(product.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())));
        }
        subtotal = MoneyUtil.scale(subtotal);

        BigDecimal discount = MoneyUtil.scale(BigDecimal.ZERO);
        String couponCode = null;
        if (r.couponCode() != null && !r.couponCode().isBlank()) {
            CouponService.CouponResult result = couponService.evaluate(r.couponCode(), subtotal);
            couponService.consume(result.coupon());
            discount = result.discount();
            couponCode = result.coupon().getCode();
        }
        BigDecimal shippingFee = MoneyUtil.shippingFee(subtotal, r.shippingMethod());
        BigDecimal total = MoneyUtil.scale(subtotal.subtract(discount).add(shippingFee));

        Order order = Order.builder()
                .orderNumber(orderNumberGenerator.next())
                .user(user)
                .status(OrderStatus.PENDING)
                .subtotal(subtotal).discountAmount(discount).shippingFee(shippingFee).total(total)
                .couponCode(couponCode)
                .receiverName(address.getReceiverName()).receiverPhone(address.getPhone())
                .shippingAddress(address.getLine1() + ", " + address.getCity())
                .deliveryLatitude(address.getLatitude()).deliveryLongitude(address.getLongitude())
                .shippingMethod(r.shippingMethod()).paymentMethod(r.paymentMethod())
                .note(r.note())
                .build();
        for (CartItem item : cart.getItems()) {
            Product product = item.getProduct();
            order.getItems().add(OrderItem.builder().order(order).product(product).productName(product.getName())
                    .unitPrice(product.getPrice()).quantity(item.getQuantity())
                    .lineTotal(MoneyUtil.scale(product.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())))).build());
        }
        order = orderRepository.save(order);

        for (CartItem item : cart.getItems()) {
            Product product = item.getProduct();
            inventoryService.applyChange(product, -item.getQuantity(), InventoryReason.ORDER, userId, "Order " + order.getOrderNumber());
            product.setSoldCount(product.getSoldCount() + item.getQuantity());
        }

        Payment payment = paymentRepository.save(Payment.builder().order(order).method(r.paymentMethod())
                .status(PaymentStatus.PENDING).amount(total).build());
        Shipment shipment = shipmentRepository.save(Shipment.builder().order(order).method(r.shippingMethod())
                .fee(shippingFee).status(ShipmentStatus.PREPARING).build());
        cart.getItems().clear();

        notificationService.notifyUser(user, NotificationType.EMAIL, "Order placed",
                "Your order " + order.getOrderNumber() + " has been placed. Total: $" + total);
        return OrderResponse.from(order, payment, shipment);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<OrderResponse> myOrders(Long userId, int page, int size) {
        return toPage(orderRepository.findByUserId(userId, PageUtil.newestFirst(page, size)));
    }

    @Override
    @Transactional(readOnly = true)
    public OrderResponse getMyOrder(Long userId, String orderNumber) {
        return toResponse(findOwned(userId, orderNumber));
    }

    @Override
    @Transactional
    public OrderResponse cancel(Long userId, String orderNumber, String reason) {
        Order order = findOwned(userId, orderNumber);
        changeStatus(order, OrderStatus.CANCELLED, reason);
        return toResponse(order);
    }

    @Override
    @Transactional(readOnly = true)
    public InvoiceResponse invoice(Long userId, String orderNumber) {
        Order o = findOwned(userId, orderNumber);
        Payment payment = paymentRepository.findByOrderId(o.getId()).orElse(null);
        return new InvoiceResponse("INV-" + o.getOrderNumber(), LocalDateTime.now(), o.getOrderNumber(), o.getStatus(),
                o.getUser().getFullName(), o.getUser().getEmail(), o.getReceiverName(), o.getReceiverPhone(),
                o.getShippingAddress(), o.getItems().stream().map(OrderItemResponse::from).toList(), o.getSubtotal(),
                o.getDiscountAmount(), o.getCouponCode(), o.getShippingFee(), o.getTotal(),
                payment == null ? null : PaymentResponse.from(payment));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<OrderResponse> adminSearch(OrderStatus status, LocalDate from, LocalDate to, String keyword, int page, int size) {
        var spec = OrderSpecifications.filter(status, from == null ? null : from.atStartOfDay(),
                to == null ? null : to.plusDays(1).atStartOfDay(), keyword);
        return toPage(orderRepository.findAll(spec, PageUtil.newestFirst(page, size)));
    }

    @Override
    @Transactional(readOnly = true)
    public OrderResponse adminGet(String orderNumber) {
        return toResponse(findOrder(orderNumber));
    }

    @Override
    @Transactional
    public OrderResponse adminChangeStatus(String orderNumber, OrderStatus status, String reason) {
        Order order = findOrder(orderNumber);
        changeStatus(order, status, reason);
        return toResponse(order);
    }

    @Override
    @Transactional
    public OrderResponse restoreAfterPayment(String orderNumber) {
        Order order = findOrder(orderNumber);
        Payment payment = paymentRepository.findByOrderId(order.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Payment not found"));
        if (order.getStatus() != OrderStatus.CANCELLED || payment.getStatus() != PaymentStatus.PAID_AFTER_CANCEL) {
            throw new BadRequestException("Only a CANCELLED order whose payment is PAID_AFTER_CANCEL can be restored");
        }
        // all-or-nothing: an InsufficientStockException (409) rolls back every reservation made so far
        for (OrderItem item : order.getItems()) {
            Product product = item.getProduct();
            inventoryService.applyChange(product, -item.getQuantity(), InventoryReason.ORDER, order.getUser().getId(),
                    "Order " + order.getOrderNumber() + " restored after late payment");
            product.setSoldCount(product.getSoldCount() + item.getQuantity());
        }
        order.setStatus(OrderStatus.CONFIRMED);
        order.setCancelledReason(null);
        payment.setStatus(PaymentStatus.PAID);
        payment.setFailureReason(null);
        notificationService.notifyUser(order.getUser(), NotificationType.EMAIL, "Order restored",
                "Your payment for order " + order.getOrderNumber() + " was received and the order is confirmed again.");
        return toResponse(order);
    }

    @Override
    @Transactional
    public OrderResponse ship(String orderNumber, String trackingNumber) {
        Order order = findOrder(orderNumber);
        if (order.getStatus() != OrderStatus.PROCESSING) {
            throw new BadRequestException("Only orders in PROCESSING status can be shipped");
        }
        markShipped(order, trackingNumber);
        return toResponse(order);
    }

    @Override
    @Transactional(readOnly = true)
    public Order findOrder(String orderNumber) {
        return orderRepository.findByOrderNumber(orderNumber).orElseThrow(() -> new ResourceNotFoundException("Order not found"));
    }

    private Order findOwned(Long userId, String orderNumber) {
        return orderRepository.findByOrderNumberAndUserId(orderNumber, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found"));
    }

    @Override
    @Transactional
    public void changeStatus(Order order, OrderStatus target, String reason) {
        if (!ALLOWED.get(order.getStatus()).contains(target)) {
            throw new BadRequestException("Cannot change order status from " + order.getStatus() + " to " + target);
        }
        switch (target) {
            case CANCELLED -> cancelOrder(order, reason);
            case SHIPPED -> markShipped(order, null);
            case DELIVERED -> markDelivered(order);
            default -> order.setStatus(target);
        }
    }

    private void cancelOrder(Order order, String reason) {
        for (OrderItem item : order.getItems()) {
            Product product = item.getProduct();
            inventoryService.applyChange(product, item.getQuantity(), InventoryReason.CANCEL, order.getUser().getId(),
                    "Order " + order.getOrderNumber() + " cancelled");
            product.setSoldCount(Math.max(0, product.getSoldCount() - item.getQuantity()));
        }
        paymentRepository.findByOrderId(order.getId()).ifPresent(p -> {
            if (p.getStatus() == PaymentStatus.PAID) {
                p.setStatus(PaymentStatus.REFUNDED);
            } else if (p.getStatus() == PaymentStatus.PENDING) {
                p.setStatus(PaymentStatus.FAILED);
            }
        });
        order.setStatus(OrderStatus.CANCELLED);
        order.setCancelledReason(reason);
        notificationService.notifyUser(order.getUser(), NotificationType.EMAIL, "Order cancelled",
                "Your order " + order.getOrderNumber() + " was cancelled." + (reason == null || reason.isBlank() ? "" : " Reason: " + reason));
    }

    private void markShipped(Order order, String trackingNumber) {
        Shipment shipment = shipmentRepository.findByOrderId(order.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Shipment not found"));
        String tracking = trackingNumber == null || trackingNumber.isBlank()
                ? "TRK" + order.getOrderNumber().replace("ECOM-", "").replace("-", "") : trackingNumber.trim();
        shipment.setTrackingNumber(tracking);
        shipment.setStatus(ShipmentStatus.IN_TRANSIT);
        shipment.setShippedAt(LocalDateTime.now());
        order.setStatus(OrderStatus.SHIPPED);
        notificationService.notifyUser(order.getUser(), NotificationType.PUSH, "Order shipped",
                "Your order " + order.getOrderNumber() + " is on its way. Tracking number: " + tracking);
    }

    private void markDelivered(Order order) {
        shipmentRepository.findByOrderId(order.getId()).ifPresent(s -> {
            s.setStatus(ShipmentStatus.DELIVERED);
            s.setDeliveredAt(LocalDateTime.now());
        });
        paymentRepository.findByOrderId(order.getId()).ifPresent(p -> {
            if (p.getMethod() == PaymentMethod.CASH_ON_DELIVERY && p.getStatus() == PaymentStatus.PENDING) {
                p.setStatus(PaymentStatus.PAID);
                p.setPaidAt(LocalDateTime.now());
            }
        });
        order.setStatus(OrderStatus.DELIVERED);
        notificationService.notifyUser(order.getUser(), NotificationType.PUSH, "Order delivered",
                "Your order " + order.getOrderNumber() + " has been delivered. Leave a review for your purchase!");
    }

    private OrderResponse toResponse(Order order) {
        return OrderResponse.from(order, paymentRepository.findByOrderId(order.getId()).orElse(null),
                shipmentRepository.findByOrderId(order.getId()).orElse(null));
    }

    private PageResponse<OrderResponse> toPage(Page<Order> page) {
        List<Order> orders = page.getContent();
        Map<Long, Payment> payments = orders.isEmpty() ? Map.of() : paymentRepository.findByOrderIn(orders).stream()
                .collect(Collectors.toMap(p -> p.getOrder().getId(), Function.identity()));
        Map<Long, Shipment> shipments = orders.isEmpty() ? Map.of() : shipmentRepository.findByOrderIn(orders).stream()
                .collect(Collectors.toMap(s -> s.getOrder().getId(), Function.identity()));
        return PageResponse.of(page, o -> OrderResponse.from(o, payments.get(o.getId()), shipments.get(o.getId())));
    }
}
