package com.ecom.controller;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class OrderControllerTest extends AbstractIntegrationTest {

    @Test
    void checkoutRequiresAuthenticationAndValidBody() throws Exception {
        mvc.perform(post("/api/v1/orders/checkout", null, Map.of("addressId", 1))).andExpect(status().isUnauthorized());

        mvc.perform(post("/api/v1/orders/checkout", registerCustomer(), Map.of("couponCode", "X")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.addressId").exists())
                .andExpect(jsonPath("$.errors.shippingMethod").exists())
                .andExpect(jsonPath("$.errors.paymentMethod").exists());
    }

    @Test
    void checkoutWithEmptyCartIsBadRequest() throws Exception {
        String token = registerCustomer();
        long address = createAddress(token);

        mvc.perform(post("/api/v1/orders/checkout", token, Map.of("addressId", address, "shippingMethod", "STANDARD", "paymentMethod", "KHQR")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(containsString("empty")));
    }

    @Test
    void checkoutWithUnknownAddressIsNotFound() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Address Laptop", "100.00", 5);
        addToCart(token, product.getId(), 1);

        mvc.perform(post("/api/v1/orders/checkout", token, Map.of("addressId", 99999999, "shippingMethod", "STANDARD", "paymentMethod", "KHQR")))
                .andExpect(status().isNotFound());
    }

    @Test
    void checkoutCreatesOrderSnapshotDeductsStockAndClearsCart() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Checkout Laptop", "300.00", 5);
        long address = createAddress(token);
        addToCart(token, product.getId(), 2);

        MvcResult res = mvc.perform(post("/api/v1/orders/checkout", token,
                        Map.of("addressId", address, "shippingMethod", "EXPRESS", "paymentMethod", "CASH_ON_DELIVERY", "note", "call me")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.orderNumber", matchesPattern("ECOM-\\d{8}-\\d{4}")))
                .andExpect(jsonPath("$.data.status").value("PENDING"))
                .andExpect(jsonPath("$.data.subtotal").value(600.0))
                .andExpect(jsonPath("$.data.shippingFee").value(15.0))
                .andExpect(jsonPath("$.data.total").value(615.0))
                .andExpect(jsonPath("$.data.items[0].productName").value("Checkout Laptop"))
                .andExpect(jsonPath("$.data.items[0].unitPrice").value(300.0))
                .andExpect(jsonPath("$.data.payment.status").value("PENDING"))
                .andExpect(jsonPath("$.data.shipment.status").value("PREPARING"))
                .andExpect(jsonPath("$.data.receiverName").value("Receiver")).andReturn();

        assertThat(productRepository.findById(product.getId()).orElseThrow().getStockQuantity()).isEqualTo(3);
        mvc.perform(get("/api/v1/cart", token)).andExpect(jsonPath("$.data.items.length()").value(0));

        // price change afterwards must not change the order snapshot
        var changed = productRepository.findById(product.getId()).orElseThrow();
        changed.setPrice(new java.math.BigDecimal("999.00"));
        productRepository.save(changed);
        String orderNumber = read(res).at("/data/orderNumber").asText();
        mvc.perform(get("/api/v1/orders/" + orderNumber, token))
                .andExpect(jsonPath("$.data.items[0].unitPrice").value(300.0))
                .andExpect(jsonPath("$.data.total").value(615.0));
    }

    @Test
    void checkoutWithCouponAndFreeShipping() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Coupon Checkout Laptop", "700.00", 5);
        long address = createAddress(token);
        addToCart(token, product.getId(), 2);

        mvc.perform(post("/api/v1/orders/checkout", token,
                        Map.of("addressId", address, "shippingMethod", "STANDARD", "paymentMethod", "KHQR", "couponCode", "WELCOME10")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.subtotal").value(1400.0))
                .andExpect(jsonPath("$.data.discountAmount").value(140.0))
                .andExpect(jsonPath("$.data.shippingFee").value(0.0))
                .andExpect(jsonPath("$.data.total").value(1260.0))
                .andExpect(jsonPath("$.data.couponCode").value("WELCOME10"));
    }

    @Test
    void checkoutWithExpiredCouponIsRejectedAndKeepsStockAndCart() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Expired Coupon Laptop", "700.00", 5);
        long address = createAddress(token);
        addToCart(token, product.getId(), 1);

        mvc.perform(post("/api/v1/orders/checkout", token,
                        Map.of("addressId", address, "shippingMethod", "STANDARD", "paymentMethod", "KHQR", "couponCode", "EXPIRED")))
                .andExpect(status().isBadRequest());

        assertThat(productRepository.findById(product.getId()).orElseThrow().getStockQuantity()).isEqualTo(5);
        mvc.perform(get("/api/v1/cart", token)).andExpect(jsonPath("$.data.items.length()").value(1));
    }

    @Test
    void checkoutWithInsufficientStockIsConflict() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Vanishing Laptop", "100.00", 3);
        long address = createAddress(token);
        addToCart(token, product.getId(), 3);
        var reduced = productRepository.findById(product.getId()).orElseThrow();
        reduced.setStockQuantity(1);
        productRepository.save(reduced);

        mvc.perform(post("/api/v1/orders/checkout", token, Map.of("addressId", address, "shippingMethod", "STANDARD", "paymentMethod", "KHQR")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value(containsString("Insufficient stock")));
        assertThat(productRepository.findById(product.getId()).orElseThrow().getStockQuantity()).isEqualTo(1);
    }

    @Test
    void customersCannotSeeEachOthersOrders() throws Exception {
        String a = registerCustomer();
        String b = registerCustomer();
        var product = newProduct("Owner Laptop", "100.00", 5);
        addToCart(a, product.getId(), 1);
        String orderNumber = checkout(a, createAddress(a), "STANDARD", "KHQR", null);

        mvc.perform(get("/api/v1/orders/" + orderNumber, a)).andExpect(status().isOk());
        mvc.perform(get("/api/v1/orders/" + orderNumber, b)).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/orders/" + orderNumber + "/invoice", b)).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/orders/" + orderNumber + "/tracking", b)).andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/orders/" + orderNumber + "/cancel", b, Map.of("reason", "sabotage"))).andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/payments/" + orderNumber + "/khqr", b, null)).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/payments/" + orderNumber + "/status", b)).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/orders", b)).andExpect(jsonPath("$.data.totalElements").value(0));
        mvc.perform(get("/api/v1/orders", a)).andExpect(jsonPath("$.data.totalElements").value(1));
    }

    @Test
    void cancelRestoresStockAndRejectsSecondCancel() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Cancel Laptop", "100.00", 5);
        addToCart(token, product.getId(), 2);
        String orderNumber = checkout(token, createAddress(token), "STANDARD", "KHQR", null);
        assertThat(productRepository.findById(product.getId()).orElseThrow().getStockQuantity()).isEqualTo(3);

        mvc.perform(post("/api/v1/orders/" + orderNumber + "/cancel", token, Map.of("reason", "")))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.errors.reason").exists());

        mvc.perform(post("/api/v1/orders/" + orderNumber + "/cancel", token, Map.of("reason", "changed my mind")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("CANCELLED"))
                .andExpect(jsonPath("$.data.cancelledReason").value("changed my mind"));
        assertThat(productRepository.findById(product.getId()).orElseThrow().getStockQuantity()).isEqualTo(5);

        mvc.perform(post("/api/v1/orders/" + orderNumber + "/cancel", token, Map.of("reason", "again")))
                .andExpect(status().isBadRequest());
    }

    @Test
    void paidOrderIsRefundedWhenCancelled() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Refund Laptop", "100.00", 5);
        addToCart(token, product.getId(), 1);
        String orderNumber = checkout(token, createAddress(token), "STANDARD", "KHQR", null);
        mvc.perform(post("/api/v1/payments/callback", null, Map.of("transactionRef", "TX-R", "orderNumber", orderNumber, "status", "PAID")))
                .andExpect(status().isOk());

        mvc.perform(post("/api/v1/orders/" + orderNumber + "/cancel", token, Map.of("reason", "refund please")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.payment.status").value("REFUNDED"));
    }

    @Test
    void invoiceAndTrackingAndListing() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Invoice Laptop", "100.00", 5);
        addToCart(token, product.getId(), 2);
        String orderNumber = checkout(token, createAddress(token), "STANDARD", "BANK_TRANSFER", null);

        mvc.perform(get("/api/v1/orders/" + orderNumber + "/invoice", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.invoiceNumber").value("INV-" + orderNumber))
                .andExpect(jsonPath("$.data.items.length()").value(1))
                .andExpect(jsonPath("$.data.subtotal").value(200.0))
                .andExpect(jsonPath("$.data.total").value(205.0))
                .andExpect(jsonPath("$.data.payment.method").value("BANK_TRANSFER"));
        mvc.perform(get("/api/v1/orders/" + orderNumber + "/tracking", token))
                .andExpect(jsonPath("$.data.status").value("PREPARING"))
                .andExpect(jsonPath("$.data.method").value("STANDARD"));
        mvc.perform(get("/api/v1/orders?page=0&size=5", token))
                .andExpect(jsonPath("$.data.content[0].orderNumber").value(orderNumber))
                .andExpect(jsonPath("$.data.content[0].items.length()").value(1));
        mvc.perform(get("/api/v1/orders/ECOM-00000000-0000", token)).andExpect(status().isNotFound());
    }

    @Test
    void customerCannotAccessAdminOrderEndpoints() throws Exception {
        String token = registerCustomer();
        mvc.perform(get("/api/v1/admin/orders", token)).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/admin/orders", null)).andExpect(status().isUnauthorized());
    }
}
