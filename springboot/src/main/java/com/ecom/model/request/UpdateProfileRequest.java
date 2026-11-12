package com.ecom.model.request;

import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record UpdateProfileRequest(
        @NotBlank(message = "Full name is required") @Size(max = 255) String fullName,
        @Size(max = 30) String phone) {
}
