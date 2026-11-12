package com.ecom.service;

import com.ecom.common.exception.BadRequestException;
import com.ecom.common.exception.InsufficientStockException;
import com.ecom.common.exception.ResourceNotFoundException;
import com.ecom.model.entity.Cart;
import com.ecom.model.entity.CartItem;
import com.ecom.model.entity.Product;
import com.ecom.model.enumerate.DiscountType;
import com.ecom.model.request.ApplyCouponRequest;
import com.ecom.model.request.CartItemRequest;
import com.ecom.model.request.UpdateCartItemRequest;
import com.ecom.model.response.CartPreviewResponse;
import com.ecom.model.response.CartResponse;
import com.ecom.repository.CartRepository;
import com.ecom.repository.ProductRepository;
import com.ecom.repository.UserRepository;
import com.ecom.service.impl.CartServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CartServiceTest {
    @Mock
    CartRepository cartRepository;
    @Mock
    UserRepository userRepository;
    @Mock
    ProductRepository productRepository;
    @Mock
    CouponService couponService;
    @InjectMocks
    CartServiceImpl cartService;

    Cart cart;
    Product laptop;

    @BeforeEach
    void setUp() {
        cart = Cart.builder().user(TestData.user(1)).build();
        cart.setId(10L);
        laptop = TestData.product(5, "100.00", 3);
        lenient().when(cartRepository.findByUserId(1L)).thenReturn(Optional.of(cart));
        lenient().when(productRepository.findById(5L)).thenReturn(Optional.of(laptop));
    }

    private CartItem existingItem(int quantity) {
        CartItem item = CartItem.builder().cart(cart).product(laptop).quantity(quantity).build();
        item.setId(77L);
        cart.getItems().add(item);
        return item;
    }

    @Test
    void addingMoreThanStockIsRejected() {
        assertThatThrownBy(() -> cartService.addItem(1L, new CartItemRequest(5L, 4)))
                .isInstanceOf(InsufficientStockException.class);
        assertThat(cart.getItems()).isEmpty();
    }

    @Test
    void addingToExistingItemChecksCombinedQuantityAgainstStock() {
        existingItem(2);

        assertThatThrownBy(() -> cartService.addItem(1L, new CartItemRequest(5L, 2)))
                .isInstanceOf(InsufficientStockException.class);
    }

    @Test
    void addNewItemComputesTotals() {
        CartResponse response = cartService.addItem(1L, new CartItemRequest(5L, 2));

        assertThat(response.items()).hasSize(1);
        assertThat(response.totalItems()).isEqualTo(2);
        assertThat(response.subtotal()).isEqualByComparingTo("200.00");
        assertThat(response.items().get(0).lineTotal()).isEqualByComparingTo("200.00");
    }

    @Test
    void addingSameProductMergesQuantity() {
        existingItem(1);

        CartResponse response = cartService.addItem(1L, new CartItemRequest(5L, 2));

        assertThat(response.items()).hasSize(1);
        assertThat(response.items().get(0).quantity()).isEqualTo(3);
    }

    @Test
    void inactiveProductCannotBeAdded() {
        laptop.setActive(false);

        assertThatThrownBy(() -> cartService.addItem(1L, new CartItemRequest(5L, 1)))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void updateChangesQuantityAndSubtotal() {
        existingItem(1);

        CartResponse response = cartService.updateItem(1L, 77L, new UpdateCartItemRequest(3));

        assertThat(response.subtotal()).isEqualByComparingTo("300.00");
    }

    @Test
    void updateBeyondStockIsRejected() {
        existingItem(1);

        assertThatThrownBy(() -> cartService.updateItem(1L, 77L, new UpdateCartItemRequest(4)))
                .isInstanceOf(InsufficientStockException.class);
    }

    @Test
    void updatingUnknownItemIsNotFound() {
        assertThatThrownBy(() -> cartService.updateItem(1L, 999L, new UpdateCartItemRequest(1)))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void removeAndClearEmptyTheCart() {
        existingItem(2);
        assertThat(cartService.removeItem(1L, 77L).items()).isEmpty();

        existingItem(2);
        CartResponse cleared = cartService.clear(1L);
        assertThat(cleared.items()).isEmpty();
        assertThat(cleared.subtotal()).isEqualByComparingTo("0.00");
    }

    @Test
    void newUsersGetAnEmptyCartCreated() {
        when(cartRepository.findByUserId(2L)).thenReturn(Optional.empty());
        when(userRepository.getReferenceById(2L)).thenReturn(TestData.user(2));
        when(cartRepository.save(org.mockito.ArgumentMatchers.any(Cart.class))).thenAnswer(inv -> inv.getArgument(0));

        assertThat(cartService.get(2L).items()).isEmpty();
    }

    @Test
    void applyCouponOnEmptyCartIsRejected() {
        assertThatThrownBy(() -> cartService.applyCoupon(1L, new ApplyCouponRequest("WELCOME10", null)))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void applyCouponReturnsPreviewWithDiscountAndShipping() {
        existingItem(2);
        var coupon = TestData.coupon(DiscountType.PERCENT, "10");
        when(couponService.evaluate("WELCOME10", new BigDecimal("200.00")))
                .thenReturn(new CouponService.CouponResult(coupon, new BigDecimal("20.00")));

        CartPreviewResponse preview = cartService.applyCoupon(1L, new ApplyCouponRequest("WELCOME10", null));

        assertThat(preview.subtotal()).isEqualByComparingTo("200.00");
        assertThat(preview.discount()).isEqualByComparingTo("20.00");
        assertThat(preview.shippingFee()).isEqualByComparingTo("5.00");
        assertThat(preview.total()).isEqualByComparingTo("185.00");
    }
}
