package com.ecom.repository;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.*;


public interface CouponRepository extends JpaRepository<Coupon, Long> {
    Optional<Coupon> findByCode(String code);

    boolean existsByCode(String code);

    @Modifying
    @Query("update Coupon c set c.usedCount = c.usedCount + 1 where c.id = :id and (c.maxUses is null or c.usedCount < c.maxUses)")
    int incrementUsage(@Param("id") Long id);
}
