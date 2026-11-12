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
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@Tag(name = "Admin - Reports & Uploads")
public class AdminReportController {
    private final ReportService reportService;
    private final FileStorageService fileStorageService;

    @GetMapping("/reports/dashboard")
    public ApiResponse<DashboardResponse> dashboard() {
        return ApiResponse.ok(reportService.dashboard());
    }

    @GetMapping("/reports/sales")
    public ApiResponse<List<SalesPointResponse>> sales(@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                                       @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ApiResponse.ok(reportService.sales(from, to));
    }

    @PostMapping(value = "/uploads", consumes = "multipart/form-data")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<UploadResponse> upload(@RequestPart("file") org.springframework.web.multipart.MultipartFile file) {
        return ApiResponse.ok("File uploaded", fileStorageService.store(file));
    }
}
