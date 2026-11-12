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
@RequestMapping("/api/v1/admin/users")
@RequiredArgsConstructor
@Tag(name = "Admin - Users")
public class AdminUserController {
    private final UserService userService;

    @GetMapping
    public ApiResponse<PageResponse<UserResponse>> list(@RequestParam(required = false) String keyword,
                                                        @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(userService.search(keyword, page, size));
    }

    @PatchMapping("/{id}/role")
    public ApiResponse<UserResponse> role(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id, @Valid @RequestBody RoleRequest request) {
        return ApiResponse.ok("Role updated", userService.changeRole(me.getId(), id, request.role()));
    }

    @PatchMapping("/{id}/enabled")
    public ApiResponse<UserResponse> enabled(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id, @Valid @RequestBody EnabledRequest request) {
        return ApiResponse.ok("Account updated", userService.setEnabled(me.getId(), id, request.enabled()));
    }
}
