package com.ecom.model.request;

import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record ProductRequest(
        @NotBlank(message = "SKU is required") @Size(max = 50) String sku,
        @NotBlank(message = "Name is required") @Size(max = 200) String name,
        @Size(max = 4000) String description,
        @NotNull(message = "Price is required") @DecimalMin(value = "0.01", message = "Price must be positive") @Digits(integer = 10, fraction = 2) BigDecimal price,
        @NotNull(message = "Category is required") Long categoryId,
        @NotNull(message = "Brand is required") Long brandId,
        String cpu,
        @Min(0) Integer ram,
        String storage,
        String gpu,
        @DecimalMin("0.0") Double screenSize,
        String os,
        @Min(0) Integer warrantyMonths,
        @NotNull(message = "Stock quantity is required") @Min(value = 0, message = "Stock cannot be negative") Integer stockQuantity,
        @Min(0) Integer lowStockThreshold,
        Boolean active,
        List<@NotBlank String> imageUrls) {
}
