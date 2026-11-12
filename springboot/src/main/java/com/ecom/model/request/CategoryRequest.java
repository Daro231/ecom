package com.ecom.model.request;

import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record CategoryRequest(
        @NotBlank(message = "Name is required") @Size(max = 100) String name,
        @Size(max = 255) String description) {
}
