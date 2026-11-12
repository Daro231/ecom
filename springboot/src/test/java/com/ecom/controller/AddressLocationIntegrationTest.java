package com.ecom.controller;

import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class AddressLocationIntegrationTest extends AbstractIntegrationTest {

    private Map<String, Object> body(Object lat, Object lng) {
        Map<String, Object> m = new HashMap<>(Map.of("receiverName", "Receiver", "phone", "012345678",
                "line1", "Street 1", "city", "Phnom Penh"));
        if (lat != null) m.put("latitude", lat);
        if (lng != null) m.put("longitude", lng);
        return m;
    }

    @Test
    void addressWithoutLocationStaysBackwardCompatible() throws Exception {
        String token = registerCustomer();
        mvc.perform(post("/api/v1/users/me/addresses", token, body(null, null)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.latitude").doesNotExist())
                .andExpect(jsonPath("$.data.longitude").doesNotExist());
    }

    @Test
    void addressLocationIsStoredReturnedAndUpdatable() throws Exception {
        String token = registerCustomer();
        long id = read(mvc.perform(post("/api/v1/users/me/addresses", token, body(11.556374, 104.928207)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.latitude").value(11.556374))
                .andExpect(jsonPath("$.data.longitude").value(104.928207)).andReturn()).at("/data/id").asLong();

        mvc.perform(get("/api/v1/users/me/addresses", token)).andExpect(jsonPath("$.data[0].latitude").value(11.556374));
        mvc.perform(put("/api/v1/users/me/addresses/" + id, token, body(-90, 180)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.latitude").value(-90.0))
                .andExpect(jsonPath("$.data.longitude").value(180.0));
        mvc.perform(put("/api/v1/users/me/addresses/" + id, token, body(null, null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.latitude").doesNotExist());
    }

    @Test
    void invalidLocationIsRejected() throws Exception {
        String token = registerCustomer();
        mvc.perform(post("/api/v1/users/me/addresses", token, body(90.1, 10)))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.errors.latitude").exists());
        mvc.perform(post("/api/v1/users/me/addresses", token, body(10, -180.5)))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.errors.longitude").exists());
        mvc.perform(post("/api/v1/users/me/addresses", token, body(10, null)))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.errors.locationComplete").exists());
        mvc.perform(post("/api/v1/users/me/addresses", token, body(null, 10)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void checkoutSnapshotsLocationAndLaterAddressEditsDoNotChangeTheOrder() throws Exception {
        String token = registerCustomer();
        var product = newProduct("Location Laptop", "100.00", 5);
        long id = read(mvc.perform(post("/api/v1/users/me/addresses", token, body(11.556374, 104.928207))).andReturn())
                .at("/data/id").asLong();
        addToCart(token, product.getId(), 1);
        String order = checkout(token, id, "STANDARD", "CASH_ON_DELIVERY", null);

        mvc.perform(put("/api/v1/users/me/addresses/" + id, token, body(1.5, 2.5))).andExpect(status().isOk());

        mvc.perform(get("/api/v1/orders/" + order, token))
                .andExpect(jsonPath("$.data.deliveryLatitude").value(11.556374))
                .andExpect(jsonPath("$.data.deliveryLongitude").value(104.928207));
        mvc.perform(get("/api/v1/admin/orders/" + order, adminToken()))
                .andExpect(jsonPath("$.data.deliveryLatitude").value(11.556374))
                .andExpect(jsonPath("$.data.deliveryLongitude").value(104.928207));
    }

    @Test
    void orderWithoutAddressLocationHasNullDeliveryCoordinates() throws Exception {
        String token = registerCustomer();
        var product = newProduct("No Location Laptop", "100.00", 5);
        addToCart(token, product.getId(), 1);
        String order = checkout(token, createAddress(token), "STANDARD", "CASH_ON_DELIVERY", null);
        mvc.perform(get("/api/v1/orders/" + order, token))
                .andExpect(jsonPath("$.data.deliveryLatitude").doesNotExist())
                .andExpect(jsonPath("$.data.deliveryLongitude").doesNotExist());
    }
}
