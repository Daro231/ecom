package com.ecom.repository;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.*;


public interface AddressRepository extends JpaRepository<Address, Long> {
    List<Address> findByUserIdOrderByIdAsc(Long userId);

    Optional<Address> findByIdAndUserId(Long id, Long userId);
}
