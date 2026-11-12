package com.ecom.model.response;

import com.ecom.model.enumerate.KhqrMode;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** qrPayload is kept as an alias of qrString for clients written against the first API version. */
public record KhqrResponse(String orderNumber, BigDecimal amount, String currency, String qrString, String qrPayload, String md5,
                           LocalDateTime expiresAt, KhqrMode mode) {
}
