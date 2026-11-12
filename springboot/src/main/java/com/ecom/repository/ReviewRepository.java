package com.ecom.repository;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.*;


public interface ReviewRepository extends JpaRepository<Review, Long> {
    @EntityGraph(attributePaths = {"user"})
    Page<Review> findByProductIdAndVisibleTrue(Long productId, Pageable pageable);

    @EntityGraph(attributePaths = {"user", "product"})
    Page<Review> findAll(Pageable pageable);

    boolean existsByUserIdAndProductId(Long userId, Long productId);

    @Query("select avg(r.rating) from Review r where r.product.id = :productId and r.visible = true")
    Double averageRating(@Param("productId") Long productId);

    @Query("select count(r) from Review r where r.product.id = :productId and r.visible = true")
    long countVisible(@Param("productId") Long productId);

    @Modifying
    @Query("delete from Review r where r.product.id = :productId")
    void deleteByProductId(@Param("productId") Long productId);
}
