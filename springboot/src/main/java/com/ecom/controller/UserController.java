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
@RequestMapping("/api/v1/users/me")
@RequiredArgsConstructor
@Tag(name = "Profile")
public class UserController {
    private final UserService userService;

    @GetMapping
    public ApiResponse<UserResponse> me(@AuthenticationPrincipal UserPrincipal me) {
        return ApiResponse.ok(userService.me(me.getId()));
    }

    @PutMapping
    public ApiResponse<UserResponse> update(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody UpdateProfileRequest request) {
        return ApiResponse.ok("Profile updated", userService.updateProfile(me.getId(), request));
    }

    @PutMapping("/password")
    public ApiResponse<Void> changePassword(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody ChangePasswordRequest request) {
        userService.changePassword(me.getId(), request);
        return ApiResponse.ok("Password changed", null);
    }

    @GetMapping("/addresses")
    public ApiResponse<List<AddressResponse>> addresses(@AuthenticationPrincipal UserPrincipal me) {
        return ApiResponse.ok(userService.addresses(me.getId()));
    }

    @PostMapping("/addresses")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<AddressResponse> addAddress(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody AddressRequest request) {
        return ApiResponse.ok("Address added", userService.addAddress(me.getId(), request));
    }

    @PutMapping("/addresses/{id}")
    public ApiResponse<AddressResponse> updateAddress(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                                      @Valid @RequestBody AddressRequest request) {
        return ApiResponse.ok("Address updated", userService.updateAddress(me.getId(), id, request));
    }

    @DeleteMapping("/addresses/{id}")
    public ApiResponse<Void> deleteAddress(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        userService.deleteAddress(me.getId(), id);
        return ApiResponse.ok("Address deleted", null);
    }

    @PatchMapping("/addresses/{id}/default")
    public ApiResponse<AddressResponse> setDefault(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return ApiResponse.ok("Default address updated", userService.setDefaultAddress(me.getId(), id));
    }
}
