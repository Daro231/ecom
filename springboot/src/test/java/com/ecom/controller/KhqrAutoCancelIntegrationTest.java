package com.ecom.controller;

import com.ecom.model.entity.Product;
import com.ecom.service.PaymentService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.TestPropertySource;
import org.springframework.transaction.support.TransactionTemplate;

import jakarta.persistence.EntityManager;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Unpaid KHQR orders older than payment.khqr.auto-cancel-minutes are cancelled and their stock restored. */
@TestPropertySource(properties = {"payment.khqr.auto-cancel-minutes=30", "payment.khqr.auto-cancel-check-interval-ms=3600000"})
class KhqrAutoCancelIntegrationTest extends AbstractIntegrationTest {
    @Autowired
    PaymentService paymentService;
    @Autowired
    EntityManager entityManager;
    @Autowired
    TransactionTemplate transactions;

    private void age(String orderNumber, int minutes) {
        transactions.executeWithoutResult(status -> entityManager
                .createQuery("update Orders o set o.createdAt = :t where o.orderNumber = :n")
                .setParameter("t", LocalDateTime.now().minusMinutes(minutes)).setParameter("n", orderNumber).executeUpdate());
    }

    private String order(String token, Product product, int qty, String payment) throws Exception {
        addToCart(token, product.getId(), qty);
        return checkout(token, createAddress(token), "STANDARD", payment, null);
    }

    @Test
    void unpaidKhqrOrderIsCancelledStockRestoredAndCustomerNotified() throws Exception {
        String admin = adminToken();
        String customer = registerCustomer();
        Product product = newProduct("Timeout Laptop", "100.00", 5);
        String orderNumber = order(customer, product, 2, "KHQR");
        assertThat(productRepository.findById(product.getId()).orElseThrow().getStockQuantity()).isEqualTo(3);
        age(orderNumber, 31);

        assertThat(paymentService.cancelUnpaidKhqrOrders()).isGreaterThanOrEqualTo(1);

        mvc.perform(get("/api/v1/orders/" + orderNumber, customer))
                .andExpect(jsonPath("$.data.status").value("CANCELLED"))
                .andExpect(jsonPath("$.data.cancelledReason").value("KHQR payment timeout"))
                .andExpect(jsonPath("$.data.payment.status").value("FAILED"))
                .andExpect(jsonPath("$.data.payment.failureReason").value("KHQR payment timeout"));
        assertThat(productRepository.findById(product.getId()).orElseThrow().getStockQuantity()).isEqualTo(5);
        mvc.perform(get("/api/v1/admin/inventory/" + product.getId() + "/logs", admin))
                .andExpect(jsonPath("$.data.content[0].reason").value("CANCEL"))
                .andExpect(jsonPath("$.data.content[0].changeQuantity").value(2))
                .andExpect(jsonPath("$.data.content[0].stockAfter").value(5));
        mvc.perform(get("/api/v1/notifications?size=20", customer))
                .andExpect(jsonPath("$.data.content[?(@.title==\"Order cancelled\")].message", hasItem(containsString("KHQR payment timeout"))));
        mvc.perform(post("/api/v1/payments/" + orderNumber + "/khqr", customer, null)).andExpect(status().isBadRequest());

        // running the job again changes nothing
        int again = paymentService.cancelUnpaidKhqrOrders();
        assertThat(productRepository.findById(product.getId()).orElseThrow().getStockQuantity()).isEqualTo(5);
        assertThat(again).isZero();
    }

    @Test
    void youngPaidAndCashOnDeliveryOrdersAreNotTouched() throws Exception {
        String customer = registerCustomer();
        Product product = newProduct("Safe Laptop", "100.00", 10);
        String young = order(customer, product, 1, "KHQR");
        String paid = order(customer, product, 1, "KHQR");
        String cod = order(customer, product, 1, "CASH_ON_DELIVERY");
        mvc.perform(post("/api/v1/payments/callback", null, Map.of("transactionRef", "TX-SAFE", "orderNumber", paid, "status", "PAID")))
                .andExpect(status().isOk());
        age(paid, 120);
        age(cod, 120);
        age(young, 29);

        paymentService.cancelUnpaidKhqrOrders();

        mvc.perform(get("/api/v1/orders/" + young, customer)).andExpect(jsonPath("$.data.status").value("PENDING"));
        mvc.perform(get("/api/v1/orders/" + paid, customer)).andExpect(jsonPath("$.data.status").value("CONFIRMED"));
        mvc.perform(get("/api/v1/orders/" + cod, customer)).andExpect(jsonPath("$.data.status").value("PENDING"));
        assertThat(productRepository.findById(product.getId()).orElseThrow().getStockQuantity()).isEqualTo(7);
    }

    @Test
    void orderWhoseQrAlreadyExpiredAndFailedIsStillCancelled() throws Exception {
        String customer = registerCustomer();
        Product product = newProduct("Expired QR Laptop", "100.00", 5);
        String orderNumber = order(customer, product, 1, "KHQR");
        mvc.perform(post("/api/v1/payments/callback", null, Map.of("transactionRef", "TX-F", "orderNumber", orderNumber, "status", "FAILED")))
                .andExpect(status().isOk());
        age(orderNumber, 45);

        paymentService.cancelUnpaidKhqrOrders();

        mvc.perform(get("/api/v1/orders/" + orderNumber, customer)).andExpect(jsonPath("$.data.status").value("CANCELLED"));
        assertThat(productRepository.findById(product.getId()).orElseThrow().getStockQuantity()).isEqualTo(5);
    }

    @Test
    void jobBeanRunsTheCancellation() throws Exception {
        String customer = registerCustomer();
        Product product = newProduct("Job Laptop", "100.00", 5);
        String orderNumber = order(customer, product, 1, "KHQR");
        age(orderNumber, 31);

        new com.ecom.service.impl.KhqrOrderTimeoutJob(paymentService).run();

        mvc.perform(get("/api/v1/orders/" + orderNumber, customer)).andExpect(jsonPath("$.data.status").value("CANCELLED"));
        assertThat(List.of(orderNumber)).isNotEmpty();
    }
}
