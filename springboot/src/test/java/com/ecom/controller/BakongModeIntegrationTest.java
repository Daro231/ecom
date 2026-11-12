package com.ecom.controller;

import com.ecom.model.entity.Payment;
import com.ecom.model.entity.Product;
import com.ecom.model.enumerate.PaymentStatus;
import com.ecom.repository.PaymentRepository;
import com.ecom.service.PaymentService;
import com.fasterxml.jackson.databind.JsonNode;
import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.core.WireMockConfiguration;
import kh.gov.nbc.bakong_khqr.BakongKHQR;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

import java.time.LocalDateTime;
import java.util.Map;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Full KHQR journey in payment.khqr.mode=bakong, with WireMock standing in for the Bakong Open API. */
@TestPropertySource(properties = {"payment.khqr.mode=bakong", "bakong.token=test-token", "bakong.account-id=shop@testbank",
        "payment.khqr.poll-interval-ms=600000"})
class BakongModeIntegrationTest extends AbstractIntegrationTest {
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
    PaymentRepository paymentRepository;
    @Autowired
    PaymentService paymentService;

    @BeforeEach
    void resetBakong() {
        BAKONG.resetAll();
    }

    private void stubPaid(String md5, String amount, String to) {
        BAKONG.stubFor(com.github.tomakehurst.wiremock.client.WireMock.post(urlEqualTo(CHECK)).withHeader("Authorization", equalTo("Bearer test-token"))
                .withRequestBody(matchingJsonPath("$.md5", equalTo(md5)))
                .willReturn(okJson("{\"responseCode\":0,\"responseMessage\":\"Getting transaction successfully.\",\"errorCode\":null,"
                        + "\"data\":{\"hash\":\"hash-" + md5.substring(0, 6) + "\",\"fromAccountId\":\"buyer@bank\",\"toAccountId\":\"" + to
                        + "\",\"currency\":\"USD\",\"amount\":" + amount + ",\"createdDateMs\":1730000000000,\"acknowledgedDateMs\":1730000001000}}")));
    }

    private void stubNotFound() {
        BAKONG.stubFor(com.github.tomakehurst.wiremock.client.WireMock.post(urlEqualTo(CHECK)).willReturn(okJson(
                "{\"responseCode\":1,\"responseMessage\":\"Transaction could not be found.\",\"errorCode\":3,\"data\":null}")));
    }

    private record Placed(String token, String orderNumber, JsonNode qr) {
    }

    private Placed placeKhqrOrder(String price) throws Exception {
        String token = registerCustomer();
        Product product = newProduct("Bakong Laptop", price, 5);
        addToCart(token, product.getId(), 1);
        String orderNumber = checkout(token, createAddress(token), "STANDARD", "KHQR", null);
        MvcResult res = mvc.perform(post("/api/v1/payments/" + orderNumber + "/khqr", token, null)).andExpect(status().isOk()).andReturn();
        return new Placed(token, orderNumber, read(res).at("/data"));
    }

    @Test
    void khqrIsARealScannableCodeAndTheSameOneIsReturnedUntilItExpires() throws Exception {
        Placed placed = placeKhqrOrder("100.00");

        assertThat(placed.qr().at("/mode").asText()).isEqualTo("BAKONG");
        assertThat(placed.qr().at("/amount").decimalValue()).isEqualByComparingTo("105.00");
        assertThat(placed.qr().at("/currency").asText()).isEqualTo("USD");
        assertThat(placed.qr().at("/md5").asText()).matches("[0-9a-f]{32}");
        assertThat(placed.qr().at("/qrPayload").asText()).isEqualTo(placed.qr().at("/qrString").asText());
        assertThat(BakongKHQR.verify(placed.qr().at("/qrString").asText()).getData().isValid()).isTrue();
        assertThat(BakongKHQR.decode(placed.qr().at("/qrString").asText()).getData().getBillNumber()).isEqualTo(placed.orderNumber());

        mvc.perform(post("/api/v1/payments/" + placed.orderNumber() + "/khqr", placed.token(), null))
                .andExpect(jsonPath("$.data.md5").value(placed.qr().at("/md5").asText()));
        assertThat(BAKONG.getAllServeEvents()).isEmpty();
    }

    @Test
    void paymentIsConfirmedWhenPollingFindsTheTransaction() throws Exception {
        Placed placed = placeKhqrOrder("100.00");
        String md5 = placed.qr().at("/md5").asText();
        stubPaid(md5, "105.0", "shop@testbank");

        mvc.perform(get("/api/v1/payments/" + placed.orderNumber() + "/status", placed.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("PAID"))
                .andExpect(jsonPath("$.data.transactionRef").value("hash-" + md5.substring(0, 6)));
        mvc.perform(get("/api/v1/orders/" + placed.orderNumber(), placed.token())).andExpect(jsonPath("$.data.status").value("CONFIRMED"));
        mvc.perform(get("/api/v1/notifications", placed.token()))
                .andExpect(jsonPath("$.data.content[?(@.title==\"Payment received\")].message", hasItem(containsString("$105.00"))));

        // polling again must not confirm or notify twice
        mvc.perform(get("/api/v1/payments/" + placed.orderNumber() + "/status", placed.token())).andExpect(jsonPath("$.data.status").value("PAID"));
        mvc.perform(get("/api/v1/notifications/unread-count", placed.token())).andExpect(jsonPath("$.data").value(2));
        BAKONG.verify(1, postRequestedFor(urlEqualTo(CHECK)));
    }

    @Test
    void wrongAmountIsNeverMarkedPaidAndAdminsAreAlerted() throws Exception {
        String admin = adminToken();
        long before = read(mvc.perform(get("/api/v1/notifications/unread-count", admin)).andReturn()).at("/data").asLong();
        Placed placed = placeKhqrOrder("100.00");
        stubPaid(placed.qr().at("/md5").asText(), "1.0", "shop@testbank");

        mvc.perform(get("/api/v1/payments/" + placed.orderNumber() + "/status", placed.token()))
                .andExpect(jsonPath("$.data.status").value("FAILED"))
                .andExpect(jsonPath("$.data.failureReason").value(containsString("Amount mismatch")));
        mvc.perform(get("/api/v1/orders/" + placed.orderNumber(), placed.token())).andExpect(jsonPath("$.data.status").value("PENDING"));
        mvc.perform(get("/api/v1/notifications/unread-count", admin)).andExpect(jsonPath("$.data").value(before + 1));
        mvc.perform(get("/api/v1/notifications", admin))
                .andExpect(jsonPath("$.data.content[?(@.title==\"KHQR payment needs attention\")]").exists());
    }

    @Test
    void paymentToAnotherAccountIsRejected() throws Exception {
        Placed placed = placeKhqrOrder("100.00");
        stubPaid(placed.qr().at("/md5").asText(), "105.0", "somebody@else");

        mvc.perform(get("/api/v1/payments/" + placed.orderNumber() + "/status", placed.token()))
                .andExpect(jsonPath("$.data.status").value("FAILED"))
                .andExpect(jsonPath("$.data.failureReason").value(containsString("Receiving account")));
    }

    @Test
    void statusPollingIsRateLimitedAndAdminRecheckBypassesTheLimit() throws Exception {
        Placed placed = placeKhqrOrder("100.00");
        String admin = adminToken();
        stubNotFound();

        mvc.perform(get("/api/v1/payments/" + placed.orderNumber() + "/status", placed.token())).andExpect(jsonPath("$.data.status").value("PENDING"));
        mvc.perform(get("/api/v1/payments/" + placed.orderNumber() + "/status", placed.token())).andExpect(jsonPath("$.data.status").value("PENDING"));
        BAKONG.verify(1, postRequestedFor(urlEqualTo(CHECK)));

        stubPaid(placed.qr().at("/md5").asText(), "105.0", "shop@testbank");
        mvc.perform(post("/api/v1/admin/payments/" + placed.orderNumber() + "/recheck", admin, null))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.status").value("PAID"));
        BAKONG.verify(2, postRequestedFor(urlEqualTo(CHECK)));
        mvc.perform(get("/api/v1/orders/" + placed.orderNumber(), placed.token())).andExpect(jsonPath("$.data.status").value("CONFIRMED"));
    }

    @Test
    void scheduledReconcilerConfirmsPaymentsWithoutAnyClientPolling() throws Exception {
        Placed placed = placeKhqrOrder("100.00");
        stubNotFound(); // every other unpaid QR left in the shared test database is simply "not paid yet"
        stubPaid(placed.qr().at("/md5").asText(), "105.0", "shop@testbank");

        assertThat(paymentService.reconcilePending()).isGreaterThanOrEqualTo(1);

        mvc.perform(get("/api/v1/orders/" + placed.orderNumber(), placed.token()))
                .andExpect(jsonPath("$.data.status").value("CONFIRMED"))
                .andExpect(jsonPath("$.data.payment.status").value("PAID"));
    }

    @Test
    void expiredQrFailsThePaymentButTheCustomerCanGetANewOne() throws Exception {
        Placed placed = placeKhqrOrder("100.00");
        Payment payment = paymentRepository.findByOrder_OrderNumber(placed.orderNumber()).orElseThrow();
        payment.setKhqrExpiresAt(LocalDateTime.now().minusMinutes(30));
        paymentRepository.save(payment);
        stubNotFound();

        paymentService.reconcilePending();

        mvc.perform(get("/api/v1/payments/" + placed.orderNumber() + "/status", placed.token()))
                .andExpect(jsonPath("$.data.status").value("FAILED"))
                .andExpect(jsonPath("$.data.failureReason").value("QR expired"));
        mvc.perform(get("/api/v1/orders/" + placed.orderNumber(), placed.token())).andExpect(jsonPath("$.data.status").value("PENDING"));

        mvc.perform(post("/api/v1/payments/" + placed.orderNumber() + "/khqr", placed.token(), null))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.md5", not(placed.qr().at("/md5").asText())));
        mvc.perform(get("/api/v1/payments/" + placed.orderNumber() + "/status", placed.token())).andExpect(jsonPath("$.data.status").value("PENDING"));
        assertThat(paymentRepository.findByOrder_OrderNumber(placed.orderNumber()).orElseThrow().getStatus()).isEqualTo(PaymentStatus.PENDING);
    }

    @Test
    void expiredBakongTokenGivesTheClientA502WithAFriendlyMessage() throws Exception {
        Placed placed = placeKhqrOrder("100.00");
        BAKONG.stubFor(com.github.tomakehurst.wiremock.client.WireMock.post(urlEqualTo(CHECK)).willReturn(aResponse().withStatus(401)));

        mvc.perform(get("/api/v1/payments/" + placed.orderNumber() + "/status", placed.token()))
                .andExpect(status().isBadGateway())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value(containsString("contact the store")));
        mvc.perform(get("/api/v1/orders/" + placed.orderNumber(), placed.token())).andExpect(jsonPath("$.data.status").value("PENDING"));
    }

    @Test
    void slowBakongGivesA504() throws Exception {
        Placed placed = placeKhqrOrder("100.00");
        BAKONG.stubFor(com.github.tomakehurst.wiremock.client.WireMock.post(urlEqualTo(CHECK)).willReturn(aResponse().withStatus(200).withFixedDelay(12_000)));

        mvc.perform(get("/api/v1/payments/" + placed.orderNumber() + "/status", placed.token())).andExpect(status().isGatewayTimeout());
    }

    @Test
    void fakeCallbacksAreNotFoundAndRecheckIsAdminOnly() throws Exception {
        Placed placed = placeKhqrOrder("100.00");

        mvc.perform(post("/api/v1/payments/callback", null, Map.of("transactionRef", "FAKE", "orderNumber", placed.orderNumber(), "status", "PAID")))
                .andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/orders/" + placed.orderNumber(), placed.token())).andExpect(jsonPath("$.data.status").value("PENDING"));

        mvc.perform(post("/api/v1/admin/payments/" + placed.orderNumber() + "/recheck", placed.token(), null)).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/payments/" + placed.orderNumber() + "/recheck", null, null)).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/admin/payments/ECOM-NOPE/recheck", adminToken(), null)).andExpect(status().isNotFound());
    }
}
