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
@RequestMapping("/api/v1/admin/reviews")
@RequiredArgsConstructor
@Tag(name = "Admin - Reviews")
public class AdminReviewController {
    private final ReviewService reviewService;

    @GetMapping
    public ApiResponse<PageResponse<ReviewResponse>> list(@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(reviewService.adminList(page, size));
    }

    @PatchMapping("/{id}/visibility")
    public ApiResponse<ReviewResponse> visibility(@PathVariable Long id, @Valid @RequestBody VisibilityRequest request) {
        return ApiResponse.ok("Review updated", reviewService.setVisibility(id, request.visible()));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        reviewService.adminDelete(id);
        return ApiResponse.ok("Review deleted", null);
    }
}
