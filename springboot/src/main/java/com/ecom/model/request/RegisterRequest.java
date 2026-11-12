package com.ecom.model.request;

import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record RegisterRequest(
        @NotBlank(message = "Full name is required") @Size(max = 255) String fullName,
        @NotBlank(message = "Email is required") @Email(message = "Email is invalid") String email,
        @NotBlank(message = "Password is required") @Size(min = 8, max = 100, message = "Password must be 8-100 characters") String password,
        @Size(max = 30) String phone) {
}
