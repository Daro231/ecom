package com.ecom.repository;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.*;


public interface ShipmentRepository extends JpaRepository<Shipment, Long> {
    Optional<Shipment> findByOrderId(Long orderId);

    List<Shipment> findByOrderIn(Collection<Order> orders);
}
