package com.ecom.repository;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.*;

public interface PaymentRepository extends JpaRepository<Payment, Long> {
    Optional<Payment> findByOrderId(Long orderId);

    List<Payment> findByOrderIn(Collection<Order> orders);

    @EntityGraph(attributePaths = {"order"})
    Page<Payment> findAll(Pageable pageable);

    @EntityGraph(attributePaths = {"order"})
    Page<Payment> findByStatus(PaymentStatus status, Pageable pageable);

    @EntityGraph(attributePaths = {"order"})
    Optional<Payment> findByOrder_OrderNumberAndOrder_User_Id(String orderNumber, Long userId);

    @EntityGraph(attributePaths = {"order"})
    Optional<Payment> findByOrder_OrderNumber(String orderNumber);

    @EntityGraph(attributePaths = {"order"})
    Optional<Payment> findWithOrderById(Long id);

    /** Unpaid KHQR payments whose QR (plus grace period) has not run out yet. */
    @EntityGraph(attributePaths = {"order"})
    @Query("select p from Payment p where p.method = com.ecom.model.enumerate.PaymentMethod.KHQR "
            + "and p.status = com.ecom.model.enumerate.PaymentStatus.PENDING and p.khqrMd5 is not null and p.khqrExpiresAt > :cutoff "
            + "order by p.id")
    List<Payment> findPendingKhqr(@Param("cutoff") LocalDateTime cutoff);

    /** Atomically reserves a Bakong check; returns 0 when the payment was checked too recently or is no longer PENDING. */
    @Modifying
    @Query("update Payment p set p.lastCheckedAt = :now, p.checkCount = p.checkCount + 1 where p.id = :id "
            + "and p.status = com.ecom.model.enumerate.PaymentStatus.PENDING "
            + "and (p.lastCheckedAt is null or p.lastCheckedAt < :threshold)")
    int claimCheck(@Param("id") Long id, @Param("now") LocalDateTime now, @Param("threshold") LocalDateTime threshold);

    /** Conditional update: only the first caller flips PENDING to PAID, which makes settlement idempotent. */
    @Modifying
    @Query("update Payment p set p.status = com.ecom.model.enumerate.PaymentStatus.PAID, p.paidAt = :paidAt, "
            + "p.transactionRef = :ref, p.bakongHash = :hash, p.fromAccountId = :fromAccount "
            + "where p.id = :id and p.status = com.ecom.model.enumerate.PaymentStatus.PENDING")
    int markPaidIfPending(@Param("id") Long id, @Param("paidAt") LocalDateTime paidAt, @Param("ref") String ref,
                          @Param("hash") String hash, @Param("fromAccount") String fromAccount);

    @Modifying
    @Query("update Payment p set p.status = com.ecom.model.enumerate.PaymentStatus.FAILED, p.failureReason = :reason "
            + "where p.id = :id and p.status = com.ecom.model.enumerate.PaymentStatus.PENDING")
    int markFailedIfPending(@Param("id") Long id, @Param("reason") String reason);

    /** Auto-cancelled KHQR payments that may still be paid late. */
    @EntityGraph(attributePaths = {"order"})
    @Query("select p from Payment p where p.status = com.ecom.model.enumerate.PaymentStatus.FAILED "
            + "and p.lateWatchUntil > :now and p.khqrMd5 is not null order by p.id")
    List<Payment> findLateWatch(@Param("now") LocalDateTime now);

    /** Reserves a late-payment Bakong check (same rate limit as normal checks). */
    @Modifying
    @Query("update Payment p set p.lastCheckedAt = :now, p.checkCount = p.checkCount + 1 where p.id = :id "
            + "and p.status = com.ecom.model.enumerate.PaymentStatus.FAILED and p.lateWatchUntil > :now "
            + "and (p.lastCheckedAt is null or p.lastCheckedAt < :threshold)")
    int claimLateCheck(@Param("id") Long id, @Param("now") LocalDateTime now, @Param("threshold") LocalDateTime threshold);

    /** Only the first caller flips an auto-cancelled payment to PAID_AFTER_CANCEL. */
    @Modifying
    @Query("update Payment p set p.status = com.ecom.model.enumerate.PaymentStatus.PAID_AFTER_CANCEL, p.paidAt = :paidAt, "
            + "p.transactionRef = :ref, p.bakongHash = :hash, p.fromAccountId = :fromAccount, p.lateWatchUntil = null, "
            + "p.failureReason = :reason "
            + "where p.id = :id and p.status = com.ecom.model.enumerate.PaymentStatus.FAILED and p.lateWatchUntil is not null")
    int markPaidAfterCancel(@Param("id") Long id, @Param("paidAt") LocalDateTime paidAt, @Param("ref") String ref,
                            @Param("hash") String hash, @Param("fromAccount") String fromAccount, @Param("reason") String reason);

    /** Stops watching a payment (mismatching late payment, already alerted). */
    @Modifying
    @Query("update Payment p set p.lateWatchUntil = null where p.id = :id and p.lateWatchUntil is not null")
    int stopLateWatch(@Param("id") Long id);

    /** KHQR payments still PENDING after the QR and its grace period expired. */
    @Query("select p.id from Payment p where p.method = com.ecom.model.enumerate.PaymentMethod.KHQR "
            + "and p.status = com.ecom.model.enumerate.PaymentStatus.PENDING and p.khqrExpiresAt is not null and p.khqrExpiresAt < :cutoff")
    List<Long> findExpiredPendingKhqrIds(@Param("cutoff") LocalDateTime cutoff);
}
