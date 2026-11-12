package com.ecom.util;

import com.ecom.common.constant.AppConstants;
import com.ecom.model.enumerate.ShippingMethod;

import java.math.BigDecimal;
import java.math.RoundingMode;

public final class MoneyUtil {
    private MoneyUtil() {
    }

    public static BigDecimal scale(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    public static BigDecimal shippingFee(BigDecimal subtotal, ShippingMethod method) {
        if (subtotal.compareTo(AppConstants.FREE_SHIPPING_THRESHOLD) >= 0) {
            return scale(BigDecimal.ZERO);
        }
        return scale(method.getFee());
    }
}
