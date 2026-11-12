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
@RequestMapping("/api/v1/admin/inventory")
@RequiredArgsConstructor
@Tag(name = "Admin - Inventory")
public class AdminInventoryController {
    private final InventoryService inventoryService;

    @GetMapping
    public ApiResponse<PageResponse<InventoryResponse>> list(@RequestParam(required = false) String keyword,
                                                             @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(inventoryService.list(keyword, page, size));
    }

    @GetMapping("/low-stock")
    public ApiResponse<List<InventoryResponse>> lowStock() {
        return ApiResponse.ok(inventoryService.lowStock());
    }

    @PostMapping("/{productId}/restock")
    public ApiResponse<InventoryResponse> restock(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long productId,
                                                  @Valid @RequestBody RestockRequest request) {
        return ApiResponse.ok("Stock added", inventoryService.restock(productId, request.quantity(), request.note(), me.getId()));
    }

    @PostMapping("/{productId}/adjust")
    public ApiResponse<InventoryResponse> adjust(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long productId,
                                                 @Valid @RequestBody AdjustStockRequest request) {
        return ApiResponse.ok("Stock adjusted", inventoryService.adjust(productId, request.delta(), request.note(), me.getId()));
    }

    @GetMapping("/{productId}/logs")
    public ApiResponse<PageResponse<InventoryLogResponse>> logs(@PathVariable Long productId, @RequestParam(defaultValue = "0") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(inventoryService.logs(productId, page, size));
    }
}
