package com.ecom.service;

import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface ProductService {
    PageResponse<ProductResponse> search(ProductSearchCriteria criteria);

    ProductResponse getById(Long id);

    ProductResponse getBySlug(String slug);

    PageResponse<ProductResponse> adminSearch(ProductSearchCriteria criteria);

    ProductResponse adminGet(Long id);

    ProductResponse create(ProductRequest request, Long actorId);

    ProductResponse update(Long id, ProductRequest request, Long actorId);

    void delete(Long id);

    ProductResponse setActive(Long id, boolean active);
}
