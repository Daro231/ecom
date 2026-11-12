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

class AdminControllerTest extends AbstractIntegrationTest {

    @Test
    void adminEndpointsRejectAnonymousAndCustomers() throws Exception {
        String customer = registerCustomer();
        for (String url : List.of("/api/v1/admin/users", "/api/v1/admin/products", "/api/v1/admin/coupons", "/api/v1/admin/payments",
                "/api/v1/admin/reviews", "/api/v1/admin/inventory", "/api/v1/admin/orders", "/api/v1/admin/reports/dashboard")) {
            mvc.perform(get(url, null)).andExpect(status().isUnauthorized());
            mvc.perform(get(url, customer)).andExpect(status().isForbidden()).andExpect(jsonPath("$.success").value(false));
        }
    }

    // ---------- users ----------
    @Test
    void adminManagesUsers() throws Exception {
        String admin = adminToken();
        String email = uniqueEmail("managed");
        MvcResult reg = mvc.perform(post("/api/v1/auth/register", null, Map.of("fullName", "Managed Person", "email", email, "password", "Passw0rd!"))).andReturn();
        long id = read(reg).at("/data/user/id").asLong();

        mvc.perform(get("/api/v1/admin/users?keyword=managed person", admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].email").value(email));
        mvc.perform(patch("/api/v1/admin/users/" + id + "/role", admin, Map.of("role", "STAFF")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.role").value("STAFF"));
        mvc.perform(patch("/api/v1/admin/users/" + id + "/role", admin, Map.of("role", "SUPERUSER"))).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/users/" + id + "/enabled", admin, Map.of())).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/users/99999999/role", admin, Map.of("role", "STAFF"))).andExpect(status().isNotFound());
    }

    @Test
    void adminCannotChangeOwnRoleOrDisableSelf() throws Exception {
        String email = uniqueEmail("self");
        long id = userRepository.save(com.ecom.model.entity.User.builder().fullName("Self").email(email)
                .password(passwordEncoder.encode("Passw0rd!")).role(Role.ADMIN).enabled(true).build()).getId();
        String token = read(mvc.perform(post("/api/v1/auth/login", null, Map.of("email", email, "password", "Passw0rd!"))).andReturn()).at("/data/accessToken").asText();

        mvc.perform(patch("/api/v1/admin/users/" + id + "/role", token, Map.of("role", "CUSTOMER"))).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/users/" + id + "/enabled", token, Map.of("enabled", false))).andExpect(status().isBadRequest());
    }

    // ---------- products ----------
    private Map<String, Object> productBody(String sku, String price, int stock) {
        long category = categoryRepository.findAll().get(0).getId();
        long brand = brandRepository.findAll().get(0).getId();
        Map<String, Object> body = new HashMap<>();
        body.put("sku", sku);
        body.put("name", "Admin Created Laptop " + sku);
        body.put("description", "Created in a test");
        body.put("price", price);
        body.put("categoryId", category);
        body.put("brandId", brand);
        body.put("cpu", "Intel Core i9");
        body.put("ram", 32);
        body.put("stockQuantity", stock);
        body.put("lowStockThreshold", 2);
        body.put("imageUrls", List.of("/uploads/a.png", "/uploads/b.png"));
        return body;
    }

    @Test
    void adminProductCrud() throws Exception {
        String admin = adminToken();
        String sku = "ADM-" + System.nanoTime();

        MvcResult created = mvc.perform(post("/api/v1/admin/products", admin, productBody(sku, "1234.50", 7)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.sku").value(sku))
                .andExpect(jsonPath("$.data.slug").value(startsWith("admin-created-laptop")))
                .andExpect(jsonPath("$.data.stockQuantity").value(7))
                .andExpect(jsonPath("$.data.images.length()").value(2)).andReturn();
        long id = read(created).at("/data/id").asLong();

        mvc.perform(get("/api/v1/admin/inventory/" + id + "/logs", admin))
                .andExpect(jsonPath("$.data.content[0].reason").value("RESTOCK"))
                .andExpect(jsonPath("$.data.content[0].changeQuantity").value(7));

        Map<String, Object> update = productBody(sku, "1000.00", 10);
        update.put("name", "Renamed Laptop " + sku);
        update.put("imageUrls", List.of("/uploads/only.png"));
        mvc.perform(put("/api/v1/admin/products/" + id, admin, update))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Renamed Laptop " + sku))
                .andExpect(jsonPath("$.data.price").value(1000.0))
                .andExpect(jsonPath("$.data.stockQuantity").value(10))
                .andExpect(jsonPath("$.data.images.length()").value(1));
        mvc.perform(get("/api/v1/admin/inventory/" + id + "/logs", admin))
                .andExpect(jsonPath("$.data.content[0].reason").value("ADJUST"))
                .andExpect(jsonPath("$.data.content[0].changeQuantity").value(3));

        mvc.perform(patch("/api/v1/admin/products/" + id + "/active?value=false", admin, null))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.active").value(false));
        mvc.perform(get("/api/v1/products/" + id, null)).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/admin/products/" + id, admin)).andExpect(status().isOk());
        mvc.perform(get("/api/v1/admin/products?keyword=" + sku, admin)).andExpect(jsonPath("$.data.totalElements").value(1));

        mvc.perform(delete("/api/v1/admin/products/" + id, admin)).andExpect(status().isOk());
        mvc.perform(get("/api/v1/admin/products/" + id, admin)).andExpect(status().isNotFound());
    }

    @Test
    void productValidationDuplicatesAndReferences() throws Exception {
        String admin = adminToken();
        String sku = "DUP-" + System.nanoTime();
        mvc.perform(post("/api/v1/admin/products", admin, productBody(sku, "10.00", 1))).andExpect(status().isCreated());

        mvc.perform(post("/api/v1/admin/products", admin, productBody(sku, "10.00", 1))).andExpect(status().isConflict());
        mvc.perform(post("/api/v1/admin/products", admin, productBody("NEG-" + System.nanoTime(), "-5.00", 1)))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.errors.price").exists());
        mvc.perform(post("/api/v1/admin/products", admin, productBody("NEG2-" + System.nanoTime(), "5.00", -1)))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.errors.stockQuantity").exists());
        Map<String, Object> badCategory = productBody("BC-" + System.nanoTime(), "5.00", 1);
        badCategory.put("categoryId", 999999);
        mvc.perform(post("/api/v1/admin/products", admin, badCategory)).andExpect(status().isBadRequest());
        mvc.perform(put("/api/v1/admin/products/99999999", admin, productBody("NF-" + System.nanoTime(), "5.00", 1))).andExpect(status().isNotFound());
        mvc.perform(delete("/api/v1/admin/products/99999999", admin)).andExpect(status().isNotFound());
    }

    @Test
    void orderedProductsCannotBeDeletedButCanBeDeactivated() throws Exception {
        String admin = adminToken();
        String customer = registerCustomer();
        Product product = newProduct("Ordered Laptop", "100.00", 5);
        addToCart(customer, product.getId(), 1);
        checkout(customer, createAddress(customer), "STANDARD", "KHQR", null);

        mvc.perform(delete("/api/v1/admin/products/" + product.getId(), admin)).andExpect(status().isConflict());
        mvc.perform(patch("/api/v1/admin/products/" + product.getId() + "/active?value=false", admin, null)).andExpect(status().isOk());
    }

    @Test
    void deletingProductRemovesItFromCarts() throws Exception {
        String admin = adminToken();
        String customer = registerCustomer();
        Product product = newProduct("Unordered Laptop", "100.00", 5);
        addToCart(customer, product.getId(), 1);

        mvc.perform(delete("/api/v1/admin/products/" + product.getId(), admin)).andExpect(status().isOk());
        mvc.perform(get("/api/v1/cart", customer)).andExpect(jsonPath("$.data.items.length()").value(0));
    }

    // ---------- categories & brands ----------
    @Test
    void adminCategoryAndBrandCrud() throws Exception {
        String admin = adminToken();
        String name = "Cat" + System.nanoTime();

        long catId = read(mvc.perform(post("/api/v1/admin/categories", admin, Map.of("name", name, "description", "d")))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.data.slug").value(name.toLowerCase())).andReturn()).at("/data/id").asLong();
        mvc.perform(post("/api/v1/admin/categories", admin, Map.of("name", name.toUpperCase()))).andExpect(status().isConflict());
        mvc.perform(post("/api/v1/admin/categories", admin, Map.of("name", ""))).andExpect(status().isBadRequest());
        mvc.perform(put("/api/v1/admin/categories/" + catId, admin, Map.of("name", name + "x")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.name").value(name + "x"));
        mvc.perform(put("/api/v1/admin/categories/" + catId, admin, Map.of("name", "Laptop"))).andExpect(status().isConflict());
        mvc.perform(delete("/api/v1/admin/categories/" + catId, admin)).andExpect(status().isOk());
        mvc.perform(delete("/api/v1/admin/categories/" + catId, admin)).andExpect(status().isNotFound());

        String brand = "Brand" + System.nanoTime();
        long brandId = read(mvc.perform(post("/api/v1/admin/brands", admin, Map.of("name", brand)))
                .andExpect(status().isCreated()).andReturn()).at("/data/id").asLong();
        mvc.perform(post("/api/v1/admin/brands", admin, Map.of("name", brand))).andExpect(status().isConflict());
        mvc.perform(put("/api/v1/admin/brands/" + brandId, admin, Map.of("name", brand + "x"))).andExpect(status().isOk());
        mvc.perform(put("/api/v1/admin/brands/" + brandId, admin, Map.of("name", "Dell"))).andExpect(status().isConflict());
        mvc.perform(delete("/api/v1/admin/brands/" + brandId, admin)).andExpect(status().isOk());
        mvc.perform(delete("/api/v1/admin/brands/" + brandId, admin)).andExpect(status().isNotFound());
    }

    @Test
    void categoryAndBrandWithProductsCannotBeDeleted() throws Exception {
        String admin = adminToken();
        mvc.perform(delete("/api/v1/admin/categories/" + categoryRepository.findAll().get(0).getId(), admin)).andExpect(status().isConflict());
        mvc.perform(delete("/api/v1/admin/brands/" + brandRepository.findAll().get(0).getId(), admin)).andExpect(status().isConflict());
    }

    // ---------- coupons ----------
    @Test
    void adminCouponCrud() throws Exception {
        String admin = adminToken();
        String code = "T" + System.nanoTime();
        Map<String, Object> body = new HashMap<>();
        body.put("code", code.toLowerCase());
        body.put("discountType", "PERCENT");
        body.put("value", 15);
        body.put("minOrderAmount", 100);
        body.put("maxUses", 2);

        long id = read(mvc.perform(post("/api/v1/admin/coupons", admin, body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.code").value(code))
                .andExpect(jsonPath("$.data.usedCount").value(0))
                .andExpect(jsonPath("$.data.active").value(true)).andReturn()).at("/data/id").asLong();
        mvc.perform(post("/api/v1/admin/coupons", admin, body)).andExpect(status().isConflict());

        body.put("discountType", "FIXED");
        body.put("value", 25);
        mvc.perform(put("/api/v1/admin/coupons/" + id, admin, body))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.discountType").value("FIXED"));
        mvc.perform(get("/api/v1/admin/coupons", admin)).andExpect(jsonPath("$.data.totalElements", greaterThanOrEqualTo(4)));

        body.put("value", 0);
        mvc.perform(put("/api/v1/admin/coupons/" + id, admin, body)).andExpect(status().isBadRequest());
        mvc.perform(delete("/api/v1/admin/coupons/" + id, admin)).andExpect(status().isOk());
        mvc.perform(delete("/api/v1/admin/coupons/" + id, admin)).andExpect(status().isNotFound());
    }

    @Test
    void couponStopsWorkingAfterMaxUses() throws Exception {
        String admin = adminToken();
        String code = "ONCE" + System.nanoTime();
        mvc.perform(post("/api/v1/admin/coupons", admin, Map.of("code", code, "discountType", "FIXED", "value", 5, "maxUses", 1)));
        Product product = newProduct("Max Use Laptop", "100.00", 10);

        String first = registerCustomer();
        addToCart(first, product.getId(), 1);
        mvc.perform(post("/api/v1/orders/checkout", first, Map.of("addressId", createAddress(first), "shippingMethod", "STANDARD",
                "paymentMethod", "KHQR", "couponCode", code))).andExpect(status().isCreated());

        String second = registerCustomer();
        addToCart(second, product.getId(), 1);
        mvc.perform(post("/api/v1/orders/checkout", second, Map.of("addressId", createAddress(second), "shippingMethod", "STANDARD",
                "paymentMethod", "KHQR", "couponCode", code)))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.message").value(containsString("maximum")));
    }

    // ---------- inventory ----------
    @Test
    void inventoryRestockAdjustAndLogs() throws Exception {
        String staff = staffOrAdminToken(Role.STAFF);
        Product product = newProduct("Inventory Laptop", "100.00", 4);
        long id = product.getId();

        mvc.perform(post("/api/v1/admin/inventory/" + id + "/restock", staff, Map.of("quantity", 6, "note", "PO-1")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.stockQuantity").value(10));
        mvc.perform(post("/api/v1/admin/inventory/" + id + "/adjust", staff, Map.of("delta", -3, "note", "damaged")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.stockQuantity").value(7));
        mvc.perform(post("/api/v1/admin/inventory/" + id + "/adjust", staff, Map.of("delta", -50)))
                .andExpect(status().isConflict());
        mvc.perform(post("/api/v1/admin/inventory/" + id + "/adjust", staff, Map.of("delta", 0))).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/admin/inventory/" + id + "/restock", staff, Map.of("quantity", 0))).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/admin/inventory/99999999/restock", staff, Map.of("quantity", 1))).andExpect(status().isNotFound());

        mvc.perform(get("/api/v1/admin/inventory/" + id + "/logs", staff))
                .andExpect(jsonPath("$.data.content.length()").value(2))
                .andExpect(jsonPath("$.data.content[0].reason").value("ADJUST"))
                .andExpect(jsonPath("$.data.content[0].stockAfter").value(7))
                .andExpect(jsonPath("$.data.content[1].reason").value("RESTOCK"));
        mvc.perform(get("/api/v1/admin/inventory?keyword=Inventory Laptop", staff)).andExpect(jsonPath("$.data.content[0].sku").value(product.getSku()));
        mvc.perform(get("/api/v1/admin/inventory/99999999/logs", staff)).andExpect(status().isNotFound());
    }

    @Test
    void lowStockListContainsSeededAndFlaggedProducts() throws Exception {
        String admin = adminToken();
        mvc.perform(get("/api/v1/admin/inventory/low-stock", admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.sku==\"CMP-ASUS-B650A\")].lowStock").value(true))
                .andExpect(jsonPath("$.data[?(@.sku==\"LAP-ASUS-VB15\")]").exists());
    }

    @Test
    void orderThatDepletesStockAlertsAdmins() throws Exception {
        String admin = adminToken();
        long before = read(mvc.perform(get("/api/v1/notifications/unread-count", admin)).andReturn()).at("/data").asLong();
        Product product = newProduct("Alert Laptop", "100.00", 2);
        String customer = registerCustomer();
        addToCart(customer, product.getId(), 1);
        checkout(customer, createAddress(customer), "STANDARD", "KHQR", null);

        mvc.perform(get("/api/v1/notifications/unread-count", admin)).andExpect(jsonPath("$.data").value(before + 1));
        mvc.perform(get("/api/v1/notifications", admin))
                .andExpect(jsonPath("$.data.content[?(@.title==\"Low stock: Alert Laptop\")]").exists());
    }

    // ---------- reviews ----------
    @Test
    void adminModeratesReviews() throws Exception {
        String admin = adminToken();
        Product product = newProduct("Reviewed Laptop", "100.00", 5);
        String customer = registerCustomer();
        addToCart(customer, product.getId(), 1);
        String order = checkout(customer, createAddress(customer), "STANDARD", "CASH_ON_DELIVERY", null);
        deliver(admin, order);

        long reviewId = read(mvc.perform(post("/api/v1/products/" + product.getId() + "/reviews", customer, Map.of("rating", 4, "comment", "good")))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.data.verifiedPurchase").value(true)).andReturn()).at("/data/id").asLong();
        mvc.perform(get("/api/v1/products/" + product.getId(), null)).andExpect(jsonPath("$.data.averageRating").value(4.0)).andExpect(jsonPath("$.data.reviewCount").value(1));

        mvc.perform(get("/api/v1/admin/reviews", admin)).andExpect(jsonPath("$.data.content[0].id").value(reviewId));
        mvc.perform(patch("/api/v1/admin/reviews/" + reviewId + "/visibility", admin, Map.of("visible", false)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.visible").value(false));
        mvc.perform(get("/api/v1/products/" + product.getId(), null)).andExpect(jsonPath("$.data.averageRating").value(0.0)).andExpect(jsonPath("$.data.reviewCount").value(0));
        mvc.perform(get("/api/v1/products/" + product.getId() + "/reviews", null)).andExpect(jsonPath("$.data.totalElements").value(0));

        mvc.perform(patch("/api/v1/admin/reviews/" + reviewId + "/visibility", admin, Map.of("visible", true))).andExpect(status().isOk());
        mvc.perform(delete("/api/v1/admin/reviews/" + reviewId, admin)).andExpect(status().isOk());
        mvc.perform(delete("/api/v1/admin/reviews/" + reviewId, admin)).andExpect(status().isNotFound());
    }

    @Test
    void reviewRulesAreEnforced() throws Exception {
        String admin = adminToken();
        Product product = newProduct("Rules Laptop", "100.00", 5);
        String customer = registerCustomer();

        mvc.perform(post("/api/v1/products/" + product.getId() + "/reviews", null, Map.of("rating", 5))).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/products/" + product.getId() + "/reviews", customer, Map.of("rating", 5))).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/products/" + product.getId() + "/reviews", customer, Map.of("rating", 6)))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.errors.rating").exists());

        addToCart(customer, product.getId(), 1);
        String order = checkout(customer, createAddress(customer), "STANDARD", "CASH_ON_DELIVERY", null);
        mvc.perform(post("/api/v1/products/" + product.getId() + "/reviews", customer, Map.of("rating", 5))).andExpect(status().isForbidden());
        deliver(admin, order);

        long id = read(mvc.perform(post("/api/v1/products/" + product.getId() + "/reviews", customer, Map.of("rating", 3, "comment", "ok")))
                .andExpect(status().isCreated()).andReturn()).at("/data/id").asLong();
        mvc.perform(post("/api/v1/products/" + product.getId() + "/reviews", customer, Map.of("rating", 5))).andExpect(status().isConflict());

        mvc.perform(put("/api/v1/reviews/" + id, customer, Map.of("rating", 5, "comment", "better")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.rating").value(5));
        mvc.perform(get("/api/v1/products/" + product.getId(), null)).andExpect(jsonPath("$.data.averageRating").value(5.0));
        mvc.perform(put("/api/v1/reviews/" + id, registerCustomer(), Map.of("rating", 1))).andExpect(status().isNotFound());
        mvc.perform(delete("/api/v1/reviews/" + id, registerCustomer())).andExpect(status().isNotFound());
        mvc.perform(delete("/api/v1/reviews/" + id, customer)).andExpect(status().isOk());
        mvc.perform(get("/api/v1/products/" + product.getId(), null)).andExpect(jsonPath("$.data.reviewCount").value(0));
    }

    private void deliver(String admin, String order) throws Exception {
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/status", admin, Map.of("status", "CONFIRMED"))).andExpect(status().isOk());
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/status", admin, Map.of("status", "PROCESSING"))).andExpect(status().isOk());
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/ship", admin, Map.of("trackingNumber", "T-" + order))).andExpect(status().isOk());
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/status", admin, Map.of("status", "DELIVERED"))).andExpect(status().isOk());
    }

    // ---------- orders, payments, reports ----------
    @Test
    void adminOrderListFiltersAndDetail() throws Exception {
        String admin = adminToken();
        Product product = newProduct("Admin List Laptop", "100.00", 5);
        String customer = registerCustomer();
        addToCart(customer, product.getId(), 1);
        String order = checkout(customer, createAddress(customer), "STANDARD", "KHQR", null);
        String today = java.time.LocalDate.now().toString();

        mvc.perform(get("/api/v1/admin/orders?status=PENDING&keyword=" + order + "&from=" + today + "&to=" + today, admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].orderNumber").value(order))
                .andExpect(jsonPath("$.data.content[0].customerEmail").exists());
        mvc.perform(get("/api/v1/admin/orders?status=DELIVERED&keyword=" + order, admin)).andExpect(jsonPath("$.data.totalElements").value(0));
        mvc.perform(get("/api/v1/admin/orders?from=2000-01-01&to=2000-01-02&keyword=" + order, admin)).andExpect(jsonPath("$.data.totalElements").value(0));
        mvc.perform(get("/api/v1/admin/orders/" + order, admin)).andExpect(jsonPath("$.data.items.length()").value(1));
        mvc.perform(get("/api/v1/admin/orders/NOPE", admin)).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/admin/orders?status=BOGUS", admin)).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/status", admin, Map.of())).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/orders/" + order + "/status", admin, Map.of("status", "CANCELLED", "reason", "fraud")))
                .andExpect(jsonPath("$.data.status").value("CANCELLED"));
    }

    @Test
    void adminPaymentsListAndRefund() throws Exception {
        String admin = adminToken();
        Product product = newProduct("Refundable Laptop", "100.00", 5);
        String customer = registerCustomer();
        addToCart(customer, product.getId(), 1);
        String order = checkout(customer, createAddress(customer), "STANDARD", "KHQR", null);
        long paymentId = read(mvc.perform(get("/api/v1/payments/" + order + "/status", customer)).andReturn()).at("/data/id").asLong();

        mvc.perform(post("/api/v1/admin/payments/" + paymentId + "/refund", admin, null)).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/payments/callback", null, Map.of("transactionRef", "T-ADM", "orderNumber", order, "status", "PAID")));
        mvc.perform(get("/api/v1/admin/payments?status=PAID", admin)).andExpect(status().isOk()).andExpect(jsonPath("$.data.content[0].status").value("PAID"));
        mvc.perform(get("/api/v1/admin/payments", admin)).andExpect(jsonPath("$.data.totalElements", greaterThanOrEqualTo(1)));
        mvc.perform(post("/api/v1/admin/payments/" + paymentId + "/refund", admin, null))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.status").value("REFUNDED"));
        mvc.perform(post("/api/v1/admin/payments/99999999/refund", admin, null)).andExpect(status().isNotFound());
    }

    @Test
    void dashboardAndSalesReports() throws Exception {
        String admin = adminToken();
        mvc.perform(get("/api/v1/admin/reports/dashboard", admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalSales").isNumber())
                .andExpect(jsonPath("$.data.totalOrders").isNumber())
                .andExpect(jsonPath("$.data.ordersByStatus.PENDING").isNumber())
                .andExpect(jsonPath("$.data.totalCustomers").isNumber())
                .andExpect(jsonPath("$.data.topProducts").isArray())
                .andExpect(jsonPath("$.data.lowStockCount", greaterThanOrEqualTo(3)));

        String today = java.time.LocalDate.now().toString();
        String weekAgo = java.time.LocalDate.now().minusDays(6).toString();
        mvc.perform(get("/api/v1/admin/reports/sales?from=" + weekAgo + "&to=" + today, admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(7))
                .andExpect(jsonPath("$.data[0].revenue").isNumber());
        mvc.perform(get("/api/v1/admin/reports/sales?from=" + today + "&to=" + weekAgo, admin)).andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/admin/reports/sales", admin)).andExpect(status().isBadRequest());
    }

    // ---------- uploads ----------
    @Test
    void imageUploadStoresFileAndServesItPublicly() throws Exception {
        String admin = adminToken();
        byte[] png = {(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3};
        MockMultipartFile file = new MockMultipartFile("file", "photo.png", "image/png", png);

        MvcResult res = mvc.perform(MockMvcRequestBuilders.multipart("/api/v1/admin/uploads").file(file).header("Authorization", "Bearer " + admin))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.url", startsWith("/uploads/")))
                .andExpect(jsonPath("$.data.url", endsWith(".png")))
                .andExpect(jsonPath("$.data.size").value(png.length)).andReturn();

        String url = read(res).at("/data/url").asText();
        MvcResult served = mvc.perform(get(url, null)).andExpect(status().isOk()).andReturn();
        assertThat(served.getResponse().getContentAsByteArray()).isEqualTo(png);
    }

    @Test
    void uploadRejectsNonImagesEmptyFilesAndAnonymousUsers() throws Exception {
        String admin = adminToken();
        MockMultipartFile text = new MockMultipartFile("file", "notes.txt", "text/plain", "hello".getBytes());
        MockMultipartFile empty = new MockMultipartFile("file", "empty.png", "image/png", new byte[0]);

        mvc.perform(MockMvcRequestBuilders.multipart("/api/v1/admin/uploads").file(text).header("Authorization", "Bearer " + admin))
                .andExpect(status().isBadRequest());
        mvc.perform(MockMvcRequestBuilders.multipart("/api/v1/admin/uploads").file(empty).header("Authorization", "Bearer " + admin))
                .andExpect(status().isBadRequest());
        mvc.perform(MockMvcRequestBuilders.multipart("/api/v1/admin/uploads").header("Authorization", "Bearer " + admin))
                .andExpect(status().isBadRequest());
        mvc.perform(MockMvcRequestBuilders.multipart("/api/v1/admin/uploads").file(text)).andExpect(status().isUnauthorized());
        mvc.perform(MockMvcRequestBuilders.multipart("/api/v1/admin/uploads").file(text).header("Authorization", "Bearer " + registerCustomer()))
                .andExpect(status().isForbidden());
    }
}
