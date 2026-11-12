package com.ecom.service.impl;

import com.ecom.service.PaymentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** Keeps asking Bakong about auto-cancelled KHQR orders for payment.khqr.late-payment-watch-hours (bakong mode only). */
@Component
@ConditionalOnProperty(name = "payment.khqr.mode", havingValue = "bakong")
@RequiredArgsConstructor
@Slf4j
public class KhqrLatePaymentWatcher {
    private final PaymentService paymentService;

    @Scheduled(initialDelayString = "${payment.khqr.late-payment-check-interval-ms:60000}",
            fixedDelayString = "${payment.khqr.late-payment-check-interval-ms:60000}")
    public void run() {
        try {
            int found = paymentService.checkLatePayments();
            if (found > 0) {
                log.warn("{} customer(s) paid KHQR order(s) after auto-cancel - admins notified", found);
            }
        } catch (RuntimeException ex) {
            log.error("Late KHQR payment check failed: {}", ex.getMessage());
        }
    }
}
