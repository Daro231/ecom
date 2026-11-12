package com.ecom.service;

import com.ecom.common.exception.PaymentGatewayException;
import com.ecom.config.BakongProperties;
import com.ecom.service.impl.BakongKhqrGateway;
import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.core.WireMockConfiguration;
import kh.gov.nbc.bakong_khqr.BakongKHQR;
import kh.gov.nbc.bakong_khqr.model.KHQRDecodeData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.ecom.service.impl.BakongKhqrGateway;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** The real Bakong API is never called: WireMock plays Bakong, and the SDK runs offline. */
class BakongKhqrGatewayTest {
    static final String PATH = "/v1/check_transaction_by_md5";
    static final String PAID_BODY = """
            {"responseCode":0,"responseMessage":"Getting transaction successfully.","errorCode":null,
             "data":{"hash":"abc123","fromAccountId":"buyer@bank","toAccountId":"shop@testbank","currency":"USD",
                     "amount":105.0,"description":"order","createdDateMs":1730000000000,"acknowledgedDateMs":1730000001000}}
            """;

    WireMockServer bakong;
    BakongProperties props;
    BakongKhqrGateway gateway;

    @BeforeEach
    void setUp() {
        bakong = new WireMockServer(WireMockConfiguration.options().dynamicPort());
        bakong.start();
        props = new BakongProperties();
        props.setBaseUrl("http://localhost:" + bakong.port());
        props.setToken("test-token");
        props.setAccountId("shop@testbank");
        props.setReadTimeoutMs(400);
        props.setConnectTimeoutMs(400);
        gateway = new BakongKhqrGateway(props);
    }

    @AfterEach
    void tearDown() {
        bakong.stop();
    }

    // ---------- check_transaction_by_md5 ----------
    @Test
    void paidTransactionIsMappedWithAllFields() {
        bakong.stubFor(post(urlEqualTo(PATH)).withHeader("Authorization", equalTo("Bearer test-token"))
                .withRequestBody(equalToJson("{\"md5\":\"md5-abc\"}"))
                .willReturn(okJson(PAID_BODY)));

        KhqrCheckResult result = gateway.checkStatus("md5-abc");

        assertThat(result.status()).isEqualTo(KhqrCheckResult.Status.PAID);
        assertThat(result.hash()).isEqualTo("abc123");
        assertThat(result.fromAccountId()).isEqualTo("buyer@bank");
        assertThat(result.toAccountId()).isEqualTo("shop@testbank");
        assertThat(result.currency()).isEqualTo("USD");
        assertThat(result.amount()).isEqualByComparingTo("105.00");
        assertThat(result.paidAt()).isEqualTo(LocalDateTime.ofInstant(java.time.Instant.ofEpochMilli(1730000001000L), ZoneId.systemDefault()));
    }

    @Test
    void paidAtFallsBackToCreatedDateThenNow() {
        bakong.stubFor(post(urlEqualTo(PATH)).willReturn(okJson(
                "{\"responseCode\":0,\"data\":{\"hash\":\"h\",\"createdDateMs\":1730000000000,\"amount\":1,\"currency\":\"USD\"}}")));
        assertThat(gateway.checkStatus("m").paidAt().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()).isEqualTo(1730000000000L);

        bakong.stubFor(post(urlEqualTo(PATH)).willReturn(okJson("{\"responseCode\":0,\"data\":{\"hash\":\"h\"}}")));
        assertThat(gateway.checkStatus("m").paidAt()).isNotNull();
    }

    @Test
    void unknownTransactionIsNotFound() {
        bakong.stubFor(post(urlEqualTo(PATH)).willReturn(okJson(
                "{\"responseCode\":1,\"responseMessage\":\"Transaction could not be found. Please check and try again.\",\"errorCode\":3,\"data\":null}")));

        assertThat(gateway.checkStatus("md5-x").status()).isEqualTo(KhqrCheckResult.Status.NOT_FOUND);
    }

    @Test
    void notFoundIsRecognisedByMessageToo() {
        bakong.stubFor(post(urlEqualTo(PATH)).willReturn(okJson("{\"responseCode\":1,\"responseMessage\":\"Not found\",\"data\":null}")));

        assertThat(gateway.checkStatus("md5-x").status()).isEqualTo(KhqrCheckResult.Status.NOT_FOUND);
    }

    @Test
    void expiredTokenAnswerWith401IsABadGateway() {
        bakong.stubFor(post(urlEqualTo(PATH)).willReturn(aResponse().withStatus(401).withBody("{\"message\":\"Unauthorized\"}")));

        assertThatThrownBy(() -> gateway.checkStatus("md5-x")).isInstanceOfSatisfying(PaymentGatewayException.class, ex -> {
            assertThat(ex.getStatus()).isEqualTo(HttpStatus.BAD_GATEWAY);
            assertThat(ex.getMessage()).contains("authentication");
        });
    }

    @Test
    void serverErrorIsABadGateway() {
        bakong.stubFor(post(urlEqualTo(PATH)).willReturn(aResponse().withStatus(500)));

        assertThatThrownBy(() -> gateway.checkStatus("md5-x")).isInstanceOfSatisfying(PaymentGatewayException.class,
                ex -> assertThat(ex.getStatus()).isEqualTo(HttpStatus.BAD_GATEWAY));
    }

    @Test
    void slowAnswerIsAGatewayTimeout() {
        bakong.stubFor(post(urlEqualTo(PATH)).willReturn(okJson(PAID_BODY).withFixedDelay(2000)));

        assertThatThrownBy(() -> gateway.checkStatus("md5-x")).isInstanceOfSatisfying(PaymentGatewayException.class,
                ex -> assertThat(ex.getStatus()).isEqualTo(HttpStatus.GATEWAY_TIMEOUT));
    }

    @Test
    void unreachableServerIsAGatewayTimeout() {
        bakong.stop();

        assertThatThrownBy(() -> gateway.checkStatus("md5-x")).isInstanceOfSatisfying(PaymentGatewayException.class,
                ex -> assertThat(ex.getStatus()).isEqualTo(HttpStatus.GATEWAY_TIMEOUT));
    }

    @Test
    void malformedJsonIsABadGateway() {
        bakong.stubFor(post(urlEqualTo(PATH)).willReturn(aResponse().withHeader("Content-Type", "application/json").withBody("{not json")));

        assertThatThrownBy(() -> gateway.checkStatus("md5-x")).isInstanceOfSatisfying(PaymentGatewayException.class,
                ex -> assertThat(ex.getStatus()).isEqualTo(HttpStatus.BAD_GATEWAY));
    }

    @Test
    void onlyResponseCodeZeroWithADataObjectIsPaid() {
        // paid-looking data but a non-zero responseCode: never paid
        bakong.stubFor(post(urlEqualTo(PATH)).willReturn(okJson(
                "{\"responseCode\":1,\"responseMessage\":\"x\",\"data\":{\"hash\":\"h\",\"amount\":105.0,\"currency\":\"USD\"}}")));
        assertThat(gateway.checkStatus("m").status()).isEqualTo(KhqrCheckResult.Status.NOT_FOUND);
    }

    @Test
    void responseCodeZeroWithoutADataObjectIsNotPaid() {
        for (String body : new String[]{"{\"responseCode\":0}", "{\"responseCode\":0,\"data\":null}", "{\"responseCode\":0,\"data\":[]}",
                "{\"responseCode\":0,\"data\":\"paid\"}"}) {
            bakong.stubFor(post(urlEqualTo(PATH)).willReturn(okJson(body)));
            assertThat(gateway.checkStatus("m").status()).as(body).isEqualTo(KhqrCheckResult.Status.NOT_FOUND);
        }
    }

    @Test
    void anyOtherResponseCodeIsNotPaidWhateverTheErrorCodeOrMessage() {
        for (String body : new String[]{
                "{\"responseCode\":1,\"responseMessage\":\"Transaction could not be found.\",\"errorCode\":3,\"data\":null}",
                "{\"responseCode\":1,\"responseMessage\":\"Something odd\",\"errorCode\":99,\"data\":null}",
                "{\"responseCode\":1,\"responseMessage\":\"Token has expired\",\"errorCode\":11,\"data\":null}",
                "{\"responseCode\":-1,\"errorCode\":null}",
                "{\"responseCode\":\"abc\",\"data\":{}}",
                "{\"hello\":\"world\"}",
                "[]",
                "null"}) {
            bakong.stubFor(post(urlEqualTo(PATH)).willReturn(okJson(body)));
            assertThat(gateway.checkStatus("m").status()).as(body).isEqualTo(KhqrCheckResult.Status.NOT_FOUND);
        }
    }

    @Test
    void emptyBodyIsNotPaid() {
        bakong.stubFor(post(urlEqualTo(PATH)).willReturn(aResponse().withStatus(200)));

        assertThat(gateway.checkStatus("m").status()).isEqualTo(KhqrCheckResult.Status.NOT_FOUND);
    }

    @Test
    void theFullRawBakongJsonIsLoggedAtDebug() {
        Logger logger = (Logger) LoggerFactory.getLogger(BakongKhqrGateway.class);
        Level previous = logger.getLevel();
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        logger.addAppender(appender);
        logger.setLevel(Level.DEBUG);
        try {
            bakong.stubFor(post(urlEqualTo(PATH)).willReturn(okJson("{\"responseCode\":1,\"responseMessage\":\"raw-marker\",\"errorCode\":42,\"data\":null}")));
            gateway.checkStatus("md5-raw");
            bakong.stubFor(post(urlEqualTo(PATH)).willReturn(aResponse().withStatus(404).withBody("{\"error\":\"raw-http-marker\"}")));
            assertThatThrownBy(() -> gateway.checkStatus("md5-raw")).isInstanceOf(PaymentGatewayException.class);
        } finally {
            logger.detachAppender(appender);
            logger.setLevel(previous);
        }

        assertThat(appender.list).filteredOn(e -> e.getLevel() == Level.DEBUG).extracting(ILoggingEvent::getFormattedMessage)
                .anyMatch(m -> m.contains("md5-raw") && m.contains("\"responseMessage\":\"raw-marker\"") && m.contains("\"errorCode\":42"))
                .anyMatch(m -> m.contains("HTTP 404") && m.contains("raw-http-marker"));
    }

    // ---------- offline KHQR generation with the official SDK ----------
    @Test
    void generatedQrIsValidAndCarriesAmountCurrencyAndBillNumber() {
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(10);

        KhqrGateway.KhqrPayload payload = gateway.generate("ECOM-20261104-0001", new BigDecimal("105.00"), expiry);

        assertThat(BakongKHQR.verify(payload.qrPayload()).getData().isValid()).isTrue();
        assertThat(payload.md5()).matches("[0-9a-f]{32}");
        assertThat(payload.expiresAt()).isEqualTo(expiry);
        KHQRDecodeData decoded = BakongKHQR.decode(payload.qrPayload()).getData();
        assertThat(new BigDecimal(decoded.getTransactionAmount())).isEqualByComparingTo("105.00");
        assertThat(decoded.getTransactionCurrency()).isEqualTo("840");
        assertThat(decoded.getBillNumber()).isEqualTo("ECOM-20261104-0001");
        assertThat(decoded.getBakongAccountID()).isEqualTo("shop@testbank");
        assertThat(decoded.getMerchantName()).isEqualTo("ECOM Computer Store");
        assertThat(decoded.getMerchantCity()).isEqualTo("Phnom Penh");
        assertThat(decoded.getStoreLabel()).isEqualTo("ECOM");
        assertThat(decoded.getTerminalLabel()).isEqualTo("WEB");
        assertThat(decoded.getExpirationTimestamp()).isEqualTo(String.valueOf(expiry.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()));
    }

    @Test
    void khrQrConvertsTheUsdTotal() {
        props.setCurrency("KHR");
        props.setKhrPerUsd(new BigDecimal("4000"));

        KhqrGateway.KhqrPayload payload = gateway.generate("ECOM-20261104-0002", new BigDecimal("12.50"), LocalDateTime.now().plusMinutes(10));

        KHQRDecodeData decoded = BakongKHQR.decode(payload.qrPayload()).getData();
        assertThat(decoded.getTransactionCurrency()).isEqualTo("116");
        assertThat(new BigDecimal(decoded.getTransactionAmount())).isEqualByComparingTo("50000");
        assertThat(gateway.currency()).isEqualTo("KHR");
        assertThat(gateway.gatewayAmount(new BigDecimal("12.50"))).isEqualByComparingTo("50000");
    }

    @Test
    void sdkErrorsBecomeGatewayExceptionsWithTheSdkMessage() {
        props.setAccountId("");
        assertThatThrownBy(() -> gateway.generate("ECOM-1", BigDecimal.TEN, LocalDateTime.now().plusMinutes(5)))
                .isInstanceOfSatisfying(PaymentGatewayException.class, ex -> assertThat(ex.getMessage()).contains("Bakong Account ID"));

        props.setAccountId("shop@testbank");
        assertThatThrownBy(() -> gateway.generate("ECOM-1", BigDecimal.TEN, LocalDateTime.now().minusMinutes(5)))
                .isInstanceOf(PaymentGatewayException.class);
    }

    @Test
    void gatewayReportsItsAccount() {
        assertThat(gateway.accountId()).isEqualTo("shop@testbank");
        assertThat(gateway.currency()).isEqualTo("USD");
        assertThat(gateway.gatewayAmount(new BigDecimal("7.5"))).isEqualByComparingTo("7.50");
    }
}
