package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record DashboardResponse(BigDecimal totalSales, long totalOrders, Map<OrderStatus, Long> ordersByStatus,
                                long totalCustomers, List<TopProductResponse> topProducts, long lowStockCount) {
}
