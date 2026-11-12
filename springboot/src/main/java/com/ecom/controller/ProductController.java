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
@Tag(name = "Catalog")
public class ProductController {
    private final ProductService productService;
    private final CategoryService categoryService;
    private final BrandService brandService;

    @GetMapping("/products")
    public ApiResponse<PageResponse<ProductResponse>> search(
            @RequestParam(required = false) String keyword, @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long brandId, @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice, @RequestParam(required = false) Integer ram,
            @RequestParam(required = false) Double minRating, @RequestParam(required = false) Boolean inStock,
            @RequestParam(required = false) String sort, @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size) {
        return ApiResponse.ok(productService.search(new ProductSearchCriteria(keyword, categoryId, brandId, minPrice,
                maxPrice, ram, minRating, inStock, sort, page, size)));
    }

    @GetMapping("/products/{id}")
    public ApiResponse<ProductResponse> byId(@PathVariable Long id) {
        return ApiResponse.ok(productService.getById(id));
    }

    @GetMapping("/products/slug/{slug}")
    public ApiResponse<ProductResponse> bySlug(@PathVariable String slug) {
        return ApiResponse.ok(productService.getBySlug(slug));
    }

    @GetMapping("/categories")
    public ApiResponse<List<CategoryResponse>> categories() {
        return ApiResponse.ok(categoryService.findAll());
    }

    @GetMapping("/brands")
    public ApiResponse<List<BrandResponse>> brands() {
        return ApiResponse.ok(brandService.findAll());
    }
}
