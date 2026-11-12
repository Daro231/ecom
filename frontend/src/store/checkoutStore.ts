import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import type { PaymentMethod, ShippingMethodCode } from "@/types";

export const CHECKOUT_STORAGE_KEY = "ecom-checkout";
interface CheckoutState {
  couponCode: string | null;
  shippingMethod: ShippingMethodCode;
  paymentMethod: PaymentMethod;
  addressId: number | null;
  note: string;
  set: (p: Partial<Omit<CheckoutState, "set" | "reset">>) => void;
  reset: () => void;
}
const initial = { couponCode: null, shippingMethod: "STANDARD" as ShippingMethodCode, paymentMethod: "KHQR" as PaymentMethod, addressId: null, note: "" };

export const useCheckoutStore = create<CheckoutState>()(
  persist(
    (set) => ({ ...initial, set: (p) => set(p), reset: () => set({ ...initial }) }),
    { name: CHECKOUT_STORAGE_KEY, storage: createJSONStorage(() => sessionStorage) },
  ),
);
