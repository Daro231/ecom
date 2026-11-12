package com.ecom.config;

import com.ecom.model.enumerate.KhqrMode;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@ConfigurationProperties(prefix = "payment.khqr")
@Validated
@Getter
@Setter
public class KhqrProperties {
    @NotNull
    private KhqrMode mode = KhqrMode.MOCK;
    @Min(1)
    private int expiryMinutes = 10;
    @Min(1000)
    private long pollIntervalMs = 5000;
    @Min(0)
    private int expiryGraceMinutes = 5;
    @Min(0)
    private int minCheckIntervalSeconds = 3;

    /** KHQR orders still unpaid this long after creation are cancelled; 0 disables the auto-cancel. */
    @Min(0)
    private int autoCancelMinutes = 30;
    @Min(1000)
    private long autoCancelCheckIntervalMs = 60000;

    /** How long after an auto-cancel Bakong keeps being asked whether the customer paid anyway (bakong mode only); 0 disables. */
    @Min(0)
    private int latePaymentWatchHours = 24;
    @Min(1000)
    private long latePaymentCheckIntervalMs = 60000;

    public boolean isBakong() {
        return mode == KhqrMode.BAKONG;
    }
}
