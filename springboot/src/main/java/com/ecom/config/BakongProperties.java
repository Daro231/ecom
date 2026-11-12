package com.ecom.config;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

import java.math.BigDecimal;

/** Bakong Open API / KHQR settings. Token and account id are secrets and come from environment variables. */
@ConfigurationProperties(prefix = "bakong")
@Validated
@Getter
@Setter
public class BakongProperties {
    @NotBlank
    private String baseUrl = "https://api-bakong.nbc.gov.kh";
    private String token = "";
    private String accountId = "";
    @NotBlank
    private String merchantName = "ECOM Computer Store";
    @NotBlank
    private String merchantCity = "Phnom Penh";
    @NotBlank
    @Pattern(regexp = "USD|KHR", message = "currency must be USD or KHR")
    private String currency = "USD";
    @NotNull
    @DecimalMin("1")
    private BigDecimal khrPerUsd = new BigDecimal("4100");
    private String storeLabel = "ECOM";
    private String terminalLabel = "WEB";
    private int connectTimeoutMs = 5000;
    private int readTimeoutMs = 10000;
}
