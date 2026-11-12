package com.ecom.service.impl;

import com.ecom.common.constant.AppConstants;
import com.ecom.common.exception.*;
import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;
import com.ecom.repository.*;
import com.ecom.service.*;
import com.ecom.util.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReportServiceImpl implements ReportService {
    private static final List<OrderStatus> NOT_SALES = List.of(OrderStatus.CANCELLED, OrderStatus.PENDING);

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final UserRepository userRepository;
    private final ProductRepository productRepository;

    @Override
    @Transactional(readOnly = true)
    public DashboardResponse dashboard() {
        Map<OrderStatus, Long> byStatus = new EnumMap<>(OrderStatus.class);
        long totalOrders = 0;
        for (OrderStatus status : OrderStatus.values()) {
            long count = orderRepository.countByStatus(status);
            byStatus.put(status, count);
            totalOrders += count;
        }
        List<TopProductResponse> top = orderItemRepository.topSelling(OrderStatus.CANCELLED, PageRequest.of(0, 5)).stream()
                .map(row -> new TopProductResponse((Long) row[0], (String) row[1], ((Number) row[2]).longValue())).toList();
        return new DashboardResponse(MoneyUtil.scale(orderRepository.sumTotalExcluding(NOT_SALES)), totalOrders, byStatus,
                userRepository.countByRole(Role.CUSTOMER), top, productRepository.countLowStock());
    }

    @Override
    @Transactional(readOnly = true)
    public List<SalesPointResponse> sales(LocalDate from, LocalDate to) {
        if (from == null || to == null || to.isBefore(from)) {
            throw new BadRequestException("A valid from/to date range is required");
        }
        Map<LocalDate, List<Order>> byDay = orderRepository.findForSales(from.atStartOfDay(), to.plusDays(1).atStartOfDay(), NOT_SALES)
                .stream().collect(Collectors.groupingBy(o -> o.getCreatedAt().toLocalDate()));
        List<SalesPointResponse> points = new ArrayList<>();
        for (LocalDate day = from; !day.isAfter(to); day = day.plusDays(1)) {
            List<Order> orders = byDay.getOrDefault(day, List.of());
            BigDecimal revenue = orders.stream().map(Order::getTotal).reduce(BigDecimal.ZERO, BigDecimal::add);
            points.add(new SalesPointResponse(day, orders.size(), MoneyUtil.scale(revenue)));
        }
        return points;
    }
}
