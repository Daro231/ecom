package com.ecom.config;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/** Fails fast when KHQR_MODE=bakong but the credentials are missing. */
@Component
@ConditionalOnProperty(name = "payment.khqr.mode", havingValue = "bakong")
@RequiredArgsConstructor
public class BakongStartupValidator {
    private final BakongProperties properties;

    @PostConstruct
    void validate() {
        if (properties.getToken() == null || properties.getToken().isBlank()) {
            throw new IllegalStateException("payment.khqr.mode=bakong requires BAKONG_TOKEN (Bakong Open API token) to be set");
        }
        if (properties.getAccountId() == null || properties.getAccountId().isBlank()) {
            throw new IllegalStateException("payment.khqr.mode=bakong requires BAKONG_ACCOUNT_ID (e.g. yourname@bank) to be set");
        }
    }
}
