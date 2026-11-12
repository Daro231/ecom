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
@Table(name = "shipments")
public class Shipment extends BaseEntity {

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", unique = true)
    private Order order;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ShippingMethod method;
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal fee;
    private String trackingNumber;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private ShipmentStatus status;
    private LocalDateTime shippedAt;
    private LocalDateTime deliveredAt;
}
