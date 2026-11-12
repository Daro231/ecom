package com.ecom.service;

import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface ReviewService {
    PageResponse<ReviewResponse> listForProduct(Long productId, int page, int size);

    ReviewResponse create(Long userId, Long productId, ReviewRequest request);

    ReviewResponse update(Long userId, Long reviewId, ReviewRequest request);

    void delete(Long userId, Long reviewId);

    PageResponse<ReviewResponse> adminList(int page, int size);

    ReviewResponse setVisibility(Long reviewId, boolean visible);

    void adminDelete(Long reviewId);
}
