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
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@Tag(name = "Payments & Shipping")
public class PaymentController {
    private final PaymentService paymentService;
    private final ShippingService shippingService;

    @PostMapping("/payments/{orderNumber}/khqr")
    public ApiResponse<KhqrResponse> khqr(@AuthenticationPrincipal UserPrincipal me, @PathVariable String orderNumber) {
        return ApiResponse.ok("KHQR generated", paymentService.generateKhqr(me.getId(), orderNumber));
    }

    @GetMapping("/payments/{orderNumber}/status")
    public ApiResponse<PaymentResponse> status(@AuthenticationPrincipal UserPrincipal me, @PathVariable String orderNumber) {
        return ApiResponse.ok(paymentService.status(me.getId(), orderNumber));
    }

    @PostMapping("/payments/callback")
    public ApiResponse<PaymentResponse> callback(@Valid @RequestBody PaymentCallbackRequest request) {
        return ApiResponse.ok("Callback processed", paymentService.callback(request));
    }

    @GetMapping("/shipping/methods")
    public ApiResponse<List<ShippingMethodResponse>> shippingMethods() {
        return ApiResponse.ok(shippingService.methods());
    }
}
