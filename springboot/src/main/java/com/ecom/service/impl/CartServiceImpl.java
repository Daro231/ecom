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
public class CartServiceImpl implements CartService {
    private final CartRepository cartRepository;
    private final UserRepository userRepository;
    private final ProductRepository productRepository;
    private final CouponService couponService;

    private Cart cartFor(Long userId) {
        return cartRepository.findByUserId(userId).orElseGet(() -> cartRepository.save(
                Cart.builder().user(userRepository.getReferenceById(userId)).build()));
    }

    @Override
    @Transactional
    public CartResponse get(Long userId) {
        return toResponse(cartFor(userId));
    }

    @Override
    @Transactional
    public CartResponse addItem(Long userId, CartItemRequest request) {
        Cart cart = cartFor(userId);
        Product product = productRepository.findById(request.productId()).filter(Product::isActive)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found"));
        Optional<CartItem> existing = cart.getItems().stream()
                .filter(i -> i.getProduct().getId().equals(product.getId())).findFirst();
        int newQuantity = request.quantity() + existing.map(CartItem::getQuantity).orElse(0);
        ensureStock(product, newQuantity);
        if (existing.isPresent()) {
            existing.get().setQuantity(newQuantity);
        } else {
            cart.getItems().add(CartItem.builder().cart(cart).product(product).quantity(newQuantity).build());
        }
        cartRepository.saveAndFlush(cart);
        return toResponse(cart);
    }

    @Override
    @Transactional
    public CartResponse updateItem(Long userId, Long itemId, UpdateCartItemRequest request) {
        Cart cart = cartFor(userId);
        CartItem item = findItem(cart, itemId);
        ensureStock(item.getProduct(), request.quantity());
        item.setQuantity(request.quantity());
        return toResponse(cart);
    }

    @Override
    @Transactional
    public CartResponse removeItem(Long userId, Long itemId) {
        Cart cart = cartFor(userId);
        cart.getItems().remove(findItem(cart, itemId));
        return toResponse(cart);
    }

    @Override
    @Transactional
    public CartResponse clear(Long userId) {
        Cart cart = cartFor(userId);
        cart.getItems().clear();
        return toResponse(cart);
    }

    @Override
    @Transactional
    public CartPreviewResponse applyCoupon(Long userId, ApplyCouponRequest request) {
        Cart cart = cartFor(userId);
        if (cart.getItems().isEmpty()) {
            throw new BadRequestException("Cart is empty");
        }
        BigDecimal subtotal = subtotal(cart);
        CouponService.CouponResult result = couponService.evaluate(request.code(), subtotal);
        ShippingMethod method = request.shippingMethod() == null ? ShippingMethod.STANDARD : request.shippingMethod();
        BigDecimal shipping = MoneyUtil.shippingFee(subtotal, method);
        BigDecimal total = MoneyUtil.scale(subtotal.subtract(result.discount()).add(shipping));
        return new CartPreviewResponse(result.coupon().getCode(), subtotal, result.discount(), shipping, total);
    }

    private CartItem findItem(Cart cart, Long itemId) {
        return cart.getItems().stream().filter(i -> i.getId().equals(itemId)).findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Cart item not found"));
    }

    private void ensureStock(Product product, int quantity) {
        if (quantity > product.getStockQuantity()) {
            throw new InsufficientStockException("Only " + product.getStockQuantity() + " unit(s) of " + product.getName() + " in stock");
        }
    }

    private BigDecimal subtotal(Cart cart) {
        return MoneyUtil.scale(cart.getItems().stream()
                .map(i -> i.getProduct().getPrice().multiply(BigDecimal.valueOf(i.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add));
    }

    private CartResponse toResponse(Cart cart) {
        List<CartItemResponse> items = cart.getItems().stream().map(i -> {
            Product p = i.getProduct();
            String image = p.getImages().isEmpty() ? null : p.getImages().get(0).getImageUrl();
            return new CartItemResponse(i.getId(), p.getId(), p.getName(), image, p.getPrice(), i.getQuantity(),
                    MoneyUtil.scale(p.getPrice().multiply(BigDecimal.valueOf(i.getQuantity()))), p.getStockQuantity());
        }).toList();
        int totalItems = items.stream().mapToInt(CartItemResponse::quantity).sum();
        return new CartResponse(cart.getId(), items, totalItems, subtotal(cart));
    }
}
