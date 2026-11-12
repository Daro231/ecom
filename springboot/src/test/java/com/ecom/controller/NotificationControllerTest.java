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

class NotificationControllerTest extends AbstractIntegrationTest {

    @Test
    void notificationsRequireAuthentication() throws Exception {
        mvc.perform(get("/api/v1/notifications", null)).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/notifications/unread-count", null)).andExpect(status().isUnauthorized());
    }

    @Test
    void orderCreatesNotificationThatCanBeReadAndCounted() throws Exception {
        String token = registerCustomer();
        Product product = newProduct("Notify Laptop", "100.00", 5);
        addToCart(token, product.getId(), 1);
        String order = checkout(token, createAddress(token), "STANDARD", "KHQR", null);

        mvc.perform(get("/api/v1/notifications/unread-count", token)).andExpect(jsonPath("$.data").value(1));
        MvcResult list = mvc.perform(get("/api/v1/notifications", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].title").value("Order placed"))
                .andExpect(jsonPath("$.data.content[0].message").value(containsString(order)))
                .andExpect(jsonPath("$.data.content[0].read").value(false)).andReturn();
        long id = read(list).at("/data/content/0/id").asLong();

        mvc.perform(patch("/api/v1/notifications/" + id + "/read", token, null))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.read").value(true));
        mvc.perform(get("/api/v1/notifications/unread-count", token)).andExpect(jsonPath("$.data").value(0));
    }

    @Test
    void readAllMarksEverythingRead() throws Exception {
        String token = registerCustomer();
        mvc.perform(put("/api/v1/users/me/password", token, Map.of("currentPassword", "Passw0rd!", "newPassword", "NewPassw0rd!"))).andExpect(status().isOk());
        mvc.perform(put("/api/v1/users/me/password", token, Map.of("currentPassword", "NewPassw0rd!", "newPassword", "Passw0rd!2"))).andExpect(status().isOk());
        mvc.perform(get("/api/v1/notifications/unread-count", token)).andExpect(jsonPath("$.data").value(2));

        mvc.perform(patch("/api/v1/notifications/read-all", token, null)).andExpect(status().isOk()).andExpect(jsonPath("$.data").value(2));
        mvc.perform(get("/api/v1/notifications/unread-count", token)).andExpect(jsonPath("$.data").value(0));
    }

    @Test
    void cannotReadSomeoneElsesNotification() throws Exception {
        String owner = registerCustomer();
        mvc.perform(put("/api/v1/users/me/password", owner, Map.of("currentPassword", "Passw0rd!", "newPassword", "NewPassw0rd!")));
        long id = read(mvc.perform(get("/api/v1/notifications", owner)).andReturn()).at("/data/content/0/id").asLong();

        mvc.perform(patch("/api/v1/notifications/" + id + "/read", registerCustomer(), null)).andExpect(status().isNotFound());
        mvc.perform(patch("/api/v1/notifications/99999999/read", owner, null)).andExpect(status().isNotFound());
    }
}
