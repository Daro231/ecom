package com.ecom.controller;

import com.ecom.model.entity.Product;
import com.ecom.model.enumerate.Role;
import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class PaymentShippingControllerTest extends AbstractIntegrationTest {

    private String placeOrder(String token, String payment, String price) throws Exception {
        Product product = newProduct("Pay Laptop", price, 5);
        addToCart(token, product.getId(), 1);
        return checkout(token, createAddress(token), "STANDARD", payment, null);
    }

    @Test
    void shippingMethodsArePublic() throws Exception {
        mvc.perform(get("/api/v1/shipping/methods", null))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(3))
                .andExpect(jsonPath("$.data[?(@.code==\"STANDARD\")].fee").value(5.0))
                .andExpect(jsonPath("$.data[?(@.code==\"EXPRESS\")].fee").value(15.0))
                .andExpect(jsonPath("$.data[?(@.code==\"SAME_DAY\")].fee").value(25.0))
                .andExpect(jsonPath("$.data[0].freeShippingThreshold").value(1000.0));
    }

    @Test
    void khqrPayloadIsGeneratedForKhqrOrdersOnly() throws Exception {
        String token = registerCustomer();
        String khqrOrder = placeOrder(token, "KHQR", "100.00");
        String codOrder = placeOrder(token, "CASH_ON_DELIVERY", "100.00");

        mvc.perform(post("/api/v1/payments/" + khqrOrder + "/khqr", token, null))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.orderNumber").value(khqrOrder))
                .andExpect(jsonPath("$.data.amount").value(105.0))
                .andExpect(jsonPath("$.data.currency").value("USD"))
                .andExpect(jsonPath("$.data.qrString").isNotEmpty())
                .andExpect(jsonPath("$.data.qrPayload").isNotEmpty())
                .andExpect(jsonPath("$.data.mode").value("MOCK"))
                .andExpect(jsonPath("$.data.md5", matchesPattern("[0-9a-f]{32}")))
                .andExpect(jsonPath("$.data.expiresAt").exists());
        mvc.perform(post("/api/v1/payments/" + codOrder + "/khqr", token, null)).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/payments/" + khqrOrder + "/khqr", null, null)).andExpect(status().isUnauthorized());
    }

    @Test
    void sameQrIsReturnedWhileItIsStillValid() throws Exception {
        String token = registerCustomer();
        String order = placeOrder(token, "KHQR", "100.00");

        String first = read(mvc.perform(post("/api/v1/payments/" + order + "/khqr", token, null)).andReturn()).at("/data/md5").asText();
        mvc.perform(post("/api/v1/payments/" + order + "/khqr", token, null)).andExpect(jsonPath("$.data.md5").value(first));
    }

    @Test
    void recheckIsNotAvailableInMockMode() throws Exception {
        String token = registerCustomer();
        String order = placeOrder(token, "KHQR", "100.00");

        mvc.perform(post("/api/v1/admin/payments/" + order + "/recheck", adminToken(), null)).andExpect(status().isBadRequest());
    }

    @Test
    void paymentStatusIsReported() throws Exception {
        String token = registerCustomer();
        String order = placeOrder(token, "KHQR", "100.00");

        mvc.perform(get("/api/v1/payments/" + order + "/status", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("PENDING"))
                .andExpect(jsonPath("$.data.method").value("KHQR"));
    }

    @Test
    void callbackIsPublicAndConfirmsOrderOnPaid() throws Exception {
        String token = registerCustomer();
        String order = placeOrder(token, "KHQR", "100.00");

        mvc.perform(post("/api/v1/payments/callback", null, Map.of("transactionRef", "BK-1", "orderNumber", order, "status", "PAID")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("PAID"))
                .andExpect(jsonPath("$.data.transactionRef").value("BK-1"));
        mvc.perform(get("/api/v1/orders/" + order, token)).andExpect(jsonPath("$.data.status").value("CONFIRMED"));
        mvc.perform(get("/api/v1/notifications?size=50", token))
                .andExpect(jsonPath("$.data.content[?(@.title==\"Payment received\")].message", hasItem(containsString("$105.00"))));

        // webhook retries are idempotent
        mvc.perform(post("/api/v1/payments/callback", null, Map.of("transactionRef", "BK-1", "orderNumber", order, "status", "PAID")))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/notifications/unread-count", token)).andExpect(jsonPath("$.data").value(2));
    }

    @Test
    void failedCallbackKeepsOrderPending() throws Exception {
        String token = registerCustomer();
        String order = placeOrder(token, "KHQR", "100.00");

        mvc.perform(post("/api/v1/payments/callback", null, Map.of("transactionRef", "BK-F", "orderNumber", order, "status", "FAILED")))
                .andExpect(jsonPath("$.data.status").value("FAILED"));
        mvc.perform(get("/api/v1/orders/" + order, token)).andExpect(jsonPath("$.data.status").value("PENDING"));
    }

    @Test
    void callbackValidationAndUnknownOrder() throws Exception {
        mvc.perform(post("/api/v1/payments/callback", null, Map.of("orderNumber", "X")))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.errors.transactionRef").exists());
        mvc.perform(post("/api/v1/payments/callback", null, Map.of("transactionRef", "T", "orderNumber", "ECOM-NOPE", "status", "PAID")))
                .andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/payments/callback", null, "{\"transactionRef\":\"T\",\"orderNumber\":\"X\",\"status\":\"BOGUS\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void cashOnDeliveryBecomesPaidAfterDelivery() throws Exception {
        String token = registerCustomer();
        String admin = adminToken();
        String order = placeOrder(token, "CASH_ON_DELIVERY", "100.00");

        mvc.perform(get("/api/v1/payments/" + order + "/status", token)).andExpect(jsonPath("$.data.status").value("PENDING"));
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/status", admin, Map.of("status", "CONFIRMED"))).andExpect(status().isOk());
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/status", admin, Map.of("status", "PROCESSING"))).andExpect(status().isOk());
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/ship", admin, Map.of("trackingNumber", "COD-TRK"))).andExpect(status().isOk());
        mvc.perform(get("/api/v1/payments/" + order + "/status", token)).andExpect(jsonPath("$.data.status").value("PENDING"));
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/status", admin, Map.of("status", "DELIVERED"))).andExpect(status().isOk());

        mvc.perform(get("/api/v1/payments/" + order + "/status", token))
                .andExpect(jsonPath("$.data.status").value("PAID"))
                .andExpect(jsonPath("$.data.paidAt").exists());
    }

    @Test
    void shippingLifecycleThroughAdminEndpoints() throws Exception {
        String token = registerCustomer();
        String staff = staffOrAdminToken(Role.STAFF);
        String order = placeOrder(token, "KHQR", "100.00");

        mvc.perform(patch("/api/v1/admin/orders/" + order + "/ship", staff, Map.of("trackingNumber", "TOO-EARLY")))
                .andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/ship", staff, Map.of("trackingNumber", "")))
                .andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/status", staff, Map.of("status", "DELIVERED")))
                .andExpect(status().isBadRequest());

        mvc.perform(patch("/api/v1/admin/orders/" + order + "/status", staff, Map.of("status", "CONFIRMED"))).andExpect(status().isOk());
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/status", staff, Map.of("status", "PROCESSING"))).andExpect(status().isOk());
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/ship", staff, Map.of("trackingNumber", "KH123456")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("SHIPPED"))
                .andExpect(jsonPath("$.data.shipment.trackingNumber").value("KH123456"))
                .andExpect(jsonPath("$.data.shipment.status").value("IN_TRANSIT"));
        long shipmentId = read(mvc.perform(get("/api/v1/orders/" + order + "/tracking", token))
                .andExpect(jsonPath("$.data.trackingNumber").value("KH123456")).andReturn()).at("/data/id").asLong();

        mvc.perform(patch("/api/v1/admin/shipments/" + shipmentId + "/status", staff, Map.of("status", "PREPARING"))).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/shipments/" + shipmentId + "/status", staff, Map.of("status", "OUT_FOR_DELIVERY")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.status").value("OUT_FOR_DELIVERY"));
        mvc.perform(patch("/api/v1/admin/shipments/" + shipmentId + "/status", staff, Map.of("status", "DELIVERED")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.status").value("DELIVERED")).andExpect(jsonPath("$.data.deliveredAt").exists());

        mvc.perform(get("/api/v1/orders/" + order, token)).andExpect(jsonPath("$.data.status").value("DELIVERED"));
        mvc.perform(patch("/api/v1/admin/shipments/" + shipmentId + "/status", staff, Map.of("status", "DELIVERED"))).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/shipments/99999999/status", staff, Map.of("status", "DELIVERED"))).andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/orders/" + order + "/cancel", token, Map.of("reason", "too late"))).andExpect(status().isBadRequest());
    }

    @Test
    void shipmentCannotBeMarkedOutForDeliveryBeforeShipping() throws Exception {
        String token = registerCustomer();
        String order = placeOrder(token, "KHQR", "100.00");
        long shipmentId = read(mvc.perform(get("/api/v1/orders/" + order + "/tracking", token)).andReturn()).at("/data/id").asLong();

        mvc.perform(patch("/api/v1/admin/shipments/" + shipmentId + "/status", adminToken(), Map.of("status", "OUT_FOR_DELIVERY")))
                .andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/shipments/" + shipmentId + "/status", adminToken(), Map.of("status", "DELIVERED")))
                .andExpect(status().isBadRequest());
    }

    @Test
    void staffCanManageOrdersButNotUsersOrProducts() throws Exception {
        String staff = staffOrAdminToken(Role.STAFF);
        mvc.perform(get("/api/v1/admin/orders", staff)).andExpect(status().isOk());
        mvc.perform(get("/api/v1/admin/inventory", staff)).andExpect(status().isOk());
        mvc.perform(get("/api/v1/admin/users", staff)).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/products", staff, Map.of("sku", "X"))).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/admin/reports/dashboard", staff)).andExpect(status().isForbidden());
    }
}
