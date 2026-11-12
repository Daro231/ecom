package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record InventoryResponse(Long productId, String sku, String name, int stockQuantity, int lowStockThreshold,
                                String category, boolean lowStock) {
    public static InventoryResponse from(Product p) {
        return new InventoryResponse(p.getId(), p.getSku(), p.getName(), p.getStockQuantity(), p.getLowStockThreshold(),
                p.getCategory().getName(), p.getStockQuantity() <= p.getLowStockThreshold());
    }
}
