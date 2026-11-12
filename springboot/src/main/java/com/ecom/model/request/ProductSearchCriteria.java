package com.ecom.model.request;

import java.math.BigDecimal;

public record ProductSearchCriteria(String keyword, Long categoryId, Long brandId, BigDecimal minPrice, BigDecimal maxPrice,
                                    Integer ram, Double minRating, Boolean inStock, String sort, int page, int size) {
}
