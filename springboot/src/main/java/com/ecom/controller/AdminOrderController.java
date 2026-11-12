package com.ecom.controller;

import com.ecom.common.response.ApiResponse;
import com.ecom.common.response.PageResponse;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;
import com.ecom.security.UserPrincipal;
import com.ecom.service.*;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@Tag(name = "Admin - Orders & Shipping")
public class AdminOrderController {
    private final OrderService orderService;
    private final ShippingService shippingService;

    @GetMapping("/orders")
    public ApiResponse<PageResponse<OrderResponse>> list(
            @RequestParam(required = false) OrderStatus status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) String keyword, @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(orderService.adminSearch(status, from, to, keyword, page, size));
    }

    @GetMapping("/orders/{orderNumber}")
    public ApiResponse<OrderResponse> get(@PathVariable String orderNumber) {
        return ApiResponse.ok(orderService.adminGet(orderNumber));
    }

    @PatchMapping("/orders/{orderNumber}/status")
    public ApiResponse<OrderResponse> status(@PathVariable String orderNumber, @Valid @RequestBody OrderStatusRequest request) {
        return ApiResponse.ok("Order status updated", orderService.adminChangeStatus(orderNumber, request.status(), request.reason()));
    }

    /** Customer paid after the order was auto-cancelled: re-reserve stock and reopen the order (409 if out of stock). */
    @PostMapping("/orders/{orderNumber}/restore-after-payment")
    public ApiResponse<OrderResponse> restoreAfterPayment(@PathVariable String orderNumber) {
        return ApiResponse.ok("Order restored", orderService.restoreAfterPayment(orderNumber));
    }

    @PatchMapping("/orders/{orderNumber}/ship")
    public ApiResponse<OrderResponse> ship(@PathVariable String orderNumber, @Valid @RequestBody ShipRequest request) {
        return ApiResponse.ok("Order shipped", orderService.ship(orderNumber, request.trackingNumber()));
    }

    @PatchMapping("/shipments/{id}/status")
    public ApiResponse<ShipmentResponse> shipmentStatus(@PathVariable Long id, @Valid @RequestBody ShipmentStatusRequest request) {
        return ApiResponse.ok("Shipment updated", shippingService.updateShipmentStatus(id, request.status()));
    }
}
