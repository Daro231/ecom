package com.ecom.service.impl;

import com.ecom.common.exception.*;
import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;
import com.ecom.repository.*;
import com.ecom.service.*;
import com.ecom.util.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class ProductServiceImpl implements ProductService {
    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final BrandRepository brandRepository;
    private final CartItemRepository cartItemRepository;
    private final OrderItemRepository orderItemRepository;
    private final ReviewRepository reviewRepository;
    private final InventoryLogRepository inventoryLogRepository;
    private final InventoryService inventoryService;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ProductResponse> search(ProductSearchCriteria c) {
        return doSearch(c, true);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ProductResponse> adminSearch(ProductSearchCriteria c) {
        return doSearch(c, false);
    }

    private PageResponse<ProductResponse> doSearch(ProductSearchCriteria c, boolean onlyActive) {
        Specification<Product> spec = ProductSpecifications.search(c.keyword(), c.categoryId(), c.brandId(), c.minPrice(),
                c.maxPrice(), c.ram(), c.minRating(), c.inStock(), onlyActive);
        return PageResponse.of(productRepository.findAll(spec, PageUtil.of(c.page(), c.size(), sortFor(c.sort()))), ProductResponse::from);
    }

    private Sort sortFor(String sort) {
        String key = sort == null ? "newest" : sort.toLowerCase();
        return switch (key) {
            case "price_asc" -> Sort.by(Sort.Order.asc("price"), Sort.Order.desc("id"));
            case "price_desc" -> Sort.by(Sort.Order.desc("price"), Sort.Order.desc("id"));
            case "rating" -> Sort.by(Sort.Order.desc("averageRating"), Sort.Order.desc("reviewCount"), Sort.Order.desc("id"));
            case "popular" -> Sort.by(Sort.Order.desc("soldCount"), Sort.Order.desc("id"));
            default -> Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"));
        };
    }

    @Override
    @Transactional(readOnly = true)
    public ProductResponse getById(Long id) {
        Product product = productRepository.findById(id).filter(Product::isActive)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found"));
        return ProductResponse.from(product);
    }

    @Override
    @Transactional(readOnly = true)
    public ProductResponse getBySlug(String slug) {
        return ProductResponse.from(productRepository.findBySlugAndActiveTrue(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found")));
    }

    @Override
    @Transactional(readOnly = true)
    public ProductResponse adminGet(Long id) {
        return ProductResponse.from(find(id));
    }

    private Product find(Long id) {
        return productRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Product not found"));
    }

    @Override
    @Transactional
    public ProductResponse create(ProductRequest r, Long actorId) {
        if (productRepository.existsBySku(r.sku().trim())) {
            throw new ConflictException("SKU already exists");
        }
        Product product = Product.builder().sku(r.sku().trim()).name(r.name().trim())
                .slug(SlugUtil.uniqueSlug(r.name(), productRepository::existsBySlug))
                .price(MoneyUtil.scale(r.price()))
                .category(category(r.categoryId())).brand(brand(r.brandId()))
                .stockQuantity(0).build();
        copy(product, r);
        Product saved = productRepository.save(product);
        if (r.stockQuantity() > 0) {
            inventoryService.applyChange(saved, r.stockQuantity(), InventoryReason.RESTOCK, actorId, "Initial stock");
        }
        return ProductResponse.from(saved);
    }

    @Override
    @Transactional
    public ProductResponse update(Long id, ProductRequest r, Long actorId) {
        Product product = find(id);
        if (!product.getSku().equals(r.sku().trim()) && productRepository.existsBySku(r.sku().trim())) {
            throw new ConflictException("SKU already exists");
        }
        product.setSku(r.sku().trim());
        if (!product.getName().equals(r.name().trim())) {
            product.setName(r.name().trim());
            product.setSlug(SlugUtil.uniqueSlug(r.name(), s -> !s.equals(product.getSlug()) && productRepository.existsBySlug(s)));
        }
        product.setPrice(MoneyUtil.scale(r.price()));
        product.setCategory(category(r.categoryId()));
        product.setBrand(brand(r.brandId()));
        copy(product, r);
        int delta = r.stockQuantity() - product.getStockQuantity();
        if (delta != 0) {
            inventoryService.applyChange(product, delta, InventoryReason.ADJUST, actorId, "Adjusted via product update");
        }
        return ProductResponse.from(product);
    }

    private void copy(Product p, ProductRequest r) {
        p.setDescription(r.description());
        p.setCpu(r.cpu());
        p.setRam(r.ram());
        p.setStorage(r.storage());
        p.setGpu(r.gpu());
        p.setScreenSize(r.screenSize());
        p.setOs(r.os());
        p.setWarrantyMonths(r.warrantyMonths());
        if (r.lowStockThreshold() != null) {
            p.setLowStockThreshold(r.lowStockThreshold());
        }
        if (r.active() != null) {
            p.setActive(r.active());
        }
        if (r.imageUrls() != null) {
            p.getImages().clear();
            int order = 0;
            for (String url : r.imageUrls()) {
                p.getImages().add(ProductImage.builder().product(p).imageUrl(url).sortOrder(order++).build());
            }
        }
    }

    private Category category(Long id) {
        return categoryRepository.findById(id).orElseThrow(() -> new BadRequestException("Category does not exist"));
    }

    private Brand brand(Long id) {
        return brandRepository.findById(id).orElseThrow(() -> new BadRequestException("Brand does not exist"));
    }

    @Override
    @Transactional
    public void delete(Long id) {
        Product product = find(id);
        if (orderItemRepository.existsByProductId(id)) {
            throw new ConflictException("Product has been ordered and cannot be deleted; deactivate it instead");
        }
        cartItemRepository.deleteByProductId(id);
        reviewRepository.deleteByProductId(id);
        inventoryLogRepository.deleteByProductId(id);
        productRepository.delete(product);
    }

    @Override
    @Transactional
    public ProductResponse setActive(Long id, boolean active) {
        Product product = find(id);
        product.setActive(active);
        return ProductResponse.from(product);
    }
}
