package com.ecom.model.request;

import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record VisibilityRequest(
        @NotNull(message = "Visible flag is required") Boolean visible) {
}
