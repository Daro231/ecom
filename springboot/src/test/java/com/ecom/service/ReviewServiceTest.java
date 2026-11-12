package com.ecom.service;

import com.ecom.common.exception.ConflictException;
import com.ecom.common.exception.ForbiddenException;
import com.ecom.common.exception.ResourceNotFoundException;
import com.ecom.model.entity.Product;
import com.ecom.model.entity.Review;
import com.ecom.model.entity.User;
import com.ecom.model.enumerate.OrderStatus;
import com.ecom.model.request.ReviewRequest;
import com.ecom.model.response.ReviewResponse;
import com.ecom.repository.OrderItemRepository;
import com.ecom.repository.ProductRepository;
import com.ecom.repository.ReviewRepository;
import com.ecom.repository.UserRepository;
import com.ecom.service.impl.ReviewServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReviewServiceTest {
    @Mock
    ReviewRepository reviewRepository;
    @Mock
    ProductRepository productRepository;
    @Mock
    UserRepository userRepository;
    @Mock
    OrderItemRepository orderItemRepository;
    @InjectMocks
    ReviewServiceImpl reviewService;

    User user;
    Product product;

    @BeforeEach
    void setUp() {
        user = TestData.user(1);
        product = TestData.product(5, "100.00", 5);
        lenient().when(productRepository.findById(5L)).thenReturn(Optional.of(product));
    }

    private Review review(long id, User owner, int rating) {
        Review r = Review.builder().product(product).user(owner).rating(rating).reviewComment("ok").build();
        r.setId(id);
        return r;
    }

    @Test
    void reviewWithoutDeliveredPurchaseIsForbidden() {
        when(orderItemRepository.existsByOrder_User_IdAndOrder_StatusAndProduct_Id(1L, OrderStatus.DELIVERED, 5L)).thenReturn(false);

        assertThatThrownBy(() -> reviewService.create(1L, 5L, new ReviewRequest(5, "great")))
                .isInstanceOf(ForbiddenException.class);
        verify(reviewRepository, never()).save(any());
    }

    @Test
    void duplicateReviewIsConflict() {
        when(orderItemRepository.existsByOrder_User_IdAndOrder_StatusAndProduct_Id(1L, OrderStatus.DELIVERED, 5L)).thenReturn(true);
        when(reviewRepository.existsByUserIdAndProductId(1L, 5L)).thenReturn(true);

        assertThatThrownBy(() -> reviewService.create(1L, 5L, new ReviewRequest(5, "again")))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void createRecalculatesAverageRatingAndCount() {
        when(orderItemRepository.existsByOrder_User_IdAndOrder_StatusAndProduct_Id(1L, OrderStatus.DELIVERED, 5L)).thenReturn(true);
        when(reviewRepository.existsByUserIdAndProductId(1L, 5L)).thenReturn(false);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(reviewRepository.save(any(Review.class))).thenAnswer(inv -> inv.getArgument(0));
        when(reviewRepository.averageRating(5L)).thenReturn(4.666666);
        when(reviewRepository.countVisible(5L)).thenReturn(3L);

        ReviewResponse response = reviewService.create(1L, 5L, new ReviewRequest(5, "great"));

        assertThat(response.rating()).isEqualTo(5);
        assertThat(response.verifiedPurchase()).isTrue();
        assertThat(product.getAverageRating()).isEqualTo(4.67);
        assertThat(product.getReviewCount()).isEqualTo(3);
    }

    @Test
    void reviewOfUnknownProductIsNotFound() {
        when(productRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reviewService.create(1L, 99L, new ReviewRequest(5, null))).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void updateChangesRatingAndRecalculates() {
        Review existing = review(7, user, 3);
        when(reviewRepository.findById(7L)).thenReturn(Optional.of(existing));
        when(reviewRepository.averageRating(5L)).thenReturn(5.0);
        when(reviewRepository.countVisible(5L)).thenReturn(1L);

        reviewService.update(1L, 7L, new ReviewRequest(5, "better"));

        assertThat(existing.getRating()).isEqualTo(5);
        assertThat(existing.getReviewComment()).isEqualTo("better");
        assertThat(product.getAverageRating()).isEqualTo(5.0);
    }

    @Test
    void usersCannotUpdateOrDeleteOthersReviews() {
        Review someoneElses = review(7, TestData.user(2), 3);
        when(reviewRepository.findById(7L)).thenReturn(Optional.of(someoneElses));

        assertThatThrownBy(() -> reviewService.update(1L, 7L, new ReviewRequest(1, "x"))).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> reviewService.delete(1L, 7L)).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void deleteLastReviewResetsRatingToZero() {
        product.setAverageRating(4.0);
        product.setReviewCount(1);
        Review existing = review(7, user, 4);
        when(reviewRepository.findById(7L)).thenReturn(Optional.of(existing));
        when(reviewRepository.averageRating(5L)).thenReturn(null);
        when(reviewRepository.countVisible(5L)).thenReturn(0L);

        reviewService.delete(1L, 7L);

        verify(reviewRepository).delete(existing);
        assertThat(product.getAverageRating()).isZero();
        assertThat(product.getReviewCount()).isZero();
    }

    @Test
    void hidingAReviewRecalculatesProductRating() {
        Review existing = review(7, user, 1);
        when(reviewRepository.findById(7L)).thenReturn(Optional.of(existing));
        when(reviewRepository.averageRating(5L)).thenReturn(4.0);
        when(reviewRepository.countVisible(5L)).thenReturn(2L);

        ReviewResponse response = reviewService.setVisibility(7L, false);

        assertThat(response.visible()).isFalse();
        assertThat(product.getAverageRating()).isEqualTo(4.0);
        assertThat(product.getReviewCount()).isEqualTo(2);
    }

    @Test
    void adminDeleteRemovesReviewAndUnknownIsNotFound() {
        Review existing = review(7, user, 2);
        when(reviewRepository.findById(7L)).thenReturn(Optional.of(existing));
        when(reviewRepository.findById(8L)).thenReturn(Optional.empty());
        when(reviewRepository.averageRating(5L)).thenReturn(null);

        reviewService.adminDelete(7L);
        verify(reviewRepository).delete(existing);
        assertThatThrownBy(() -> reviewService.adminDelete(8L)).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void listsReturnPagedReviews() {
        Review existing = review(7, user, 4);
        when(reviewRepository.findByProductIdAndVisibleTrue(eq(5L), any(Pageable.class))).thenReturn(new PageImpl<>(List.of(existing)));
        when(reviewRepository.findAll(any(Pageable.class))).thenReturn(new PageImpl<>(List.of(existing)));

        assertThat(reviewService.listForProduct(5L, 0, 10).content()).hasSize(1);
        assertThat(reviewService.adminList(0, 10).totalElements()).isEqualTo(1);
    }

    private static <T> T eq(T value) {
        return org.mockito.ArgumentMatchers.eq(value);
    }
}
