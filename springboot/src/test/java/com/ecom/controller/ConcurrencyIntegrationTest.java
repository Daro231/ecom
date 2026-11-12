package com.ecom.controller;

import com.ecom.model.entity.Product;
import org.junit.jupiter.api.RepeatedTest;
import org.springframework.test.web.servlet.MvcResult;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;

import static org.assertj.core.api.Assertions.assertThat;

/** Two customers race for the last unit: exactly one order may succeed and stock must never go negative. */
class ConcurrencyIntegrationTest extends AbstractIntegrationTest {

    @RepeatedTest(3)
    void onlyOneCustomerGetsTheLastUnit() throws Exception {
        Product product = newProduct("Last Unit Laptop", "900.00", 1);
        String[] tokens = {registerCustomer(), registerCustomer()};
        long[] addresses = {createAddress(tokens[0]), createAddress(tokens[1])};
        for (String token : tokens) {
            addToCart(token, product.getId(), 1);
        }

        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch go = new CountDownLatch(1);
        List<Future<Integer>> results = new ArrayList<>();
        for (int i = 0; i < 2; i++) {
            final int index = i;
            results.add(pool.submit(() -> {
                ready.countDown();
                go.await();
                MvcResult res = mvc.perform(post("/api/v1/orders/checkout", tokens[index],
                        Map.of("addressId", addresses[index], "shippingMethod", "STANDARD", "paymentMethod", "KHQR"))).andReturn();
                return res.getResponse().getStatus();
            }));
        }
        ready.await();
        go.countDown();
        List<Integer> statuses = new ArrayList<>();
        for (Future<Integer> f : results) {
            statuses.add(f.get(30, TimeUnit.SECONDS));
        }
        pool.shutdown();

        assertThat(statuses).containsExactlyInAnyOrder(201, 409);
        Product reloaded = productRepository.findById(product.getId()).orElseThrow();
        assertThat(reloaded.getStockQuantity()).isZero();

        int ordersPlaced = 0;
        for (String token : tokens) {
            ordersPlaced += read(mvc.perform(get("/api/v1/orders", token)).andReturn()).at("/data/totalElements").asInt();
        }
        assertThat(ordersPlaced).isEqualTo(1);
    }
}
