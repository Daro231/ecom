package com.ecom.service;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Small factory methods for building entities in unit tests. */
final class TestData {
    private TestData() {
    }

    static User user(long id) {
        User u = User.builder().fullName("User " + id).email("user" + id + "@test.com").password("hash").role(Role.CUSTOMER).enabled(true).build();
        u.setId(id);
        return u;
    }

    static Product product(long id, String price, int stock) {
        Category category = Category.builder().name("Laptop").slug("laptop").build();
        Brand brand = Brand.builder().name("Dell").slug("dell").build();
        Product p = Product.builder().sku("SKU-" + id).name("Product " + id).slug("product-" + id).price(new BigDecimal(price))
                .category(category).brand(brand).stockQuantity(stock).lowStockThreshold(2).build();
        p.setId(id);
        return p;
    }

    static Coupon coupon(DiscountType type, String value) {
        Coupon c = Coupon.builder().code("CODE").discountType(type).discountValue(new BigDecimal(value)).active(true)
                .startAt(LocalDateTime.now().minusDays(1)).endAt(LocalDateTime.now().plusDays(1)).build();
        c.setId(1L);
        return c;
    }

    static Order order(long id, User user, OrderStatus status) {
        Order o = Order.builder().orderNumber("ECOM-20261025-000" + id).user(user).status(status)
                .subtotal(new BigDecimal("100.00")).discountAmount(BigDecimal.ZERO.setScale(2)).shippingFee(new BigDecimal("5.00"))
                .total(new BigDecimal("105.00")).receiverName("R").receiverPhone("012").shippingAddress("Addr")
                .shippingMethod(ShippingMethod.STANDARD).paymentMethod(PaymentMethod.KHQR).build();
        o.setId(id);
        return o;
    }

    static OrderItem item(Order order, Product product, int quantity) {
        OrderItem i = OrderItem.builder().order(order).product(product).productName(product.getName())
                .unitPrice(product.getPrice()).quantity(quantity)
                .lineTotal(product.getPrice().multiply(BigDecimal.valueOf(quantity))).build();
        order.getItems().add(i);
        return i;
    }

    static Payment payment(Order order, PaymentMethod method, PaymentStatus status) {
        Payment p = Payment.builder().order(order).method(method).status(status).amount(order.getTotal()).build();
        p.setId(order.getId());
        return p;
    }

    static Shipment shipment(Order order, ShipmentStatus status) {
        Shipment s = Shipment.builder().order(order).method(order.getShippingMethod()).fee(order.getShippingFee()).status(status).build();
        s.setId(order.getId());
        return s;
    }
}
