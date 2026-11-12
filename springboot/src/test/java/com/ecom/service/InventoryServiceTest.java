package com.ecom.service;

import com.ecom.common.exception.BadRequestException;
import com.ecom.common.exception.InsufficientStockException;
import com.ecom.common.exception.ResourceNotFoundException;
import com.ecom.model.entity.InventoryLog;
import com.ecom.model.entity.Product;
import com.ecom.model.enumerate.InventoryReason;
import com.ecom.model.enumerate.NotificationType;
import com.ecom.model.response.InventoryResponse;
import com.ecom.repository.InventoryLogRepository;
import com.ecom.repository.ProductRepository;
import com.ecom.service.impl.InventoryServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class InventoryServiceTest {
    @Mock
    ProductRepository productRepository;
    @Mock
    InventoryLogRepository inventoryLogRepository;
    @Mock
    NotificationService notificationService;
    @InjectMocks
    InventoryServiceImpl inventoryService;

    Product product;

    @BeforeEach
    void setUp() {
        product = TestData.product(5, "100.00", 3);
    }

    @Test
    void restockIncreasesStockAndWritesLog() {
        when(productRepository.findById(5L)).thenReturn(Optional.of(product));

        InventoryResponse response = inventoryService.restock(5L, 10, "supplier delivery", 99L);

        assertThat(response.stockQuantity()).isEqualTo(13);
        ArgumentCaptor<InventoryLog> captor = ArgumentCaptor.forClass(InventoryLog.class);
        verify(inventoryLogRepository).save(captor.capture());
        InventoryLog log = captor.getValue();
        assertThat(log.getChangeQuantity()).isEqualTo(10);
        assertThat(log.getReason()).isEqualTo(InventoryReason.RESTOCK);
        assertThat(log.getStockAfter()).isEqualTo(13);
        assertThat(log.getCreatedBy()).isEqualTo(99L);
        assertThat(log.getNote()).isEqualTo("supplier delivery");
        verifyNoInteractions(notificationService);
    }

    @Test
    void deductionBelowThresholdNotifiesAdmins() {
        inventoryService.applyChange(product, -1, InventoryReason.ORDER, 1L, "order");

        assertThat(product.getStockQuantity()).isEqualTo(2);
        verify(notificationService).notifyAdmins(eq(NotificationType.EMAIL), contains("Low stock"), contains("2 unit"));
    }

    @Test
    void deductionAboveThresholdDoesNotNotify() {
        product.setStockQuantity(10);

        inventoryService.applyChange(product, -2, InventoryReason.ORDER, 1L, "order");

        verifyNoInteractions(notificationService);
    }

    @Test
    void cancelRestoreNeverTriggersLowStockAlert() {
        product.setStockQuantity(0);

        inventoryService.applyChange(product, 1, InventoryReason.CANCEL, 1L, "restore");

        verifyNoInteractions(notificationService);
        assertThat(product.getStockQuantity()).isEqualTo(1);
    }

    @Test
    void stockCannotGoNegative() {
        assertThatThrownBy(() -> inventoryService.applyChange(product, -4, InventoryReason.ORDER, 1L, "x"))
                .isInstanceOf(InsufficientStockException.class);
        assertThat(product.getStockQuantity()).isEqualTo(3);
        verify(inventoryLogRepository, never()).save(any());
    }

    @Test
    void adjustAppliesSignedDeltaAndRejectsZero() {
        when(productRepository.findById(5L)).thenReturn(Optional.of(product));

        assertThat(inventoryService.adjust(5L, -1, "damaged", 1L).stockQuantity()).isEqualTo(2);
        assertThatThrownBy(() -> inventoryService.adjust(5L, 0, "nothing", 1L)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void unknownProductIsNotFound() {
        when(productRepository.findById(404L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> inventoryService.restock(404L, 1, null, 1L)).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> inventoryService.logs(404L, 0, 10)).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void listLowStockAndLogsAreMapped() {
        when(productRepository.findLowStock()).thenReturn(List.of(product));
        when(productRepository.searchInventory(anyString(), any(Pageable.class))).thenReturn(new PageImpl<>(List.of(product)));
        when(productRepository.findById(5L)).thenReturn(Optional.of(product));
        InventoryLog log = InventoryLog.builder().product(product).changeQuantity(5).reason(InventoryReason.RESTOCK).stockAfter(8).build();
        when(inventoryLogRepository.findByProductId(eq(5L), any(Pageable.class))).thenReturn(new PageImpl<>(List.of(log)));

        assertThat(inventoryService.lowStock()).hasSize(1).first().extracting(InventoryResponse::lowStock).isEqualTo(false);
        assertThat(inventoryService.list(null, 0, 10).content()).hasSize(1);
        assertThat(inventoryService.logs(5L, 0, 10).content().get(0).stockAfter()).isEqualTo(8);
    }
}
