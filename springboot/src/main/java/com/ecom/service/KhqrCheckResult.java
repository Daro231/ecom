package com.ecom.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Outcome of asking the provider whether a KHQR (identified by its MD5) was paid. */
public record KhqrCheckResult(Status status, String hash, String fromAccountId, String toAccountId, BigDecimal amount,
                              String currency, LocalDateTime paidAt) {
    public enum Status {
        PAID, NOT_FOUND, FAILED
    }

    public static KhqrCheckResult notFound() {
        return new KhqrCheckResult(Status.NOT_FOUND, null, null, null, null, null, null);
    }

    public static KhqrCheckResult failed() {
        return new KhqrCheckResult(Status.FAILED, null, null, null, null, null, null);
    }
}
