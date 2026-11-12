package com.ecom.model.request;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.ecom.model.enumerate.*;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record AddressRequest(
        @NotBlank(message = "Receiver name is required") @Size(max = 255) String receiverName,
        @NotBlank(message = "Phone is required") @Size(max = 30) String phone,
        @NotBlank(message = "Address line is required") @Size(max = 255) String line1,
        @NotBlank(message = "City/province is required") @Size(max = 100) String city,
        Boolean isDefault,
        @DecimalMin(value = "-90", message = "Latitude must be between -90 and 90")
        @DecimalMax(value = "90", message = "Latitude must be between -90 and 90") BigDecimal latitude,
        @DecimalMin(value = "-180", message = "Longitude must be between -180 and 180")
        @DecimalMax(value = "180", message = "Longitude must be between -180 and 180") BigDecimal longitude) {

    @JsonIgnore
    @AssertTrue(message = "Latitude and longitude must be provided together")
    public boolean isLocationComplete() {
        return (latitude == null) == (longitude == null);
    }
}
