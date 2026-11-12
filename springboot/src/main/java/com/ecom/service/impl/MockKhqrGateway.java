package com.ecom.service.impl;

import com.ecom.service.KhqrCheckResult;
import com.ecom.service.KhqrGateway;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.UUID;

/** Offline simulation used by tests and local development; payments are confirmed through POST /payments/callback. */
@Component
@ConditionalOnProperty(name = "payment.khqr.mode", havingValue = "mock", matchIfMissing = true)
public class MockKhqrGateway implements KhqrGateway {
    @Override
    public KhqrPayload generate(String orderNumber, BigDecimal usdAmount, LocalDateTime expiresAt) {
        String payload = "MOCK-KHQR|merchant=ECOM|order=" + orderNumber + "|amount=" + usdAmount.toPlainString()
                + "|currency=USD|nonce=" + UUID.randomUUID();
        return new KhqrPayload(payload, md5(payload), expiresAt);
    }

    @Override
    public KhqrCheckResult checkStatus(String md5) {
        return KhqrCheckResult.notFound();
    }

    @Override
    public String currency() {
        return "USD";
    }

    @Override
    public BigDecimal gatewayAmount(BigDecimal usdAmount) {
        return usdAmount;
    }

    @Override
    public String accountId() {
        return "mock@ecom";
    }

    private static String md5(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("MD5").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
