package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record ReviewResponse(Long id, Long productId, String productName, Long userId, String userName, int rating,
                             String comment, boolean verifiedPurchase, boolean visible, LocalDateTime createdAt) {
    public static ReviewResponse from(Review r) {
        return new ReviewResponse(r.getId(), r.getProduct().getId(), r.getProduct().getName(), r.getUser().getId(),
                r.getUser().getFullName(), r.getRating(), r.getReviewComment(), r.isVerifiedPurchase(), r.isVisible(), r.getCreatedAt());
    }
}
