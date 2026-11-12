import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { toast } from "sonner";
import { cartService } from "@/services/cart";
import { useCheckoutStore } from "@/store/checkoutStore";
import { useShippingMethods } from "./use-catalog";
import { computeTotals } from "@/lib/totals";
import { errorMessage } from "@/lib/api-error";

/** Totals for the current cart: backend coupon preview when a coupon is set, else derived from shipping data. */
export function useCartTotals(subtotal: number, enabled = true) {
  const { couponCode, shippingMethod, set } = useCheckoutStore();
  const methods = useShippingMethods();
  const [couponError, setCouponError] = useState<string | null>(null);
  const preview = useQuery({
    queryKey: ["coupon-preview", couponCode, shippingMethod, subtotal],
    queryFn: () => cartService.applyCoupon(couponCode as string, shippingMethod),
    enabled: enabled && !!couponCode && subtotal > 0,
    retry: false,
    staleTime: 0,
  });
  useEffect(() => {
    if (preview.isError) {
      const msg = errorMessage(preview.error, "Coupon is not valid");
      setCouponError(msg);
      toast.error(msg);
      set({ couponCode: null });
    } else if (preview.isSuccess) setCouponError(null);
  }, [preview.isError, preview.isSuccess, preview.error, set]);
  const method = methods.data?.find((m) => m.code === shippingMethod);
  const totals = computeTotals(subtotal, method, couponCode ? preview.data : null);
  return { totals, couponError, applying: preview.isFetching, methods, method };
}
