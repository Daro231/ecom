package com.ecom.service.impl;

import com.ecom.common.constant.AppConstants;
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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InventoryServiceImpl implements InventoryService {
    private final ProductRepository productRepository;
    private final InventoryLogRepository inventoryLogRepository;
    private final NotificationService notificationService;

    @Override
    @Transactional
    public void applyChange(Product product, int delta, InventoryReason reason, Long actorId, String note) {
        int newStock = product.getStockQuantity() + delta;
        if (newStock < 0) {
            throw new InsufficientStockException("Insufficient stock for " + product.getName() + ": available "
                    + product.getStockQuantity() + ", requested " + Math.abs(delta));
        }
        product.setStockQuantity(newStock);
        productRepository.save(product);
        inventoryLogRepository.save(InventoryLog.builder().product(product).changeQuantity(delta).reason(reason)
                .stockAfter(newStock).createdBy(actorId).note(note).build());
        if (delta < 0 && newStock <= product.getLowStockThreshold()) {
            notificationService.notifyAdmins(NotificationType.EMAIL, "Low stock: " + product.getName(),
                    product.getName() + " (" + product.getSku() + ") has only " + newStock + " unit(s) left.");
        }
    }

    private Product find(Long id) {
        return productRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Product not found"));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<InventoryResponse> list(String keyword, int page, int size) {
        String kw = "%" + (keyword == null ? "" : keyword.trim().toLowerCase()) + "%";
        return PageResponse.of(productRepository.searchInventory(kw, PageUtil.of(page, size, Sort.by("name"))), InventoryResponse::from);
    }

    @Override
    @Transactional(readOnly = true)
    public List<InventoryResponse> lowStock() {
        return productRepository.findLowStock().stream().map(InventoryResponse::from).toList();
    }

    @Override
    @Transactional
    public InventoryResponse restock(Long productId, int quantity, String note, Long actorId) {
        Product product = find(productId);
        applyChange(product, quantity, InventoryReason.RESTOCK, actorId, note);
        return InventoryResponse.from(product);
    }

    @Override
    @Transactional
    public InventoryResponse adjust(Long productId, int delta, String note, Long actorId) {
        if (delta == 0) {
            throw new BadRequestException("Adjustment must not be zero");
        }
        Product product = find(productId);
        applyChange(product, delta, InventoryReason.ADJUST, actorId, note);
        return InventoryResponse.from(product);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<InventoryLogResponse> logs(Long productId, int page, int size) {
        find(productId);
        return PageResponse.of(inventoryLogRepository.findByProductId(productId, PageUtil.newestFirst(page, size)), InventoryLogResponse::from);
    }
}
