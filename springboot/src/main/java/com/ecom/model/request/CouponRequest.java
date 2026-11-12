package com.ecom.model.request;

import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record CouponRequest(
        @NotBlank(message = "Code is required") @Size(max = 50) String code,
        @NotNull(message = "Discount type is required") DiscountType discountType,
        @NotNull(message = "Value is required") @DecimalMin(value = "0.01", message = "Value must be positive") BigDecimal value,
        @DecimalMin("0.00") BigDecimal minOrderAmount,
        @Min(1) Integer maxUses,
        LocalDateTime startAt,
        LocalDateTime endAt,
        Boolean active) {
}
