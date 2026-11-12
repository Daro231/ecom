package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record BrandResponse(Long id, String name, String slug) {
    public static BrandResponse from(Brand b) {
        return new BrandResponse(b.getId(), b.getName(), b.getSlug());
    }
}
