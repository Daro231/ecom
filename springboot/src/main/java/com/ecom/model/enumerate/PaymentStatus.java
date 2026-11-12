package com.ecom.model.enumerate;

public enum PaymentStatus {
    PENDING, PAID, FAILED, REFUNDED,
    /** Customer paid a KHQR order that had already been auto-cancelled; an admin must restore the order or refund. */
    PAID_AFTER_CANCEL
}
