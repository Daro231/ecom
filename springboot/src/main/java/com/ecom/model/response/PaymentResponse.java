package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record PaymentResponse(Long id, String orderNumber, PaymentMethod method, PaymentStatus status, BigDecimal amount,
                              String transactionRef, LocalDateTime paidAt, String failureReason) {
    public static PaymentResponse from(Payment p) {
        return new PaymentResponse(p.getId(), p.getOrder().getOrderNumber(), p.getMethod(), p.getStatus(), p.getAmount(),
                p.getTransactionRef(), p.getPaidAt(), p.getFailureReason());
    }
}
