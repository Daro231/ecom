package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record OrderResponse(Long id, String orderNumber, OrderStatus status, BigDecimal subtotal, BigDecimal discountAmount,
                            BigDecimal shippingFee, BigDecimal total, String couponCode, String receiverName,
                            String receiverPhone, String shippingAddress,
                            BigDecimal deliveryLatitude, BigDecimal deliveryLongitude, ShippingMethod shippingMethod,
                            PaymentMethod paymentMethod, String note, String cancelledReason, String customerEmail,
                            List<OrderItemResponse> items, PaymentResponse payment, ShipmentResponse shipment,
                            LocalDateTime createdAt) {
    public static OrderResponse from(Order o, Payment payment, Shipment shipment) {
        return new OrderResponse(o.getId(), o.getOrderNumber(), o.getStatus(), o.getSubtotal(), o.getDiscountAmount(),
                o.getShippingFee(), o.getTotal(), o.getCouponCode(), o.getReceiverName(), o.getReceiverPhone(),
                o.getShippingAddress(), o.getDeliveryLatitude(), o.getDeliveryLongitude(), o.getShippingMethod(), o.getPaymentMethod(), o.getNote(), o.getCancelledReason(),
                o.getUser().getEmail(), o.getItems().stream().map(OrderItemResponse::from).toList(),
                payment == null ? null : PaymentResponse.from(payment),
                shipment == null ? null : ShipmentResponse.from(shipment), o.getCreatedAt());
    }
}
