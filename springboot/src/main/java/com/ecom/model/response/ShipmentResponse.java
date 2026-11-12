package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record ShipmentResponse(Long id, String orderNumber, ShippingMethod method, BigDecimal fee, String trackingNumber,
                               ShipmentStatus status, LocalDateTime shippedAt, LocalDateTime deliveredAt) {
    public static ShipmentResponse from(Shipment s) {
        return new ShipmentResponse(s.getId(), s.getOrder().getOrderNumber(), s.getMethod(), s.getFee(), s.getTrackingNumber(),
                s.getStatus(), s.getShippedAt(), s.getDeliveredAt());
    }
}
