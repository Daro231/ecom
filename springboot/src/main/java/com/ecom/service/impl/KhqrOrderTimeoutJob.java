package com.ecom.service.impl;

import com.ecom.service.PaymentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** Cancels KHQR orders nobody paid (payment.khqr.auto-cancel-minutes), in mock and bakong mode alike. */
@Component
@RequiredArgsConstructor
@Slf4j
public class KhqrOrderTimeoutJob {
    private final PaymentService paymentService;

    @Scheduled(initialDelayString = "${payment.khqr.auto-cancel-check-interval-ms:60000}",
            fixedDelayString = "${payment.khqr.auto-cancel-check-interval-ms:60000}")
    public void run() {
        try {
            int cancelled = paymentService.cancelUnpaidKhqrOrders();
            if (cancelled > 0) {
                log.info("Auto-cancelled {} unpaid KHQR order(s)", cancelled);
            }
        } catch (RuntimeException ex) {
            log.error("KHQR auto-cancel failed: {}", ex.getMessage());
        }
    }
}
