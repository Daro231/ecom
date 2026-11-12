package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record InventoryLogResponse(Long id, Long productId, int changeQuantity, InventoryReason reason, int stockAfter,
                                   Long createdBy, String note, LocalDateTime createdAt) {
    public static InventoryLogResponse from(InventoryLog l) {
        return new InventoryLogResponse(l.getId(), l.getProduct().getId(), l.getChangeQuantity(), l.getReason(),
                l.getStockAfter(), l.getCreatedBy(), l.getNote(), l.getCreatedAt());
    }
}
