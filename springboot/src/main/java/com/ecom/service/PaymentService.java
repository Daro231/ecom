package com.ecom.service;

import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface PaymentService {
    KhqrResponse generateKhqr(Long userId, String orderNumber);

    PaymentResponse status(Long userId, String orderNumber);

    PaymentResponse callback(PaymentCallbackRequest request);

    PageResponse<PaymentResponse> adminList(PaymentStatus status, int page, int size);

    PaymentResponse refund(Long paymentId);

    /** Checks all unpaid, unexpired KHQR payments with the provider; returns how many were newly confirmed. */
    int reconcilePending();

    /** Cancels KHQR orders that stayed unpaid longer than payment.khqr.auto-cancel-minutes; returns how many. */
    int cancelUnpaidKhqrOrders();

    /** Checks auto-cancelled KHQR payments still inside their watch window for a late payment; returns how many were found paid. */
    int checkLatePayments();

    /** Admin: refunds by payment id or order number. */
    PaymentResponse refund(String idOrOrderNumber);

    /** Admin: re-checks one payment with the provider right now (no rate limit). */
    PaymentResponse recheck(String orderNumber);
}
