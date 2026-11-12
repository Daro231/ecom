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
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
@Tag(name = "Notifications")
public class NotificationController {
    private final NotificationService notificationService;

    @GetMapping
    public ApiResponse<PageResponse<NotificationResponse>> list(@AuthenticationPrincipal UserPrincipal me,
                                                                @RequestParam(defaultValue = "0") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(notificationService.list(me.getId(), page, size));
    }

    @GetMapping("/unread-count")
    public ApiResponse<Long> unreadCount(@AuthenticationPrincipal UserPrincipal me) {
        return ApiResponse.ok(notificationService.unreadCount(me.getId()));
    }

    @PatchMapping("/read-all")
    public ApiResponse<Integer> readAll(@AuthenticationPrincipal UserPrincipal me) {
        return ApiResponse.ok("All notifications marked as read", notificationService.markAllRead(me.getId()));
    }

    @PatchMapping("/{id}/read")
    public ApiResponse<NotificationResponse> read(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return ApiResponse.ok(notificationService.markRead(me.getId(), id));
    }
}
