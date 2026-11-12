package com.ecom.model.request;

import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record AdjustStockRequest(
        @NotNull(message = "Delta is required") Integer delta,
        @Size(max = 500) String note) {
}
