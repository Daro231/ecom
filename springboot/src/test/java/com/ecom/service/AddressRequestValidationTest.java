package com.ecom.service;

import com.ecom.model.request.AddressRequest;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class AddressRequestValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    private AddressRequest req(String lat, String lng) {
        return new AddressRequest("R", "012", "Street", "Phnom Penh", null,
                lat == null ? null : new BigDecimal(lat), lng == null ? null : new BigDecimal(lng));
    }

    @Test
    void neitherOrBothInRangeIsValid() {
        assertThat(validator.validate(req(null, null))).isEmpty();
        assertThat(validator.validate(req("11.5", "104.9"))).isEmpty();
        assertThat(validator.validate(req("-90", "-180"))).isEmpty();
        assertThat(validator.validate(req("90", "180"))).isEmpty();
    }

    @Test
    void outOfRangeIsInvalid() {
        assertThat(validator.validate(req("90.000001", "0"))).hasSize(1);
        assertThat(validator.validate(req("-90.000001", "0"))).hasSize(1);
        assertThat(validator.validate(req("0", "180.000001"))).hasSize(1);
        assertThat(validator.validate(req("0", "-180.000001"))).hasSize(1);
    }

    @Test
    void onlyOneCoordinateIsInvalid() {
        assertThat(validator.validate(req("10", null))).hasSize(1);
        assertThat(validator.validate(req(null, "10"))).hasSize(1);
    }
}
