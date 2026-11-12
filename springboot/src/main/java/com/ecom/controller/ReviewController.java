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
@Tag(name = "Reviews")
public class ReviewController {
    private final ReviewService reviewService;

    @GetMapping("/products/{id}/reviews")
    public ApiResponse<PageResponse<ReviewResponse>> list(@PathVariable Long id, @RequestParam(defaultValue = "0") int page,
                                                          @RequestParam(defaultValue = "10") int size) {
        return ApiResponse.ok(reviewService.listForProduct(id, page, size));
    }

    @PostMapping("/products/{id}/reviews")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ReviewResponse> create(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                              @Valid @RequestBody ReviewRequest request) {
        return ApiResponse.ok("Review submitted", reviewService.create(me.getId(), id, request));
    }

    @PutMapping("/reviews/{reviewId}")
    public ApiResponse<ReviewResponse> update(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long reviewId,
                                              @Valid @RequestBody ReviewRequest request) {
        return ApiResponse.ok("Review updated", reviewService.update(me.getId(), reviewId, request));
    }

    @DeleteMapping("/reviews/{reviewId}")
    public ApiResponse<Void> delete(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long reviewId) {
        reviewService.delete(me.getId(), reviewId);
        return ApiResponse.ok("Review deleted", null);
    }
}
