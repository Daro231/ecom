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
@Table(name = "payments")
public class Payment extends BaseEntity {

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", unique = true)
    private Order order;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private PaymentMethod method;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PaymentStatus status;
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;
    private String transactionRef;
    private LocalDateTime paidAt;
    @Column(columnDefinition = "TEXT")
    private String khqrString;
    @Column(length = 64, unique = true)
    private String khqrMd5;
    private LocalDateTime khqrExpiresAt;
    @Column(length = 128)
    private String bakongHash;
    @Column(length = 100)
    private String fromAccountId;
    private LocalDateTime lastCheckedAt;
    @Builder.Default
    @Column(nullable = false)
    private int checkCount = 0;
    private String failureReason;
    /** While in the future, an auto-cancelled KHQR payment is still checked with Bakong for a late payment. */
    private LocalDateTime lateWatchUntil;
}
