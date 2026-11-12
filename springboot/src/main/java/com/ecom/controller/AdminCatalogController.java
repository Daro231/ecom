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
@Tag(name = "Admin - Catalog")
public class AdminCatalogController {
    private final ProductService productService;
    private final CategoryService categoryService;
    private final BrandService brandService;

    @GetMapping("/products")
    public ApiResponse<PageResponse<ProductResponse>> products(
            @RequestParam(required = false) String keyword, @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long brandId, @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(productService.adminSearch(new ProductSearchCriteria(keyword, categoryId, brandId, null, null,
                null, null, null, sort, page, size)));
    }

    @GetMapping("/products/{id}")
    public ApiResponse<ProductResponse> product(@PathVariable Long id) {
        return ApiResponse.ok(productService.adminGet(id));
    }

    @PostMapping("/products")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ProductResponse> create(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody ProductRequest request) {
        return ApiResponse.ok("Product created", productService.create(request, me.getId()));
    }

    @PutMapping("/products/{id}")
    public ApiResponse<ProductResponse> update(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                               @Valid @RequestBody ProductRequest request) {
        return ApiResponse.ok("Product updated", productService.update(id, request, me.getId()));
    }

    @DeleteMapping("/products/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        productService.delete(id);
        return ApiResponse.ok("Product deleted", null);
    }

    @PatchMapping("/products/{id}/active")
    public ApiResponse<ProductResponse> active(@PathVariable Long id, @RequestParam boolean value) {
        return ApiResponse.ok("Product updated", productService.setActive(id, value));
    }

    @PostMapping("/categories")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<CategoryResponse> createCategory(@Valid @RequestBody CategoryRequest request) {
        return ApiResponse.ok("Category created", categoryService.create(request));
    }

    @PutMapping("/categories/{id}")
    public ApiResponse<CategoryResponse> updateCategory(@PathVariable Long id, @Valid @RequestBody CategoryRequest request) {
        return ApiResponse.ok("Category updated", categoryService.update(id, request));
    }

    @DeleteMapping("/categories/{id}")
    public ApiResponse<Void> deleteCategory(@PathVariable Long id) {
        categoryService.delete(id);
        return ApiResponse.ok("Category deleted", null);
    }

    @PostMapping("/brands")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<BrandResponse> createBrand(@Valid @RequestBody BrandRequest request) {
        return ApiResponse.ok("Brand created", brandService.create(request));
    }

    @PutMapping("/brands/{id}")
    public ApiResponse<BrandResponse> updateBrand(@PathVariable Long id, @Valid @RequestBody BrandRequest request) {
        return ApiResponse.ok("Brand updated", brandService.update(id, request));
    }

    @DeleteMapping("/brands/{id}")
    public ApiResponse<Void> deleteBrand(@PathVariable Long id) {
        brandService.delete(id);
        return ApiResponse.ok("Brand deleted", null);
    }
}
