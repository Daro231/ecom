import { del, get, post, put } from "@/lib/api";
import type { Cart, CouponPreview, ShippingMethodCode } from "@/types";

export const cartService = {
  get: () => get<Cart>("/cart"),
  add: (productId: number, quantity: number) => post<Cart>("/cart/items", { productId, quantity }),
  update: (itemId: number, quantity: number) => put<Cart>(`/cart/items/${itemId}`, { quantity }),
  remove: (itemId: number) => del<Cart>(`/cart/items/${itemId}`),
  clear: () => del<void>("/cart"),
  applyCoupon: (code: string, shippingMethod: ShippingMethodCode) =>
    post<CouponPreview>("/cart/apply-coupon", { code, shippingMethod }),
};
