package com.ecom.common.constant;

import java.math.BigDecimal;

public final class AppConstants {
    private AppConstants() {
    }

    public static final String API_PREFIX = "/api/v1";
    /** Orders with subtotal at or above this amount ship for free. */
    public static final BigDecimal FREE_SHIPPING_THRESHOLD = new BigDecimal("1000.00");
    public static final int DEFAULT_PAGE_SIZE = 12;
    public static final int MAX_PAGE_SIZE = 100;
    public static final int KHQR_EXPIRY_MINUTES = 15;
    public static final String ORDER_NUMBER_PREFIX = "ECOM-";

    public static final String ERR_NOT_FOUND = "NOT_FOUND";
    public static final String ERR_BAD_REQUEST = "BAD_REQUEST";
    public static final String ERR_CONFLICT = "CONFLICT";
    public static final String ERR_INSUFFICIENT_STOCK = "INSUFFICIENT_STOCK";
}
