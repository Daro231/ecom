package com.ecom.model.request;

import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record ReviewRequest(
        @NotNull(message = "Rating is required") @Min(value = 1, message = "Rating must be 1-5") @Max(value = 5, message = "Rating must be 1-5") Integer rating,
        @Size(max = 2000) String comment) {
}
