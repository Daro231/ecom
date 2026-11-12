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
@Table(name = "reviews", uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "product_id"}))
public class Review extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "product_id")
    private Product product;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;
    @Column(nullable = false)
    private int rating;
    @Column(length = 2000)
    private String reviewComment;
    @Builder.Default
    @Column(nullable = false)
    private boolean verifiedPurchase = true;
    @Builder.Default
    @Column(nullable = false)
    private boolean visible = true;
}
