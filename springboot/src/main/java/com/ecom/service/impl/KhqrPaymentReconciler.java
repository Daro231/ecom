package com.ecom.service.impl;

import com.ecom.service.PaymentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** Backup for the polling endpoint: Bakong sends no webhook, so unpaid KHQR payments are checked on a timer. */
@Component
@ConditionalOnProperty(name = "payment.khqr.mode", havingValue = "bakong")
@RequiredArgsConstructor
@Slf4j
public class KhqrPaymentReconciler {
    private final PaymentService paymentService;

    @Scheduled(fixedDelayString = "${payment.khqr.poll-interval-ms:5000}")
    public void run() {
        try {
            int settled = paymentService.reconcilePending();
            if (settled > 0) {
                log.info("KHQR reconciler confirmed {} payment(s)", settled);
            }
        } catch (RuntimeException ex) {
            log.error("KHQR reconciliation failed: {}", ex.getMessage());
        }
    }
}
