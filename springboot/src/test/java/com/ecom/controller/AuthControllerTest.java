package com.ecom.controller;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class AuthControllerTest extends AbstractIntegrationTest {

    @Test
    void registerReturnsTokenAndCustomerRole() throws Exception {
        Map<String, String> body = Map.of("fullName", "Dara", "email", uniqueEmail("reg"), "password", "Passw0rd!", "phone", "012345678");

        mvc.perform(post("/api/v1/auth/register", null, body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.timestamp").exists())
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.data.user.role").value("CUSTOMER"))
                .andExpect(jsonPath("$.data.user.password").doesNotExist());
    }

    @Test
    void registerWithInvalidDataReturnsFieldErrors() throws Exception {
        Map<String, String> body = Map.of("fullName", "", "email", "not-an-email", "password", "short");

        mvc.perform(post("/api/v1/auth/register", null, body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errors.fullName").exists())
                .andExpect(jsonPath("$.errors.email").exists())
                .andExpect(jsonPath("$.errors.password").exists());
    }

    @Test
    void registerDuplicateEmailIsConflict() throws Exception {
        String email = uniqueEmail("dup");
        Map<String, String> body = Map.of("fullName", "Dara", "email", email, "password", "Passw0rd!");
        mvc.perform(post("/api/v1/auth/register", null, body)).andExpect(status().isCreated());

        mvc.perform(post("/api/v1/auth/register", null, body))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void loginWithCorrectCredentialsReturnsToken() throws Exception {
        String email = uniqueEmail("login");
        mvc.perform(post("/api/v1/auth/register", null, Map.of("fullName", "Dara", "email", email, "password", "Passw0rd!")));

        mvc.perform(post("/api/v1/auth/login", null, Map.of("email", email, "password", "Passw0rd!")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.expiresInSeconds").value(86400));
    }

    @Test
    void loginWithWrongPasswordIsUnauthorized() throws Exception {
        String email = uniqueEmail("wrong");
        mvc.perform(post("/api/v1/auth/register", null, Map.of("fullName", "Dara", "email", email, "password", "Passw0rd!")));

        mvc.perform(post("/api/v1/auth/login", null, Map.of("email", email, "password", "nope-nope")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void loginWithMissingFieldsIsBadRequest() throws Exception {
        mvc.perform(post("/api/v1/auth/login", null, Map.of("email", "")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.password").exists());
    }

    @Test
    void protectedEndpointWithoutTokenIsUnauthorized() throws Exception {
        mvc.perform(get("/api/v1/users/me", null))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void garbageTokenIsUnauthorized() throws Exception {
        mvc.perform(get("/api/v1/users/me", "not.a.jwt")).andExpect(status().isUnauthorized());
    }

    @Test
    void malformedJsonIsBadRequest() throws Exception {
        mvc.perform(post("/api/v1/auth/login", null, "{not json")).andExpect(status().isBadRequest());
    }

    @Test
    void unknownRouteForAuthenticatedUserIsNotFound() throws Exception {
        mvc.perform(get("/api/v1/does-not-exist", registerCustomer()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void disabledAccountCannotLoginOrUseExistingToken() throws Exception {
        String admin = adminToken();
        String email = uniqueEmail("disabled");
        MvcResult reg = mvc.perform(post("/api/v1/auth/register", null, Map.of("fullName", "Dara", "email", email, "password", "Passw0rd!"))).andReturn();
        JsonNode data = read(reg).at("/data");
        String token = data.at("/accessToken").asText();
        long id = data.at("/user/id").asLong();

        mvc.perform(patch("/api/v1/admin/users/" + id + "/enabled", admin, Map.of("enabled", false))).andExpect(status().isOk());

        mvc.perform(post("/api/v1/auth/login", null, Map.of("email", email, "password", "Passw0rd!"))).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/users/me", token)).andExpect(status().isUnauthorized());
    }
}
