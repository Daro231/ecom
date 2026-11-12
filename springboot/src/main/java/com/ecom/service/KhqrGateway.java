package com.ecom.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Abstraction over the KHQR / Bakong provider; MockKhqrGateway and BakongKhqrGateway are switched by payment.khqr.mode. */
public interface KhqrGateway {
    /** Builds a dynamic KHQR for an order whose total is given in USD. */
    KhqrPayload generate(String orderNumber, BigDecimal usdAmount, LocalDateTime expiresAt);

    /** Asks the provider whether the QR with this MD5 has been paid. */
    KhqrCheckResult checkStatus(String md5);

    /** Currency code encoded in the QR (USD or KHR). */
    String currency();

    /** The amount the QR must carry for an order total expressed in USD. */
    BigDecimal gatewayAmount(BigDecimal usdAmount);

    /** The account that must receive the money. */
    String accountId();

    record KhqrPayload(String qrPayload, String md5, LocalDateTime expiresAt) {
    }
}
