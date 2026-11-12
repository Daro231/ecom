package com.ecom.service;

import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface CartService {
    CartResponse get(Long userId);

    CartResponse addItem(Long userId, CartItemRequest request);

    CartResponse updateItem(Long userId, Long itemId, UpdateCartItemRequest request);

    CartResponse removeItem(Long userId, Long itemId);

    CartResponse clear(Long userId);

    CartPreviewResponse applyCoupon(Long userId, ApplyCouponRequest request);
}
