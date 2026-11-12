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
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
@Tag(name = "Orders")
public class OrderController {
    private final OrderService orderService;
    private final ShippingService shippingService;

    @PostMapping("/checkout")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<OrderResponse> checkout(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody CheckoutRequest request) {
        return ApiResponse.ok("Order placed", orderService.checkout(me.getId(), request));
    }

    @GetMapping
    public ApiResponse<PageResponse<OrderResponse>> mine(@AuthenticationPrincipal UserPrincipal me, @RequestParam(defaultValue = "0") int page,
                                                         @RequestParam(defaultValue = "10") int size) {
        return ApiResponse.ok(orderService.myOrders(me.getId(), page, size));
    }

    @GetMapping("/{orderNumber}")
    public ApiResponse<OrderResponse> get(@AuthenticationPrincipal UserPrincipal me, @PathVariable String orderNumber) {
        return ApiResponse.ok(orderService.getMyOrder(me.getId(), orderNumber));
    }

    @PostMapping("/{orderNumber}/cancel")
    public ApiResponse<OrderResponse> cancel(@AuthenticationPrincipal UserPrincipal me, @PathVariable String orderNumber,
                                             @Valid @RequestBody CancelOrderRequest request) {
        return ApiResponse.ok("Order cancelled", orderService.cancel(me.getId(), orderNumber, request.reason()));
    }

    @GetMapping("/{orderNumber}/invoice")
    public ApiResponse<InvoiceResponse> invoice(@AuthenticationPrincipal UserPrincipal me, @PathVariable String orderNumber) {
        return ApiResponse.ok(orderService.invoice(me.getId(), orderNumber));
    }

    @GetMapping("/{orderNumber}/tracking")
    public ApiResponse<ShipmentResponse> tracking(@AuthenticationPrincipal UserPrincipal me, @PathVariable String orderNumber) {
        return ApiResponse.ok(shippingService.tracking(me.getId(), orderNumber));
    }
}
