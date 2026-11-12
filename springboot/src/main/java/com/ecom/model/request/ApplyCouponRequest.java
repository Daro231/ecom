package com.ecom.model.request;

import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record ApplyCouponRequest(
        @NotBlank(message = "Coupon code is required") String code,
        ShippingMethod shippingMethod) {
}
