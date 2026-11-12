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
@RequestMapping("/api/v1/admin/payments")
@RequiredArgsConstructor
@Tag(name = "Admin - Payments")
public class AdminPaymentController {
    private final PaymentService paymentService;

    @GetMapping
    public ApiResponse<PageResponse<PaymentResponse>> list(@RequestParam(required = false) PaymentStatus status,
                                                           @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(paymentService.adminList(status, page, size));
    }

    @PostMapping("/{orderNumber}/recheck")
    public ApiResponse<PaymentResponse> recheck(@PathVariable String orderNumber) {
        return ApiResponse.ok("Payment re-checked", paymentService.recheck(orderNumber));
    }

    /** {idOrOrderNumber} is the payment id (as before) or the order number. */
    @PostMapping("/{idOrOrderNumber}/refund")
    public ApiResponse<PaymentResponse> refund(@PathVariable String idOrOrderNumber) {
        return ApiResponse.ok("Payment refunded", paymentService.refund(idOrOrderNumber));
    }
}
