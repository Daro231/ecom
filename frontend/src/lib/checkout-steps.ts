import type { PaymentMethod, ShippingMethodCode } from "@/types";

export const STEPS = ["Address", "Shipping", "Payment", "Review"] as const;
export interface CheckoutSelection {
  addressId: number | null;
  shippingMethod: ShippingMethodCode | null;
  paymentMethod: PaymentMethod | null;
}
/** Returns an error message when the step is incomplete, otherwise null. */
export function stepError(step: number, s: CheckoutSelection): string | null {
  if (step >= 0 && step <= 3 && !s.addressId) return step === 0 ? "Choose or add a delivery address to continue." : null;
  if (step === 1 && !s.shippingMethod) return "Choose a shipping method to continue.";
  if (step === 2 && !s.paymentMethod) return "Choose a payment method to continue.";
  return null;
}
