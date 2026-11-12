package com.ecom.controller;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class ProfileControllerTest extends AbstractIntegrationTest {

    @Test
    void meReturnsProfileAndUpdateChangesIt() throws Exception {
        String token = registerCustomer();

        mvc.perform(get("/api/v1/users/me", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.fullName").value("Test Customer"));

        mvc.perform(put("/api/v1/users/me", token, Map.of("fullName", "New Name", "phone", "099999999")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.fullName").value("New Name"))
                .andExpect(jsonPath("$.data.phone").value("099999999"));
    }

    @Test
    void updateProfileWithBlankNameIsBadRequest() throws Exception {
        mvc.perform(put("/api/v1/users/me", registerCustomer(), Map.of("fullName", " ")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.fullName").exists());
    }

    @Test
    void changePasswordRequiresCurrentPasswordAndCreatesNotification() throws Exception {
        String email = uniqueEmail("pw");
        MvcResult reg = mvc.perform(post("/api/v1/auth/register", null, Map.of("fullName", "Dara", "email", email, "password", "Passw0rd!"))).andReturn();
        String token = read(reg).at("/data/accessToken").asText();

        mvc.perform(put("/api/v1/users/me/password", token, Map.of("currentPassword", "wrong-one", "newPassword", "NewPassw0rd!")))
                .andExpect(status().isBadRequest());
        mvc.perform(put("/api/v1/users/me/password", token, Map.of("currentPassword", "Passw0rd!", "newPassword", "short")))
                .andExpect(status().isBadRequest());
        mvc.perform(put("/api/v1/users/me/password", token, Map.of("currentPassword", "Passw0rd!", "newPassword", "NewPassw0rd!")))
                .andExpect(status().isOk());

        mvc.perform(post("/api/v1/auth/login", null, Map.of("email", email, "password", "Passw0rd!"))).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/auth/login", null, Map.of("email", email, "password", "NewPassw0rd!"))).andExpect(status().isOk());
        mvc.perform(get("/api/v1/notifications", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].type").value("ACCOUNT"))
                .andExpect(jsonPath("$.data.content[0].title").value("Password changed"));
    }

    private Map<String, Object> address(String name, boolean isDefault) {
        Map<String, Object> body = new HashMap<>();
        body.put("receiverName", name);
        body.put("phone", "012345678");
        body.put("line1", "Street 271");
        body.put("city", "Phnom Penh");
        body.put("isDefault", isDefault);
        return body;
    }

    @Test
    void addressLifecycleKeepsExactlyOneDefault() throws Exception {
        String token = registerCustomer();

        long first = read(mvc.perform(post("/api/v1/users/me/addresses", token, address("First", false)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.isDefault").value(true)).andReturn()).at("/data/id").asLong();
        long second = read(mvc.perform(post("/api/v1/users/me/addresses", token, address("Second", false)))
                .andExpect(jsonPath("$.data.isDefault").value(false)).andReturn()).at("/data/id").asLong();

        mvc.perform(patch("/api/v1/users/me/addresses/" + second + "/default", token, null))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.isDefault").value(true));
        mvc.perform(get("/api/v1/users/me/addresses", token))
                .andExpect(jsonPath("$.data[?(@.id==" + first + ")].isDefault").value(false))
                .andExpect(jsonPath("$.data[?(@.id==" + second + ")].isDefault").value(true));

        mvc.perform(put("/api/v1/users/me/addresses/" + first, token, address("Renamed", false)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.receiverName").value("Renamed"));

        mvc.perform(delete("/api/v1/users/me/addresses/" + second, token)).andExpect(status().isOk());
        mvc.perform(get("/api/v1/users/me/addresses", token))
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].isDefault").value(true));
    }

    @Test
    void invalidAddressIsBadRequest() throws Exception {
        mvc.perform(post("/api/v1/users/me/addresses", registerCustomer(), Map.of("receiverName", "")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.line1").exists());
    }

    @Test
    void otherCustomersAddressesAreNotFound() throws Exception {
        String owner = registerCustomer();
        String intruder = registerCustomer();
        long id = createAddress(owner);

        mvc.perform(put("/api/v1/users/me/addresses/" + id, intruder, address("Hacked", true))).andExpect(status().isNotFound());
        mvc.perform(delete("/api/v1/users/me/addresses/" + id, intruder)).andExpect(status().isNotFound());
        mvc.perform(patch("/api/v1/users/me/addresses/" + id + "/default", intruder, null)).andExpect(status().isNotFound());
    }
}
