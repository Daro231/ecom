package com.ecom.model.request;

import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record PaymentCallbackRequest(
        @NotBlank(message = "Transaction reference is required") String transactionRef,
        @NotBlank(message = "Order number is required") String orderNumber,
        @NotNull(message = "Status is required") PaymentStatus status) {
}
