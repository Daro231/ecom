import type { CouponPreview, ShippingMethod } from "@/types";

export interface Totals {
  subtotal: number;
  discount: number;
  shippingFee: number | null; // null = not known yet
  total: number | null;
  couponCode?: string;
  fromBackend: boolean;
}

/**
 * With a coupon the backend preview is used exactly. Without one there is no totals endpoint, so
 * shipping is derived from the backend's own shipping method data (fee + free-shipping threshold).
 */
export function computeTotals(subtotal: number, method?: ShippingMethod, preview?: CouponPreview | null): Totals {
  if (preview) {
    return { subtotal: preview.subtotal, discount: preview.discount, shippingFee: preview.shippingFee, total: preview.total, couponCode: preview.couponCode, fromBackend: true };
  }
  if (!method) return { subtotal, discount: 0, shippingFee: null, total: null, fromBackend: false };
  const free = method.freeShippingThreshold !== undefined && subtotal >= method.freeShippingThreshold;
  const fee = free ? 0 : method.fee;
  return { subtotal, discount: 0, shippingFee: fee, total: Math.round((subtotal + fee) * 100) / 100, fromBackend: false };
}
