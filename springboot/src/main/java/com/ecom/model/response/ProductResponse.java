package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record ProductResponse(Long id, String sku, String name, String slug, String description, BigDecimal price,
                              CategoryResponse category, BrandResponse brand, String cpu, Integer ram, String storage,
                              String gpu, Double screenSize, String os, Integer warrantyMonths, int stockQuantity,
                              int lowStockThreshold, boolean active, double averageRating, int reviewCount,
                              int soldCount, List<String> images, LocalDateTime createdAt) {
    public static ProductResponse from(Product p) {
        return new ProductResponse(p.getId(), p.getSku(), p.getName(), p.getSlug(), p.getDescription(), p.getPrice(),
                CategoryResponse.from(p.getCategory()), BrandResponse.from(p.getBrand()), p.getCpu(), p.getRam(),
                p.getStorage(), p.getGpu(), p.getScreenSize(), p.getOs(), p.getWarrantyMonths(), p.getStockQuantity(),
                p.getLowStockThreshold(), p.isActive(), p.getAverageRating(), p.getReviewCount(), p.getSoldCount(),
                p.getImages().stream().map(ProductImage::getImageUrl).toList(), p.getCreatedAt());
    }
}
