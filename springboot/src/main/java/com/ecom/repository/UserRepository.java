package com.ecom.repository;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.*;


public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    List<User> findByRoleAndEnabledTrue(Role role);

    long countByRole(Role role);

    @Query("select u from User u where lower(u.fullName) like :kw or lower(u.email) like :kw")
    Page<User> search(@Param("kw") String keyword, Pageable pageable);
}
