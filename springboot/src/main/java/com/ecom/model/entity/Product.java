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
@Table(name = "products")
public class Product extends BaseEntity {

    @Column(nullable = false, unique = true, length = 50)
    private String sku;
    @Column(nullable = false, length = 200)
    private String name;
    @Column(nullable = false, unique = true, length = 220)
    private String slug;
    @Column(length = 4000)
    private String description;
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "category_id")
    private Category category;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "brand_id")
    private Brand brand;
    private String cpu;
    private Integer ram;
    private String storage;
    private String gpu;
    private Double screenSize;
    private String os;
    private Integer warrantyMonths;
    @Builder.Default
    @Column(nullable = false)
    private int stockQuantity = 0;
    @Builder.Default
    @Column(nullable = false)
    private int lowStockThreshold = 5;
    @Builder.Default
    @Column(nullable = false)
    private boolean active = true;
    @Builder.Default
    @Column(nullable = false)
    private double averageRating = 0.0;
    @Builder.Default
    @Column(nullable = false)
    private int reviewCount = 0;
    @Builder.Default
    @Column(nullable = false)
    private int soldCount = 0;
    @Version
    private Long version;
    @Builder.Default
    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("sortOrder ASC")
    @BatchSize(size = 50)
    private List<ProductImage> images = new ArrayList<>();
}
