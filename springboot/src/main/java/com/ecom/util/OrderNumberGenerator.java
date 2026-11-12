package com.ecom.util;

import com.ecom.common.constant.AppConstants;
import com.ecom.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/** Produces numbers like ECOM-20261025-0001; the daily counter is seeded from the database. */
@Component
@RequiredArgsConstructor
public class OrderNumberGenerator {
    private static final DateTimeFormatter DAY = DateTimeFormatter.ofPattern("yyyyMMdd");

    private final OrderRepository orderRepository;
    private LocalDate currentDay;
    private int counter;

    /**
     * The in-memory counter keeps numbers unique between transactions of this instance that have not committed yet;
     * re-reading the committed count on every call also keeps several instances (or Spring contexts) in step.
     */
    public synchronized String next() {
        LocalDate today = LocalDate.now();
        String prefix = AppConstants.ORDER_NUMBER_PREFIX + today.format(DAY) + "-";
        if (!today.equals(currentDay)) {
            currentDay = today;
            counter = 0;
        }
        counter = Math.max(counter, (int) orderRepository.countByOrderNumberStartingWith(prefix)) + 1;
        while (orderRepository.existsByOrderNumber(prefix + String.format("%04d", counter))) {
            counter++;
        }
        return prefix + String.format("%04d", counter);
    }
}
