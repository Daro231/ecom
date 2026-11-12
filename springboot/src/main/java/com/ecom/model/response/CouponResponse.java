package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record CouponResponse(Long id, String code, DiscountType discountType, BigDecimal value, BigDecimal minOrderAmount,
                             Integer maxUses, int usedCount, LocalDateTime startAt, LocalDateTime endAt, boolean active) {
    public static CouponResponse from(Coupon c) {
        return new CouponResponse(c.getId(), c.getCode(), c.getDiscountType(), c.getDiscountValue(), c.getMinOrderAmount(),
                c.getMaxUses(), c.getUsedCount(), c.getStartAt(), c.getEndAt(), c.isActive());
    }
}
