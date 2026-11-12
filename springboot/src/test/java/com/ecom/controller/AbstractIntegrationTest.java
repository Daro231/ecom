package com.ecom.controller;

import com.ecom.model.entity.Product;
import com.ecom.model.entity.User;
import com.ecom.model.enumerate.Role;
import com.ecom.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public abstract class AbstractIntegrationTest {
    /**
     * One PostgreSQL 16 container shared by every integration test class (same engine as production).
     * Started once per JVM and never stopped by a test lifecycle, because Spring caches the application context
     * across test classes; the Testcontainers Ryuk sidecar removes it when the JVM exits.
     */
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    static {
        POSTGRES.start();
    }

    @Autowired
    protected MockMvc mvc;
    @Autowired
    protected ObjectMapper mapper;
    @Autowired
    protected UserRepository userRepository;
    @Autowired
    protected ProductRepository productRepository;
    @Autowired
    protected CategoryRepository categoryRepository;
    @Autowired
    protected BrandRepository brandRepository;
    @Autowired
    protected PasswordEncoder passwordEncoder;

    protected String uniqueEmail(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8) + "@test.com";
    }

    protected String json(Object body) throws Exception {
        return mapper.writeValueAsString(body);
    }

    protected JsonNode read(MvcResult result) throws Exception {
        return mapper.readTree(result.getResponse().getContentAsString());
    }

    protected MockHttpServletRequestBuilder with(MockHttpServletRequestBuilder builder, String token, Object body) throws Exception {
        if (token != null) {
            builder.header("Authorization", "Bearer " + token);
        }
        if (body != null) {
            builder.contentType(MediaType.APPLICATION_JSON).content(body instanceof String s ? s : json(body));
        }
        return builder;
    }

    protected MockHttpServletRequestBuilder get(String url, String token) throws Exception {
        return with(MockMvcRequestBuilders.get(url), token, null);
    }

    protected MockHttpServletRequestBuilder post(String url, String token, Object body) throws Exception {
        return with(MockMvcRequestBuilders.post(url), token, body);
    }

    protected MockHttpServletRequestBuilder put(String url, String token, Object body) throws Exception {
        return with(MockMvcRequestBuilders.put(url), token, body);
    }

    protected MockHttpServletRequestBuilder patch(String url, String token, Object body) throws Exception {
        return with(MockMvcRequestBuilders.patch(url), token, body);
    }

    protected MockHttpServletRequestBuilder delete(String url, String token) throws Exception {
        return with(MockMvcRequestBuilders.delete(url), token, null);
    }

    /** Registers a new customer and returns the JWT. */
    protected String registerCustomer() throws Exception {
        Map<String, String> body = Map.of("fullName", "Test Customer", "email", uniqueEmail("cust"), "password", "Passw0rd!");
        MvcResult res = mvc.perform(post("/api/v1/auth/register", null, body)).andReturn();
        return read(res).at("/data/accessToken").asText();
    }

    protected String staffOrAdminToken(Role role) throws Exception {
        String email = uniqueEmail(role.name().toLowerCase());
        userRepository.save(User.builder().fullName(role.name()).email(email).password(passwordEncoder.encode("Passw0rd!"))
                .role(role).enabled(true).build());
        MvcResult res = mvc.perform(post("/api/v1/auth/login", null, Map.of("email", email, "password", "Passw0rd!"))).andReturn();
        return read(res).at("/data/accessToken").asText();
    }

    protected String adminToken() throws Exception {
        return staffOrAdminToken(Role.ADMIN);
    }

    protected Product newProduct(String name, String price, int stock) {
        return productRepository.save(Product.builder().sku("T-" + UUID.randomUUID().toString().substring(0, 10))
                .name(name).slug(name.toLowerCase().replace(' ', '-') + "-" + UUID.randomUUID().toString().substring(0, 6))
                .description("Test laptop product").price(new BigDecimal(price))
                .category(categoryRepository.findAll().get(0)).brand(brandRepository.findAll().get(0))
                .ram(16).stockQuantity(stock).lowStockThreshold(1).build());
    }

    protected long createAddress(String token) throws Exception {
        Map<String, Object> body = Map.of("receiverName", "Receiver", "phone", "012345678", "line1", "Street 1", "city", "Phnom Penh", "isDefault", true);
        return read(mvc.perform(post("/api/v1/users/me/addresses", token, body)).andReturn()).at("/data/id").asLong();
    }

    protected void addToCart(String token, long productId, int qty) throws Exception {
        mvc.perform(post("/api/v1/cart/items", token, Map.of("productId", productId, "quantity", qty)));
    }

    /** Checks out the current cart and returns the order number. */
    protected String checkout(String token, long addressId, String shipping, String payment, String coupon) throws Exception {
        Map<String, Object> body = new java.util.HashMap<>(Map.of("addressId", addressId, "shippingMethod", shipping, "paymentMethod", payment));
        if (coupon != null) {
            body.put("couponCode", coupon);
        }
        MvcResult res = mvc.perform(post("/api/v1/orders/checkout", token, body)).andReturn();
        return read(res).at("/data/orderNumber").asText();
    }
}
