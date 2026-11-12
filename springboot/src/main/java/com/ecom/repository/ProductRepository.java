package com.ecom.repository;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.*;


public interface ProductRepository extends JpaRepository<Product, Long>, JpaSpecificationExecutor<Product> {
    @Override
    @EntityGraph(attributePaths = {"category", "brand"})
    Page<Product> findAll(Specification<Product> spec, Pageable pageable);

    @EntityGraph(attributePaths = {"category", "brand"})
    Optional<Product> findBySlugAndActiveTrue(String slug);

    boolean existsBySku(String sku);

    boolean existsBySlug(String slug);

    boolean existsByCategoryId(Long categoryId);

    boolean existsByBrandId(Long brandId);

    @EntityGraph(attributePaths = {"category", "brand"})
    @Query("select p from Product p where p.stockQuantity <= p.lowStockThreshold order by p.stockQuantity asc, p.id asc")
    List<Product> findLowStock();

    @Query("select count(p) from Product p where p.stockQuantity <= p.lowStockThreshold")
    long countLowStock();

    @EntityGraph(attributePaths = {"category", "brand"})
    @Query("select p from Product p where lower(p.name) like :kw or lower(p.sku) like :kw")
    Page<Product> searchInventory(@Param("kw") String keyword, Pageable pageable);
}
