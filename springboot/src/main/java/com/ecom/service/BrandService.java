package com.ecom.service;

import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface BrandService {
    List<BrandResponse> findAll();

    BrandResponse create(BrandRequest request);

    BrandResponse update(Long id, BrandRequest request);

    void delete(Long id);
}
