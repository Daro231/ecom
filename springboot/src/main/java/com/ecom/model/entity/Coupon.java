package com.ecom.model.entity;

import com.ecom.model.enumerate.*;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.BatchSize;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "coupons")
public class Coupon extends BaseEntity {

    @Column(nullable = false, unique = true, length = 50)
    private String code;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DiscountType discountType;
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal discountValue;
    @Column(precision = 12, scale = 2)
    private BigDecimal minOrderAmount;
    private Integer maxUses;
    @Builder.Default
    @Column(nullable = false)
    private int usedCount = 0;
    private LocalDateTime startAt;
    private LocalDateTime endAt;
    @Builder.Default
    @Column(nullable = false)
    private boolean active = true;
}
