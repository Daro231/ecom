package com.ecom.service;

import com.ecom.common.exception.BadRequestException;
import com.ecom.common.exception.ConflictException;
import com.ecom.common.exception.ResourceNotFoundException;
import com.ecom.model.entity.Coupon;
import com.ecom.model.enumerate.DiscountType;
import com.ecom.model.request.CouponRequest;
import com.ecom.repository.CouponRepository;
import com.ecom.service.impl.CouponServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CouponServiceTest {
    @Mock
    CouponRepository couponRepository;
    @InjectMocks
    CouponServiceImpl couponService;

    Coupon coupon;

    @BeforeEach
    void setUp() {
        coupon = TestData.coupon(DiscountType.PERCENT, "10");
    }

    private void found() {
        when(couponRepository.findByCode("CODE")).thenReturn(Optional.of(coupon));
    }

    @Test
    void percentCouponComputesDiscount() {
        found();
        var result = couponService.evaluate(" code ", new BigDecimal("250.00"));
        assertThat(result.discount()).isEqualByComparingTo("25.00");
    }

    @Test
    void fixedCouponComputesDiscount() {
        coupon.setDiscountType(DiscountType.FIXED);
        coupon.setDiscountValue(new BigDecimal("50.00"));
        found();
        assertThat(couponService.evaluate("CODE", new BigDecimal("600.00")).discount()).isEqualByComparingTo("50.00");
    }

    @Test
    void fixedDiscountLargerThanSubtotalIsCapped() {
        coupon.setDiscountType(DiscountType.FIXED);
        coupon.setDiscountValue(new BigDecimal("50.00"));
        found();
        assertThat(couponService.evaluate("CODE", new BigDecimal("30.00")).discount()).isEqualByComparingTo("30.00");
    }

    @Test
    void unknownCodeIsRejected() {
        when(couponRepository.findByCode("CODE")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> couponService.evaluate("CODE", BigDecimal.TEN)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void expiredCouponIsRejected() {
        coupon.setEndAt(LocalDateTime.now().minusDays(1));
        found();
        assertThatThrownBy(() -> couponService.evaluate("CODE", BigDecimal.TEN))
                .isInstanceOf(BadRequestException.class).hasMessageContaining("expired");
    }

    @Test
    void notYetStartedCouponIsRejected() {
        coupon.setStartAt(LocalDateTime.now().plusDays(1));
        found();
        assertThatThrownBy(() -> couponService.evaluate("CODE", BigDecimal.TEN)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void inactiveCouponIsRejected() {
        coupon.setActive(false);
        found();
        assertThatThrownBy(() -> couponService.evaluate("CODE", BigDecimal.TEN)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void couponAtMaxUsesIsRejected() {
        coupon.setMaxUses(5);
        coupon.setUsedCount(5);
        found();
        assertThatThrownBy(() -> couponService.evaluate("CODE", BigDecimal.TEN))
                .isInstanceOf(BadRequestException.class).hasMessageContaining("maximum");
    }

    @Test
    void subtotalBelowMinimumIsRejected() {
        coupon.setMinOrderAmount(new BigDecimal("500.00"));
        found();
        assertThatThrownBy(() -> couponService.evaluate("CODE", new BigDecimal("499.99")))
                .isInstanceOf(BadRequestException.class).hasMessageContaining("at least");
    }

    @Test
    void consumeFailsWhenAtomicIncrementAffectsNoRows() {
        when(couponRepository.incrementUsage(1L)).thenReturn(0);
        assertThatThrownBy(() -> couponService.consume(coupon)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void consumeSucceedsWhenIncremented() {
        when(couponRepository.incrementUsage(1L)).thenReturn(1);
        couponService.consume(coupon);
        verify(couponRepository).incrementUsage(1L);
    }

    @Test
    void createRejectsDuplicateCode() {
        when(couponRepository.existsByCode("NEW")).thenReturn(true);
        var request = new CouponRequest("new", DiscountType.PERCENT, BigDecimal.TEN, null, null, null, null, true);
        assertThatThrownBy(() -> couponService.create(request)).isInstanceOf(ConflictException.class);
    }

    @Test
    void createNormalizesCodeToUpperCase() {
        when(couponRepository.existsByCode("NEW")).thenReturn(false);
        when(couponRepository.save(any(Coupon.class))).thenAnswer(inv -> inv.getArgument(0));
        var request = new CouponRequest(" new ", DiscountType.PERCENT, BigDecimal.TEN, null, 3, null, null, null);

        var response = couponService.create(request);

        assertThat(response.code()).isEqualTo("NEW");
        assertThat(response.active()).isTrue();
        assertThat(response.maxUses()).isEqualTo(3);
    }

    @Test
    void percentOverOneHundredIsRejected() {
        when(couponRepository.existsByCode("BIG")).thenReturn(false);
        var request = new CouponRequest("BIG", DiscountType.PERCENT, new BigDecimal("150"), null, null, null, null, true);
        assertThatThrownBy(() -> couponService.create(request)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void endBeforeStartIsRejected() {
        when(couponRepository.existsByCode("BAD")).thenReturn(false);
        var request = new CouponRequest("BAD", DiscountType.FIXED, BigDecimal.TEN, null, null,
                LocalDateTime.now().plusDays(2), LocalDateTime.now().plusDays(1), true);
        assertThatThrownBy(() -> couponService.create(request)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void updateAndDeleteWork() {
        when(couponRepository.findById(1L)).thenReturn(Optional.of(coupon));
        var request = new CouponRequest("CODE", DiscountType.FIXED, new BigDecimal("20"), null, null, null, null, false);

        var updated = couponService.update(1L, request);
        assertThat(updated.discountType()).isEqualTo(DiscountType.FIXED);
        assertThat(updated.active()).isFalse();

        couponService.delete(1L);
        verify(couponRepository).delete(coupon);
    }

    @Test
    void deleteUnknownCouponIsNotFound() {
        when(couponRepository.findById(9L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> couponService.delete(9L)).isInstanceOf(ResourceNotFoundException.class);
    }
}
