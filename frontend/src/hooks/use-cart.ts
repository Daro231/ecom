import { useEffect } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { cartService } from "@/services/cart";
import { useAuthStore } from "@/store/authStore";
import { useBadgeStore } from "@/store/badgeStore";
import { errorMessage } from "@/lib/api-error";
import type { Cart } from "@/types";

export function useCart() {
  const token = useAuthStore((s) => s.token);
  const setCount = useBadgeStore((s) => s.setCartCount);
  const q = useQuery({ queryKey: ["cart"], queryFn: cartService.get, enabled: !!token });
  useEffect(() => {
    if (q.data) setCount(q.data.totalItems);
  }, [q.data, setCount]);
  return q;
}

export function useCartMutations() {
  const qc = useQueryClient();
  const setCount = useBadgeStore((s) => s.setCartCount);
  const onSuccess = (cart: Cart) => {
    qc.setQueryData(["cart"], cart);
    setCount(cart.totalItems);
  };
  const onError = (e: unknown) => toast.error(errorMessage(e));
  return {
    add: useMutation({
      mutationFn: (v: { productId: number; quantity: number }) => cartService.add(v.productId, v.quantity),
      onSuccess: (c) => {
        onSuccess(c);
        toast.success("Added to cart");
      },
      onError,
    }),
    update: useMutation({
      mutationFn: (v: { itemId: number; quantity: number }) => cartService.update(v.itemId, v.quantity),
      onSuccess,
      onError,
    }),
    remove: useMutation({ mutationFn: (itemId: number) => cartService.remove(itemId), onSuccess, onError }),
  };
}
