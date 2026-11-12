package com.ecom.model.entity;

import com.ecom.model.enumerate.*;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.BatchSize;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity(name = "Orders")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "orders")
public class Order extends BaseEntity {

    @Column(nullable = false, unique = true, length = 40)
    private String orderNumber;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private OrderStatus status;
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal subtotal;
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal discountAmount;
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal shippingFee;
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal total;
    private String couponCode;
    @Column(nullable = false)
    private String receiverName;
    @Column(nullable = false, length = 30)
    private String receiverPhone;
    @Column(nullable = false, length = 500)
    private String shippingAddress;
    @Column(precision = 9, scale = 6)
    private BigDecimal deliveryLatitude;
    @Column(precision = 9, scale = 6)
    private BigDecimal deliveryLongitude;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ShippingMethod shippingMethod;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private PaymentMethod paymentMethod;
    @Column(length = 500)
    private String note;
    @Column(length = 500)
    private String cancelledReason;
    @Builder.Default
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("id ASC")
    @BatchSize(size = 50)
    private List<OrderItem> items = new ArrayList<>();
}
