package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record OrderItemResponse(Long id, Long productId, String productName, BigDecimal unitPrice, int quantity,
                                BigDecimal lineTotal) {
    public static OrderItemResponse from(OrderItem i) {
        return new OrderItemResponse(i.getId(), i.getProduct().getId(), i.getProductName(), i.getUnitPrice(), i.getQuantity(), i.getLineTotal());
    }
}
