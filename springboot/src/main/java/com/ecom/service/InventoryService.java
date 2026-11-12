package com.ecom.service;

import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface InventoryService {
    /** Changes stock by delta, writing an inventory log and raising a low-stock alert after deductions. */
    void applyChange(Product product, int delta, InventoryReason reason, Long actorId, String note);

    PageResponse<InventoryResponse> list(String keyword, int page, int size);

    List<InventoryResponse> lowStock();

    InventoryResponse restock(Long productId, int quantity, String note, Long actorId);

    InventoryResponse adjust(Long productId, int delta, String note, Long actorId);

    PageResponse<InventoryLogResponse> logs(Long productId, int page, int size);
}
