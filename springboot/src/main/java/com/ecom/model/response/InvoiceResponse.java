package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record InvoiceResponse(String invoiceNumber, LocalDateTime issuedAt, String orderNumber, OrderStatus orderStatus,
                              String customerName, String customerEmail, String receiverName, String receiverPhone,
                              String shippingAddress, List<OrderItemResponse> items, BigDecimal subtotal,
                              BigDecimal discountAmount, String couponCode, BigDecimal shippingFee, BigDecimal total,
                              PaymentResponse payment) {
}
