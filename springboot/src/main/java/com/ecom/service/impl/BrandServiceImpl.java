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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class BrandServiceImpl implements BrandService {
    private final BrandRepository brandRepository;
    private final ProductRepository productRepository;

    @Override
    @Transactional(readOnly = true)
    public List<BrandResponse> findAll() {
        return brandRepository.findAll(Sort.by("name")).stream().map(BrandResponse::from).toList();
    }

    @Override
    @Transactional
    public BrandResponse create(BrandRequest request) {
        if (brandRepository.existsByNameIgnoreCase(request.name().trim())) {
            throw new ConflictException("Brand already exists");
        }
        Brand brand = Brand.builder().name(request.name().trim()).slug(SlugUtil.slugify(request.name())).build();
        return BrandResponse.from(brandRepository.save(brand));
    }

    @Override
    @Transactional
    public BrandResponse update(Long id, BrandRequest request) {
        Brand brand = brandRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Brand not found"));
        if (brandRepository.existsByNameIgnoreCaseAndIdNot(request.name().trim(), id)) {
            throw new ConflictException("Brand already exists");
        }
        brand.setName(request.name().trim());
        brand.setSlug(SlugUtil.slugify(request.name()));
        return BrandResponse.from(brand);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        Brand brand = brandRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Brand not found"));
        if (productRepository.existsByBrandId(id)) {
            throw new ConflictException("Brand still has products");
        }
        brandRepository.delete(brand);
    }
}
