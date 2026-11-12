package com.ecom.service;

import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface OrderService {
    OrderResponse checkout(Long userId, CheckoutRequest request);

    PageResponse<OrderResponse> myOrders(Long userId, int page, int size);

    OrderResponse getMyOrder(Long userId, String orderNumber);

    OrderResponse cancel(Long userId, String orderNumber, String reason);

    InvoiceResponse invoice(Long userId, String orderNumber);

    PageResponse<OrderResponse> adminSearch(OrderStatus status, LocalDate from, LocalDate to, String keyword, int page, int size);

    OrderResponse adminGet(String orderNumber);

    OrderResponse adminChangeStatus(String orderNumber, OrderStatus status, String reason);

    /** Admin: re-reserves stock for a cancelled order whose payment is PAID_AFTER_CANCEL; order becomes CONFIRMED, payment PAID. */
    OrderResponse restoreAfterPayment(String orderNumber);

    OrderResponse ship(String orderNumber, String trackingNumber);

    /** Applies a validated status transition and its side effects. */
    void changeStatus(Order order, OrderStatus target, String reason);

    Order findOrder(String orderNumber);
}
