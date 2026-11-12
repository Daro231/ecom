package com.ecom.service;

import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface CouponService {
    /** Validates a coupon against a subtotal and returns the discount; throws BadRequestException when unusable. */
    CouponResult evaluate(String code, BigDecimal subtotal);

    /** Atomically increments the usage counter, failing when the maximum number of uses was reached. */
    void consume(Coupon coupon);

    PageResponse<CouponResponse> list(int page, int size);

    CouponResponse create(CouponRequest request);

    CouponResponse update(Long id, CouponRequest request);

    void delete(Long id);

    record CouponResult(Coupon coupon, BigDecimal discount) {
    }
}
