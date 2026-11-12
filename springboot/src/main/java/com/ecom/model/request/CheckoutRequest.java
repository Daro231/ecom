package com.ecom.model.request;

import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record CheckoutRequest(
        @NotNull(message = "Address id is required") Long addressId,
        @NotNull(message = "Shipping method is required") ShippingMethod shippingMethod,
        @NotNull(message = "Payment method is required") PaymentMethod paymentMethod,
        String couponCode,
        @Size(max = 500) String note) {
}
