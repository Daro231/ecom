package com.ecom.service.impl;

import com.ecom.common.constant.AppConstants;
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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReviewServiceImpl implements ReviewService {
    private final ReviewRepository reviewRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;
    private final OrderItemRepository orderItemRepository;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ReviewResponse> listForProduct(Long productId, int page, int size) {
        Product product = findProduct(productId);
        return PageResponse.of(reviewRepository.findByProductIdAndVisibleTrue(product.getId(), PageUtil.newestFirst(page, size)),
                ReviewResponse::from);
    }

    @Override
    @Transactional
    public ReviewResponse create(Long userId, Long productId, ReviewRequest request) {
        Product product = findProduct(productId);
        if (!orderItemRepository.existsByOrder_User_IdAndOrder_StatusAndProduct_Id(userId, OrderStatus.DELIVERED, productId)) {
            throw new ForbiddenException("You can only review products you have purchased and received");
        }
        if (reviewRepository.existsByUserIdAndProductId(userId, productId)) {
            throw new ConflictException("You have already reviewed this product");
        }
        User user = userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Review review = reviewRepository.save(Review.builder().product(product).user(user).rating(request.rating())
                .reviewComment(request.comment()).verifiedPurchase(true).visible(true).build());
        recalculate(product);
        return ReviewResponse.from(review);
    }

    @Override
    @Transactional
    public ReviewResponse update(Long userId, Long reviewId, ReviewRequest request) {
        Review review = reviewRepository.findById(reviewId).filter(r -> r.getUser().getId().equals(userId))
                .orElseThrow(() -> new ResourceNotFoundException("Review not found"));
        review.setRating(request.rating());
        review.setReviewComment(request.comment());
        reviewRepository.flush();
        recalculate(review.getProduct());
        return ReviewResponse.from(review);
    }

    @Override
    @Transactional
    public void delete(Long userId, Long reviewId) {
        Review review = reviewRepository.findById(reviewId).filter(r -> r.getUser().getId().equals(userId))
                .orElseThrow(() -> new ResourceNotFoundException("Review not found"));
        removeAndRecalculate(review);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ReviewResponse> adminList(int page, int size) {
        return PageResponse.of(reviewRepository.findAll(PageUtil.newestFirst(page, size)), ReviewResponse::from);
    }

    @Override
    @Transactional
    public ReviewResponse setVisibility(Long reviewId, boolean visible) {
        Review review = reviewRepository.findById(reviewId).orElseThrow(() -> new ResourceNotFoundException("Review not found"));
        review.setVisible(visible);
        reviewRepository.flush();
        recalculate(review.getProduct());
        return ReviewResponse.from(review);
    }

    @Override
    @Transactional
    public void adminDelete(Long reviewId) {
        removeAndRecalculate(reviewRepository.findById(reviewId).orElseThrow(() -> new ResourceNotFoundException("Review not found")));
    }

    private void removeAndRecalculate(Review review) {
        Product product = review.getProduct();
        reviewRepository.delete(review);
        reviewRepository.flush();
        recalculate(product);
    }

    private Product findProduct(Long id) {
        return productRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Product not found"));
    }

    private void recalculate(Product product) {
        Double avg = reviewRepository.averageRating(product.getId());
        long count = reviewRepository.countVisible(product.getId());
        product.setAverageRating(avg == null ? 0.0 : Math.round(avg * 100.0) / 100.0);
        product.setReviewCount((int) count);
        productRepository.save(product);
    }
}
