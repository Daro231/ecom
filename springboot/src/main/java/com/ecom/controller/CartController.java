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
@RequestMapping("/api/v1/cart")
@RequiredArgsConstructor
@Tag(name = "Cart")
public class CartController {
    private final CartService cartService;

    @GetMapping
    public ApiResponse<CartResponse> get(@AuthenticationPrincipal UserPrincipal me) {
        return ApiResponse.ok(cartService.get(me.getId()));
    }

    @PostMapping("/items")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<CartResponse> add(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody CartItemRequest request) {
        return ApiResponse.ok("Item added to cart", cartService.addItem(me.getId(), request));
    }

    @PutMapping("/items/{itemId}")
    public ApiResponse<CartResponse> update(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long itemId,
                                            @Valid @RequestBody UpdateCartItemRequest request) {
        return ApiResponse.ok("Cart updated", cartService.updateItem(me.getId(), itemId, request));
    }

    @DeleteMapping("/items/{itemId}")
    public ApiResponse<CartResponse> remove(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long itemId) {
        return ApiResponse.ok("Item removed", cartService.removeItem(me.getId(), itemId));
    }

    @DeleteMapping
    public ApiResponse<CartResponse> clear(@AuthenticationPrincipal UserPrincipal me) {
        return ApiResponse.ok("Cart cleared", cartService.clear(me.getId()));
    }

    @PostMapping("/apply-coupon")
    public ApiResponse<CartPreviewResponse> applyCoupon(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody ApplyCouponRequest request) {
        return ApiResponse.ok("Coupon applied", cartService.applyCoupon(me.getId(), request));
    }
}
