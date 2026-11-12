package com.ecom.repository;

import com.ecom.model.entity.Order;
import com.ecom.model.enumerate.OrderStatus;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public final class OrderSpecifications {
    private OrderSpecifications() {
    }

    public static Specification<Order> filter(OrderStatus status, LocalDateTime from, LocalDateTime to, String keyword) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (query != null && !Long.class.equals(query.getResultType()) && !long.class.equals(query.getResultType())) {
                root.fetch("user", JoinType.LEFT);
            }
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            if (from != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), from));
            }
            if (to != null) {
                predicates.add(cb.lessThan(root.get("createdAt"), to));
            }
            if (keyword != null && !keyword.isBlank()) {
                String like = "%" + keyword.trim().toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("orderNumber")), like),
                        cb.like(cb.lower(root.get("receiverName")), like),
                        cb.like(cb.lower(root.get("receiverPhone")), like)));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
