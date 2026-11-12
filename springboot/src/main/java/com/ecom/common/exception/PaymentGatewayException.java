package com.ecom.common.exception;

import org.springframework.http.HttpStatus;

/** The payment provider could not be used (token expired, timeout, bad answer). Mapped to 502 / 504. */
public class PaymentGatewayException extends RuntimeException {
    private final HttpStatus status;

    public PaymentGatewayException(String message, HttpStatus status) {
        super(message);
        this.status = status;
    }

    public PaymentGatewayException(String message, HttpStatus status, Throwable cause) {
        super(message, cause);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
