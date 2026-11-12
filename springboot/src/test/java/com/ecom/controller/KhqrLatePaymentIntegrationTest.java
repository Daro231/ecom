package com.ecom.controller;

import com.ecom.model.entity.Payment;
import com.ecom.model.entity.Product;
import com.ecom.model.enumerate.PaymentStatus;
import com.ecom.repository.PaymentRepository;
import com.ecom.service.PaymentService;
import com.fasterxml.jackson.databind.JsonNode;
import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.core.WireMockConfiguration;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDateTime;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** A customer pays a KHQR order after the server auto-cancelled it (bakong mode, WireMock as Bakong). */
@TestPropertySource(properties = {"payment.khqr.mode=bakong", "bakong.token=test-token", "bakong.account-id=shop@testbank",
        "payment.khqr.poll-interval-ms=600000", "payment.khqr.late-payment-check-interval-ms=3600000",
        "payment.khqr.auto-cancel-minutes=30", "payment.khqr.auto-cancel-check-interval-ms=3600000",
        "payment.khqr.min-check-interval-seconds=0", "payment.khqr.late-payment-watch-hours=24"})
class KhqrLatePaymentIntegrationTest extends AbstractIntegrationTest {
    static final WireMockServer BAKONG = new WireMockServer(WireMockConfiguration.options().dynamicPort());
    static final String CHECK = "/v1/check_transaction_by_md5";

    static {
        BAKONG.start();
    }

    @DynamicPropertySource
    static void bakongProperties(DynamicPropertyRegistry registry) {
        registry.add("bakong.base-url", () -> "http://localhost:" + BAKONG.port());
    }

    @Autowired
    PaymentService paymentService;
    @Autowired
    PaymentRepository paymentRepository;
    @Autowired
    EntityManager entityManager;
    @Autowired
    TransactionTemplate transactions;

    @BeforeEach
    void reset() {
        BAKONG.resetAll();
        stubNotFound();
    }

    private void stubNotFound() {
        BAKONG.stubFor(com.github.tomakehurst.wiremock.client.WireMock.post(urlEqualTo(CHECK)).atPriority(10).willReturn(okJson(
                "{\"responseCode\":1,\"responseMessage\":\"Transaction could not be found.\",\"errorCode\":3,\"data\":null}")));
    }

    private void stubPaid(String md5, String amount, String to) {
        BAKONG.stubFor(com.github.tomakehurst.wiremock.client.WireMock.post(urlEqualTo(CHECK)).atPriority(1).withRequestBody(matchingJsonPath("$.md5", equalTo(md5)))
                .willReturn(okJson("{\"responseCode\":0,\"responseMessage\":\"ok\",\"errorCode\":null,\"data\":{\"hash\":\"late-"
                        + md5.substring(0, 6) + "\",\"fromAccountId\":\"buyer@bank\",\"toAccountId\":\"" + to
                        + "\",\"currency\":\"USD\",\"amount\":" + amount + ",\"createdDateMs\":1730000000000,\"acknowledgedDateMs\":1730000001000}}")));
    }

    private record Cancelled(String customer, String orderNumber, String md5, Product product) {
    }

    /** Places a KHQR order for 1 x price (total price + 5 shipping), gets its QR, then ages it past the timeout and auto-cancels it. */
    private Cancelled cancelledOrder(String price, int stock) throws Exception {
        String customer = registerCustomer();
        Product product = newProduct("Late Laptop", price, stock);
        addToCart(customer, product.getId(), 1);
        String orderNumber = checkout(customer, createAddress(customer), "STANDARD", "KHQR", null);
        JsonNode qr = read(mvc.perform(post("/api/v1/payments/" + orderNumber + "/khqr", customer, null)).andExpect(status().isOk()).andReturn()).at("/data");
        transactions.executeWithoutResult(s -> entityManager.createQuery("update Orders o set o.createdAt = :t where o.orderNumber = :n")
                .setParameter("t", LocalDateTime.now().minusMinutes(31)).setParameter("n", orderNumber).executeUpdate());
        paymentService.cancelUnpaidKhqrOrders();
        mvc.perform(get("/api/v1/orders/" + orderNumber, customer)).andExpect(jsonPath("$.data.status").value("CANCELLED"));
        return new Cancelled(customer, orderNumber, qr.at("/md5").asText(), product);
    }

    private int stock(Product p) {
        return productRepository.findById(p.getId()).orElseThrow().getStockQuantity();
    }

    @Test
    void latePaymentIsRecordedWithoutRestoringTheOrderOrReservingStock() throws Exception {
        String admin = adminToken();
        Cancelled c = cancelledOrder("100.00", 5);
        assertThat(stock(c.product())).isEqualTo(5);
        stubPaid(c.md5(), "105.0", "shop@testbank");

        assertThat(paymentService.checkLatePayments()).isGreaterThanOrEqualTo(1);

        mvc.perform(get("/api/v1/orders/" + c.orderNumber(), c.customer()))
                .andExpect(jsonPath("$.data.status").value("CANCELLED"))
                .andExpect(jsonPath("$.data.payment.status").value("PAID_AFTER_CANCEL"))
                .andExpect(jsonPath("$.data.payment.transactionRef").value("late-" + c.md5().substring(0, 6)));
        assertThat(stock(c.product())).isEqualTo(5);
        mvc.perform(get("/api/v1/notifications?size=50", admin))
                .andExpect(jsonPath("$.data.content[?(@.title==\"Customer paid after cancel - refund or restore order\")].priority", hasItem("HIGH")))
                .andExpect(jsonPath("$.data.content[?(@.title==\"Customer paid after cancel - refund or restore order\")].message",
                        hasItem(containsString(c.orderNumber()))));
        mvc.perform(get("/api/v1/admin/payments?status=PAID_AFTER_CANCEL&size=100", admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[?(@.orderNumber==\"" + c.orderNumber() + "\")].status", hasItem("PAID_AFTER_CANCEL")));

        // found once: later rounds neither call Bakong for it again nor notify twice
        BAKONG.resetRequests();
        paymentService.checkLatePayments();
        BAKONG.verify(0, postRequestedFor(urlEqualTo(CHECK)).withRequestBody(matchingJsonPath("$.md5", equalTo(c.md5()))));
        mvc.perform(get("/api/v1/notifications?size=100", admin))
                .andExpect(jsonPath("$.data.content[?(@.message=~/.*" + c.orderNumber() + ".*/ && @.priority==\"HIGH\")]", hasSize(1)));
    }

    @Test
    void adminRestoresTheOrderWhenStockIsStillAvailable() throws Exception {
        String admin = adminToken();
        Cancelled c = cancelledOrder("100.00", 5);
        stubPaid(c.md5(), "105.0", "shop@testbank");
        paymentService.checkLatePayments();

        mvc.perform(post("/api/v1/admin/orders/" + c.orderNumber() + "/restore-after-payment", admin, null))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("CONFIRMED"))
                .andExpect(jsonPath("$.data.payment.status").value("PAID"));
        assertThat(stock(c.product())).isEqualTo(4);
        mvc.perform(get("/api/v1/notifications", c.customer()))
                .andExpect(jsonPath("$.data.content[?(@.title==\"Order restored\")]").exists());

        // a second restore is refused: the order is no longer cancelled
        mvc.perform(post("/api/v1/admin/orders/" + c.orderNumber() + "/restore-after-payment", admin, null)).andExpect(status().isBadRequest());
    }

    @Test
    void restoreReturns409WhenOutOfStockAndAdminThenRefunds() throws Exception {
        String admin = adminToken();
        Cancelled c = cancelledOrder("100.00", 1);
        stubPaid(c.md5(), "105.0", "shop@testbank");
        paymentService.checkLatePayments();
        // somebody else buys the last unit while the customer's order was cancelled
        String other = registerCustomer();
        addToCart(other, c.product().getId(), 1);
        checkout(other, createAddress(other), "STANDARD", "CASH_ON_DELIVERY", null);
        assertThat(stock(c.product())).isZero();

        mvc.perform(post("/api/v1/admin/orders/" + c.orderNumber() + "/restore-after-payment", admin, null))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false));
        mvc.perform(get("/api/v1/orders/" + c.orderNumber(), c.customer()))
                .andExpect(jsonPath("$.data.status").value("CANCELLED"))
                .andExpect(jsonPath("$.data.payment.status").value("PAID_AFTER_CANCEL"));
        assertThat(stock(c.product())).isZero();

        mvc.perform(post("/api/v1/admin/payments/" + c.orderNumber() + "/refund", admin, null))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("REFUNDED"));
        mvc.perform(post("/api/v1/admin/payments/" + c.orderNumber() + "/refund", admin, null)).andExpect(status().isBadRequest());
    }

    @Test
    void latePaymentWithWrongAmountIsNotAcceptedAndAdminsAreAlertedOnce() throws Exception {
        String admin = adminToken();
        Cancelled c = cancelledOrder("100.00", 5);
        stubPaid(c.md5(), "1.0", "shop@testbank");

        paymentService.checkLatePayments();
        paymentService.checkLatePayments();

        mvc.perform(get("/api/v1/orders/" + c.orderNumber(), c.customer()))
                .andExpect(jsonPath("$.data.status").value("CANCELLED"))
                .andExpect(jsonPath("$.data.payment.status").value("FAILED"));
        mvc.perform(get("/api/v1/notifications?size=100", admin))
                .andExpect(jsonPath("$.data.content[?(@.message=~/.*" + c.orderNumber() + ".*Amount mismatch.*/)]", hasSize(1)));
    }

    @Test
    void watchEndsAfterTheConfiguredWindow() throws Exception {
        Cancelled c = cancelledOrder("100.00", 5);
        Payment payment = paymentRepository.findByOrder_OrderNumber(c.orderNumber()).orElseThrow();
        assertThat(payment.getLateWatchUntil()).isAfter(LocalDateTime.now().plusHours(23));
        payment.setLateWatchUntil(LocalDateTime.now().minusMinutes(1));
        paymentRepository.save(payment);
        stubPaid(c.md5(), "105.0", "shop@testbank");

        paymentService.checkLatePayments();

        assertThat(paymentRepository.findByOrder_OrderNumber(c.orderNumber()).orElseThrow().getStatus()).isEqualTo(PaymentStatus.FAILED);
        BAKONG.verify(0, postRequestedFor(urlEqualTo(CHECK)).withRequestBody(matchingJsonPath("$.md5", equalTo(c.md5()))));
    }

    @Test
    void restoreAndRefundAreAdminOnlyAndRejectOrdinaryOrders() throws Exception {
        String admin = adminToken();
        Cancelled c = cancelledOrder("100.00", 5);

        mvc.perform(post("/api/v1/admin/orders/" + c.orderNumber() + "/restore-after-payment", c.customer(), null)).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/orders/" + c.orderNumber() + "/restore-after-payment", null, null)).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/admin/orders/" + c.orderNumber() + "/restore-after-payment", admin, null)).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/admin/orders/ECOM-NOPE/restore-after-payment", admin, null)).andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/admin/payments/ECOM-NOPE/refund", admin, null)).andExpect(status().isNotFound());
    }
}
