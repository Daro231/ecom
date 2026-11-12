package com.ecom.repository;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.*;


public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {
    boolean existsByOrder_User_IdAndOrder_StatusAndProduct_Id(Long userId, OrderStatus status, Long productId);

    boolean existsByProductId(Long productId);

    @Query("select oi.product.id, oi.productName, sum(oi.quantity) from OrderItem oi where oi.order.status <> :cancelled "
            + "group by oi.product.id, oi.productName order by sum(oi.quantity) desc")
    List<Object[]> topSelling(@Param("cancelled") OrderStatus cancelled, Pageable pageable);
}
