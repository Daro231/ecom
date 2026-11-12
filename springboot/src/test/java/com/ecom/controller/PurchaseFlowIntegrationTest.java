package com.ecom.controller;

import com.ecom.model.entity.Product;
import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** End-to-end shopping journey: register to review, asserting every step. */
class PurchaseFlowIntegrationTest extends AbstractIntegrationTest {

    @Test
    void customerBuysALaptopAndReviewsIt() throws Exception {
        Product laptop = newProduct("Flow Test Laptop", "800.00", 5);
        String adminToken = adminToken();

        // 1. register
        String email = uniqueEmail("flow");
        mvc.perform(post("/api/v1/auth/register", null, Map.of("fullName", "Flow Customer", "email", email, "password", "Passw0rd!")))
                .andExpect(status().isCreated());

        // 2. login
        MvcResult login = mvc.perform(post("/api/v1/auth/login", null, Map.of("email", email, "password", "Passw0rd!")))
                .andExpect(status().isOk()).andReturn();
        String token = read(login).at("/data/accessToken").asText();
        assertThat(token).isNotBlank();

        // 3. search "laptop"
        MvcResult search = mvc.perform(get("/api/v1/products?keyword=laptop&sort=newest&size=100", null))
                .andExpect(status().isOk()).andReturn();
        JsonNode found = null;
        for (JsonNode p : read(search).at("/data/content")) {
            if (p.at("/id").asLong() == laptop.getId()) {
                found = p;
            }
        }
        assertThat(found).as("created laptop is in search results").isNotNull();

        // 4. product detail
        mvc.perform(get("/api/v1/products/" + laptop.getId(), null))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Flow Test Laptop"))
                .andExpect(jsonPath("$.data.price").value(800.0))
                .andExpect(jsonPath("$.data.stockQuantity").value(5));

        // 5. add to cart
        mvc.perform(post("/api/v1/cart/items", token, Map.of("productId", laptop.getId(), "quantity", 2)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.subtotal").value(1600.0));

        // 6. apply WELCOME10
        mvc.perform(post("/api/v1/cart/apply-coupon", token, Map.of("code", "WELCOME10")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.discount").value(160.0))
                .andExpect(jsonPath("$.data.shippingFee").value(0.0))
                .andExpect(jsonPath("$.data.total").value(1440.0));

        // 7. checkout with KHQR
        long addressId = createAddress(token);
        MvcResult checkout = mvc.perform(post("/api/v1/orders/checkout", token, Map.of("addressId", addressId, "shippingMethod", "EXPRESS",
                        "paymentMethod", "KHQR", "couponCode", "WELCOME10")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.status").value("PENDING"))
                .andExpect(jsonPath("$.data.total").value(1440.0))
                .andExpect(jsonPath("$.data.payment.status").value("PENDING")).andReturn();
        String orderNumber = read(checkout).at("/data/orderNumber").asText();
        assertThat(productRepository.findById(laptop.getId()).orElseThrow().getStockQuantity()).isEqualTo(3);

        // 8. KHQR payload, then gateway callback marks it paid
        mvc.perform(post("/api/v1/payments/" + orderNumber + "/khqr", token, null))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.amount").value(1440.0));
        mvc.perform(post("/api/v1/payments/callback", null, Map.of("transactionRef", "BAKONG-777", "orderNumber", orderNumber, "status", "PAID")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.status").value("PAID"));

        // 9. order confirmed, stock reduced, notifications exist
        mvc.perform(get("/api/v1/orders/" + orderNumber, token))
                .andExpect(jsonPath("$.data.status").value("CONFIRMED"))
                .andExpect(jsonPath("$.data.payment.status").value("PAID"));
        assertThat(productRepository.findById(laptop.getId()).orElseThrow().getStockQuantity()).isEqualTo(3);
        mvc.perform(get("/api/v1/notifications?size=20", token))
                .andExpect(jsonPath("$.data.totalElements").value(2))
                .andExpect(jsonPath("$.data.content[*].title", containsInAnyOrder("Order placed", "Payment received")));

        // 10. admin: PROCESSING
        mvc.perform(patch("/api/v1/admin/orders/" + orderNumber + "/status", adminToken, Map.of("status", "PROCESSING")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.status").value("PROCESSING"));

        // 11. admin ships with a tracking number
        mvc.perform(patch("/api/v1/admin/orders/" + orderNumber + "/ship", adminToken, Map.of("trackingNumber", "KH-TRACK-001")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("SHIPPED"))
                .andExpect(jsonPath("$.data.shipment.status").value("IN_TRANSIT"));
        MvcResult tracking = mvc.perform(get("/api/v1/orders/" + orderNumber + "/tracking", token))
                .andExpect(jsonPath("$.data.trackingNumber").value("KH-TRACK-001")).andReturn();
        long shipmentId = read(tracking).at("/data/id").asLong();

        // a review before delivery is refused
        mvc.perform(post("/api/v1/products/" + laptop.getId() + "/reviews", token, Map.of("rating", 5, "comment", "too early")))
                .andExpect(status().isForbidden());

        // 12. delivered
        mvc.perform(patch("/api/v1/admin/shipments/" + shipmentId + "/status", adminToken, Map.of("status", "DELIVERED")))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/orders/" + orderNumber, token))
                .andExpect(jsonPath("$.data.status").value("DELIVERED"))
                .andExpect(jsonPath("$.data.shipment.status").value("DELIVERED"));
        mvc.perform(get("/api/v1/notifications?size=20", token))
                .andExpect(jsonPath("$.data.content[?(@.title==\"Order delivered\")].message", hasItem(containsString("review"))))
                .andExpect(jsonPath("$.data.content[?(@.title==\"Order shipped\")]").exists());

        // 13. five-star review updates the product rating
        mvc.perform(post("/api/v1/products/" + laptop.getId() + "/reviews", token, Map.of("rating", 5, "comment", "Excellent machine")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.rating").value(5))
                .andExpect(jsonPath("$.data.verifiedPurchase").value(true))
                .andExpect(jsonPath("$.data.userName").value("Flow Customer"));
        mvc.perform(get("/api/v1/products/" + laptop.getId(), null))
                .andExpect(jsonPath("$.data.averageRating").value(5.0))
                .andExpect(jsonPath("$.data.reviewCount").value(1));
        mvc.perform(get("/api/v1/products/" + laptop.getId() + "/reviews", null))
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].comment").value("Excellent machine"));

        // the invoice reflects the whole journey, and the coupon was counted
        mvc.perform(get("/api/v1/orders/" + orderNumber + "/invoice", token))
                .andExpect(jsonPath("$.data.total").value(1440.0))
                .andExpect(jsonPath("$.data.couponCode").value("WELCOME10"));
        int usedCount = 0;
        for (JsonNode coupon : read(mvc.perform(get("/api/v1/admin/coupons?size=50", adminToken)).andReturn()).at("/data/content")) {
            if (coupon.at("/code").asText().equals("WELCOME10")) {
                usedCount = coupon.at("/usedCount").asInt();
            }
        }
        assertThat(usedCount).isGreaterThanOrEqualTo(1);
    }
}
