package com.ecom.model.enumerate;

import java.math.BigDecimal;

public enum ShippingMethod {
    STANDARD("Standard", new BigDecimal("5.00"), "3-5 days"),
    EXPRESS("Express", new BigDecimal("15.00"), "1-2 days"),
    SAME_DAY("Same day (Phnom Penh)", new BigDecimal("25.00"), "Same day");

    private final String label;
    private final BigDecimal fee;
    private final String estimatedDelivery;

    ShippingMethod(String label, BigDecimal fee, String estimatedDelivery) {
        this.label = label;
        this.fee = fee;
        this.estimatedDelivery = estimatedDelivery;
    }

    public String getLabel() {
        return label;
    }

    public BigDecimal getFee() {
        return fee;
    }

    public String getEstimatedDelivery() {
        return estimatedDelivery;
    }
}
