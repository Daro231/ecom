package com.ecom.service.impl;

import com.ecom.common.exception.PaymentGatewayException;
import com.ecom.config.BakongProperties;
import com.ecom.service.KhqrCheckResult;
import com.ecom.service.KhqrGateway;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import kh.gov.nbc.bakong_khqr.BakongKHQR;
import kh.gov.nbc.bakong_khqr.model.IndividualInfo;
import kh.gov.nbc.bakong_khqr.model.KHQRCurrency;
import kh.gov.nbc.bakong_khqr.model.KHQRData;
import kh.gov.nbc.bakong_khqr.model.KHQRResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Map;

/**
 * Real Bakong KHQR: QR strings are generated offline with the official NBC SDK, payment status is read from the
 * Bakong Open API (POST /v1/check_transaction_by_md5, Bearer token).
 */
@Component
@ConditionalOnProperty(name = "payment.khqr.mode", havingValue = "bakong")
@Slf4j
public class BakongKhqrGateway implements KhqrGateway {
    static final String CHECK_PATH = "/v1/check_transaction_by_md5";
    private static final ObjectMapper JSON = new ObjectMapper();

    private final BakongProperties props;
    private final RestClient restClient;

    public BakongKhqrGateway(BakongProperties props) {
        this.props = props;
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(props.getConnectTimeoutMs());
        factory.setReadTimeout(props.getReadTimeoutMs());
        this.restClient = RestClient.builder().baseUrl(props.getBaseUrl()).requestFactory(factory).build();
    }

    @Override
    public KhqrPayload generate(String orderNumber, BigDecimal usdAmount, LocalDateTime expiresAt) {
        IndividualInfo info = new IndividualInfo();
        info.setBakongAccountId(props.getAccountId());
        info.setMerchantName(props.getMerchantName());
        info.setMerchantCity(props.getMerchantCity());
        info.setCurrency(KHQRCurrency.valueOf(currency()));
        info.setAmount(gatewayAmount(usdAmount).doubleValue());
        info.setBillNumber(orderNumber);
        info.setStoreLabel(props.getStoreLabel());
        info.setTerminalLabel(props.getTerminalLabel());
        info.setExpirationTimestamp(expiresAt.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli());

        KHQRResponse<KHQRData> response = BakongKHQR.generateIndividual(info);
        if (response.getKHQRStatus().getCode() != 0 || response.getData() == null) {
            throw new PaymentGatewayException("Could not generate KHQR: " + response.getKHQRStatus().getMessage(), HttpStatus.BAD_GATEWAY);
        }
        return new KhqrPayload(response.getData().getQr(), response.getData().getMd5(), expiresAt);
    }

    @Override
    public KhqrCheckResult checkStatus(String md5) {
        String raw;
        try {
            raw = restClient.post().uri(CHECK_PATH)
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + props.getToken())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of("md5", md5))
                    .retrieve().body(String.class);
        } catch (HttpStatusCodeException ex) {
            int code = ex.getStatusCode().value();
            log.debug("Bakong raw response for md5 {} (HTTP {}): {}", md5, code, ex.getResponseBodyAsString());
            if (code == 401 || code == 403) {
                throw tokenProblem();
            }
            log.error("Bakong answered HTTP {} for md5 check", code);
            throw new PaymentGatewayException("Payment provider returned an error, please try again shortly", HttpStatus.BAD_GATEWAY, ex);
        } catch (ResourceAccessException ex) {
            log.warn("Bakong Open API unreachable or timed out: {}", ex.getMessage());
            throw new PaymentGatewayException("Payment provider did not answer in time, please try again", HttpStatus.GATEWAY_TIMEOUT, ex);
        } catch (RestClientException ex) {
            if (isTimeout(ex)) {
                log.warn("Bakong Open API timed out while answering: {}", ex.getMessage());
                throw new PaymentGatewayException("Payment provider did not answer in time, please try again", HttpStatus.GATEWAY_TIMEOUT, ex);
            }
            log.error("Bakong answer could not be read: {}", ex.getMessage());
            throw new PaymentGatewayException("Payment provider sent an unreadable answer", HttpStatus.BAD_GATEWAY, ex);
        }
        log.debug("Bakong raw response for md5 {}: {}", md5, raw);
        return parse(raw);
    }

    private static boolean isTimeout(Throwable ex) {
        for (Throwable t = ex; t != null; t = t.getCause()) {
            if (t instanceof java.net.SocketTimeoutException || t instanceof java.net.http.HttpTimeoutException) {
                return true;
            }
        }
        return false;
    }

    /**
     * The only "paid" signal is responseCode == 0 together with a data object. Every other answer, whatever its
     * errorCode or message, means "not paid (yet)" so the caller simply keeps polling.
     */
    private KhqrCheckResult parse(String raw) {
        JsonNode body;
        try {
            body = JSON.readTree(raw == null ? "" : raw);
        } catch (JsonProcessingException ex) {
            log.error("Bakong answer is not valid JSON: {}", ex.getOriginalMessage());
            throw new PaymentGatewayException("Payment provider sent an unreadable answer", HttpStatus.BAD_GATEWAY, ex);
        }
        if (body == null || !body.isObject()) {
            log.warn("Bakong answer is not a JSON object, treating as not paid");
            return KhqrCheckResult.notFound();
        }
        JsonNode data = body.path("data");
        if (body.path("responseCode").asInt(-1) == 0 && data.isObject()) {
            return new KhqrCheckResult(KhqrCheckResult.Status.PAID, text(data, "hash"), text(data, "fromAccountId"),
                    text(data, "toAccountId"), data.hasNonNull("amount") ? data.get("amount").decimalValue() : null,
                    text(data, "currency"), paidAt(data));
        }
        return KhqrCheckResult.notFound();
    }

    private PaymentGatewayException tokenProblem() {
        log.error("Bakong token expired or rejected - renew it at https://api-bakong.nbc.gov.kh and update BAKONG_TOKEN");
        return new PaymentGatewayException("Payment provider authentication failed, please contact the store", HttpStatus.BAD_GATEWAY);
    }

    private static String text(JsonNode node, String field) {
        return node.hasNonNull(field) ? node.get(field).asText() : null;
    }

    private static LocalDateTime paidAt(JsonNode data) {
        for (String field : new String[]{"acknowledgedDateMs", "createdDateMs"}) {
            if (data.hasNonNull(field) && data.get(field).asLong() > 0) {
                return LocalDateTime.ofInstant(Instant.ofEpochMilli(data.get(field).asLong()), ZoneId.systemDefault());
            }
        }
        return LocalDateTime.now();
    }

    @Override
    public String currency() {
        return props.getCurrency();
    }

    @Override
    public BigDecimal gatewayAmount(BigDecimal usdAmount) {
        if ("KHR".equals(props.getCurrency())) {
            return usdAmount.multiply(props.getKhrPerUsd()).setScale(0, RoundingMode.HALF_UP);
        }
        return usdAmount.setScale(2, RoundingMode.HALF_UP);
    }

    @Override
    public String accountId() {
        return props.getAccountId();
    }
}
