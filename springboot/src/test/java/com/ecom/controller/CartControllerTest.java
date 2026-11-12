package com.ecom.controller;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class CartControllerTest extends AbstractIntegrationTest {

    @Test
    void cartRequiresAuthentication() throws Exception {
        mvc.perform(get("/api/v1/cart", null)).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/cart/items", null, Map.of("productId", 1, "quantity", 1))).andExpect(status().isUnauthorized());
    }

    @Test
    void emptyCartHasZeroTotals() throws Exception {
        mvc.perform(get("/api/v1/cart", registerCustomer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(0))
                .andExpect(jsonPath("$.data.subtotal").value(0.0))
                .andExpect(jsonPath("$.data.totalItems").value(0));
    }

    @Test
    void addUpdateRemoveAndClear() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Cart Laptop", "250.00", 5);

        MvcResult added = mvc.perform(post("/api/v1/cart/items", token, Map.of("productId", product.getId(), "quantity", 2)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.items.length()").value(1))
                .andExpect(jsonPath("$.data.subtotal").value(500.0))
                .andExpect(jsonPath("$.data.totalItems").value(2)).andReturn();
        long itemId = read(added).at("/data/items/0/id").asLong();
        assertThat(itemId).isPositive();

        mvc.perform(post("/api/v1/cart/items", token, Map.of("productId", product.getId(), "quantity", 1)))
                .andExpect(jsonPath("$.data.items.length()").value(1))
                .andExpect(jsonPath("$.data.items[0].quantity").value(3));

        mvc.perform(put("/api/v1/cart/items/" + itemId, token, Map.of("quantity", 4)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.subtotal").value(1000.0));

        mvc.perform(delete("/api/v1/cart/items/" + itemId, token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(0));

        addToCart(token, product.getId(), 1);
        mvc.perform(delete("/api/v1/cart", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(0));
    }

    @Test
    void cannotAddMoreThanStock() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Scarce Laptop", "250.00", 2);

        mvc.perform(post("/api/v1/cart/items", token, Map.of("productId", product.getId(), "quantity", 3)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void invalidQuantityOrMissingProductIsRejected() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Validation Laptop", "250.00", 2);

        mvc.perform(post("/api/v1/cart/items", token, Map.of("productId", product.getId(), "quantity", 0)))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.errors.quantity").exists());
        mvc.perform(post("/api/v1/cart/items", token, Map.of("quantity", 1)))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.errors.productId").exists());
        mvc.perform(post("/api/v1/cart/items", token, Map.of("productId", 99999999, "quantity", 1)))
                .andExpect(status().isNotFound());
    }

    @Test
    void customerCannotTouchAnotherCustomersCartItem() throws Exception {
        String owner = registerCustomer();
        String intruder = registerCustomer();
        var product = newProduct("Private Laptop", "250.00", 5);
        MvcResult added = mvc.perform(post("/api/v1/cart/items", owner, Map.of("productId", product.getId(), "quantity", 1))).andReturn();
        long itemId = read(added).at("/data/items/0/id").asLong();

        mvc.perform(put("/api/v1/cart/items/" + itemId, intruder, Map.of("quantity", 2))).andExpect(status().isNotFound());
        mvc.perform(delete("/api/v1/cart/items/" + itemId, intruder)).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/cart", owner)).andExpect(jsonPath("$.data.items.length()").value(1));
    }

    @Test
    void applyCouponReturnsPreviewWithFreeShippingOverThreshold() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Premium Laptop", "600.00", 5);
        addToCart(token, product.getId(), 2);

        mvc.perform(post("/api/v1/cart/apply-coupon", token, Map.of("code", "welcome10")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.couponCode").value("WELCOME10"))
                .andExpect(jsonPath("$.data.subtotal").value(1200.0))
                .andExpect(jsonPath("$.data.discount").value(120.0))
                .andExpect(jsonPath("$.data.shippingFee").value(0.0))
                .andExpect(jsonPath("$.data.total").value(1080.0));
    }

    @Test
    void applyCouponChargesShippingBelowThreshold() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Budget Laptop", "600.00", 5);
        addToCart(token, product.getId(), 1);

        mvc.perform(post("/api/v1/cart/apply-coupon", token, Map.of("code", "SAVE50", "shippingMethod", "EXPRESS")))
                .andExpect(jsonPath("$.data.discount").value(50.0))
                .andExpect(jsonPath("$.data.shippingFee").value(15.0))
                .andExpect(jsonPath("$.data.total").value(565.0));
    }

    @Test
    void invalidCouponsAreRejected() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Coupon Laptop", "100.00", 5);
        mvc.perform(post("/api/v1/cart/apply-coupon", token, Map.of("code", "WELCOME10"))).andExpect(status().isBadRequest());
        addToCart(token, product.getId(), 1);

        mvc.perform(post("/api/v1/cart/apply-coupon", token, Map.of("code", "EXPIRED")))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.message").value(containsString("expired")));
        mvc.perform(post("/api/v1/cart/apply-coupon", token, Map.of("code", "SAVE50")))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.message").value(containsString("at least")));
        mvc.perform(post("/api/v1/cart/apply-coupon", token, Map.of("code", "NOPE")))
                .andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/cart/apply-coupon", token, Map.of("code", "")))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.errors.code").exists());
    }
}
