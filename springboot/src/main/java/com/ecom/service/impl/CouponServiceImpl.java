package com.ecom.service.impl;

import com.ecom.common.exception.*;
import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;
import com.ecom.repository.*;
import com.ecom.service.*;
import com.ecom.util.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class CouponServiceImpl implements CouponService {
    private final CouponRepository couponRepository;

    @Override
    @Transactional(readOnly = true)
    public CouponResult evaluate(String code, BigDecimal subtotal) {
        Coupon coupon = couponRepository.findByCode(normalize(code))
                .orElseThrow(() -> new BadRequestException("Coupon code is invalid"));
        LocalDateTime now = LocalDateTime.now();
        if (!coupon.isActive()) {
            throw new BadRequestException("Coupon is not active");
        }
        if ((coupon.getStartAt() != null && now.isBefore(coupon.getStartAt()))
                || (coupon.getEndAt() != null && now.isAfter(coupon.getEndAt()))) {
            throw new BadRequestException("Coupon is expired or not yet valid");
        }
        if (coupon.getMaxUses() != null && coupon.getUsedCount() >= coupon.getMaxUses()) {
            throw new BadRequestException("Coupon has reached its maximum number of uses");
        }
        if (coupon.getMinOrderAmount() != null && subtotal.compareTo(coupon.getMinOrderAmount()) < 0) {
            throw new BadRequestException("Order must be at least $" + coupon.getMinOrderAmount() + " to use this coupon");
        }
        BigDecimal discount = coupon.getDiscountType() == DiscountType.PERCENT
                ? subtotal.multiply(coupon.getDiscountValue()).divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP)
                : coupon.getDiscountValue();
        return new CouponResult(coupon, MoneyUtil.scale(discount.min(subtotal)));
    }

    @Override
    @Transactional
    public void consume(Coupon coupon) {
        if (couponRepository.incrementUsage(coupon.getId()) == 0) {
            throw new BadRequestException("Coupon has reached its maximum number of uses");
        }
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<CouponResponse> list(int page, int size) {
        return PageResponse.of(couponRepository.findAll(PageUtil.newestFirst(page, size)), CouponResponse::from);
    }

    @Override
    @Transactional
    public CouponResponse create(CouponRequest request) {
        String code = normalize(request.code());
        if (couponRepository.existsByCode(code)) {
            throw new ConflictException("Coupon code already exists");
        }
        Coupon coupon = Coupon.builder().code(code).build();
        apply(coupon, request);
        return CouponResponse.from(couponRepository.save(coupon));
    }

    @Override
    @Transactional
    public CouponResponse update(Long id, CouponRequest request) {
        Coupon coupon = find(id);
        String code = normalize(request.code());
        if (!coupon.getCode().equals(code) && couponRepository.existsByCode(code)) {
            throw new ConflictException("Coupon code already exists");
        }
        coupon.setCode(code);
        apply(coupon, request);
        return CouponResponse.from(coupon);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        couponRepository.delete(find(id));
    }

    private Coupon find(Long id) {
        return couponRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Coupon not found"));
    }

    private void apply(Coupon coupon, CouponRequest r) {
        if (r.discountType() == DiscountType.PERCENT && r.value().compareTo(BigDecimal.valueOf(100)) > 0) {
            throw new BadRequestException("Percent discount cannot exceed 100");
        }
        if (r.startAt() != null && r.endAt() != null && r.endAt().isBefore(r.startAt())) {
            throw new BadRequestException("End date must be after start date");
        }
        coupon.setDiscountType(r.discountType());
        coupon.setDiscountValue(MoneyUtil.scale(r.value()));
        coupon.setMinOrderAmount(r.minOrderAmount() == null ? null : MoneyUtil.scale(r.minOrderAmount()));
        coupon.setMaxUses(r.maxUses());
        coupon.setStartAt(r.startAt());
        coupon.setEndAt(r.endAt());
        coupon.setActive(r.active() == null || r.active());
    }

    private String normalize(String code) {
        return code.trim().toUpperCase();
    }
}
