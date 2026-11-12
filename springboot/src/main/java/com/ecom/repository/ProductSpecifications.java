package com.ecom.repository;

import com.ecom.model.entity.Product;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public final class ProductSpecifications {
    private ProductSpecifications() {
    }

    public static Specification<Product> search(String keyword, Long categoryId, Long brandId, BigDecimal minPrice,
                                                BigDecimal maxPrice, Integer ram, Double minRating, Boolean inStock,
                                                boolean onlyActive) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (onlyActive) {
                predicates.add(cb.isTrue(root.get("active")));
            }
            if (keyword != null && !keyword.isBlank()) {
                String like = "%" + keyword.trim().toLowerCase() + "%";
                var category = root.join("category", JoinType.LEFT);
                var brand = root.join("brand", JoinType.LEFT);
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("name")), like),
                        cb.like(cb.lower(cb.coalesce(root.<String>get("description"), "")), like),
                        cb.like(cb.lower(cb.coalesce(root.<String>get("cpu"), "")), like),
                        cb.like(cb.lower(category.get("name")), like),
                        cb.like(cb.lower(brand.get("name")), like)));
            }
            if (categoryId != null) {
                predicates.add(cb.equal(root.get("category").get("id"), categoryId));
            }
            if (brandId != null) {
                predicates.add(cb.equal(root.get("brand").get("id"), brandId));
            }
            if (minPrice != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("price"), minPrice));
            }
            if (maxPrice != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("price"), maxPrice));
            }
            if (ram != null) {
                predicates.add(cb.equal(root.get("ram"), ram));
            }
            if (minRating != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("averageRating"), minRating));
            }
            if (Boolean.TRUE.equals(inStock)) {
                predicates.add(cb.greaterThan(root.get("stockQuantity"), 0));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
