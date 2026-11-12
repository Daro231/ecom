package com.ecom.repository;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.*;


public interface OrderRepository extends JpaRepository<Order, Long>, JpaSpecificationExecutor<Order> {
    @EntityGraph(attributePaths = {"items", "user"})
    Optional<Order> findByOrderNumber(String orderNumber);

    @EntityGraph(attributePaths = {"items", "user"})
    Optional<Order> findByOrderNumberAndUserId(String orderNumber, Long userId);

    Page<Order> findByUserId(Long userId, Pageable pageable);

    long countByOrderNumberStartingWith(String prefix);

    boolean existsByOrderNumber(String orderNumber);

    /** Still-PENDING KHQR orders created before the cutoff that have no PAID payment. */
    @Query("select o.id from Orders o where o.paymentMethod = com.ecom.model.enumerate.PaymentMethod.KHQR "
            + "and o.status = com.ecom.model.enumerate.OrderStatus.PENDING and o.createdAt < :cutoff "
            + "and not exists (select p.id from Payment p where p.order = o and p.status = com.ecom.model.enumerate.PaymentStatus.PAID) "
            + "order by o.id")
    List<Long> findUnpaidKhqrOrderIds(@Param("cutoff") LocalDateTime cutoff);

    long countByStatus(OrderStatus status);

    @Query("select o from Orders o where o.createdAt >= :from and o.createdAt < :to and o.status not in :excluded order by o.createdAt")
    List<Order> findForSales(@Param("from") LocalDateTime from, @Param("to") LocalDateTime to,
                             @Param("excluded") Collection<OrderStatus> excluded);

    @Query("select coalesce(sum(o.total), 0) from Orders o where o.status not in :excluded")
    java.math.BigDecimal sumTotalExcluding(@Param("excluded") Collection<OrderStatus> excluded);
}
