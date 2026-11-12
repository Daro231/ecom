package com.ecom.repository;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.*;


public interface InventoryLogRepository extends JpaRepository<InventoryLog, Long> {
    Page<InventoryLog> findByProductId(Long productId, Pageable pageable);

    @Modifying
    @Query("delete from InventoryLog l where l.product.id = :productId")
    void deleteByProductId(@Param("productId") Long productId);
}
