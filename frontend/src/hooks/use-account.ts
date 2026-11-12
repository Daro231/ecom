import { useEffect } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { addressService } from "@/services/address";
import { notificationService } from "@/services/notification";
import { orderService } from "@/services/order";
import { useAuthStore } from "@/store/authStore";
import { useBadgeStore } from "@/store/badgeStore";
import { errorMessage } from "@/lib/api-error";
import type { AddressInput } from "@/types";

export const useAddresses = () => {
  const token = useAuthStore((s) => s.token);
  return useQuery({ queryKey: ["addresses"], queryFn: addressService.list, enabled: !!token });
};

export function useAddressMutations() {
  const qc = useQueryClient();
  const done = (msg: string) => () => {
    qc.invalidateQueries({ queryKey: ["addresses"] });
    toast.success(msg);
  };
  const onError = (e: unknown) => toast.error(errorMessage(e));
  return {
    create: useMutation({ mutationFn: (b: AddressInput) => addressService.create(b), onSuccess: done("Address added"), onError }),
    update: useMutation({
      mutationFn: (v: { id: number; body: AddressInput }) => addressService.update(v.id, v.body),
      onSuccess: done("Address updated"),
      onError,
    }),
    remove: useMutation({ mutationFn: (id: number) => addressService.remove(id), onSuccess: done("Address deleted"), onError }),
    setDefault: useMutation({ mutationFn: (id: number) => addressService.setDefault(id), onSuccess: done("Default address updated"), onError }),
  };
}

export const useOrders = (page = 0) => {
  const token = useAuthStore((s) => s.token);
  return useQuery({ queryKey: ["orders", page], queryFn: () => orderService.list(page, 100), enabled: !!token });
};
export const useOrder = (n: string) =>
  useQuery({ queryKey: ["order", n], queryFn: () => orderService.get(n) });

export function useUnreadCount() {
  const token = useAuthStore((s) => s.token);
  const set = useBadgeStore((s) => s.setUnreadCount);
  const q = useQuery({
    queryKey: ["unread"],
    queryFn: notificationService.unreadCount,
    enabled: !!token,
    refetchInterval: 30_000,
  });
  useEffect(() => {
    if (typeof q.data === "number") set(q.data);
  }, [q.data, set]);
  return q;
}
export const useNotifications = (page = 0) => {
  const token = useAuthStore((s) => s.token);
  return useQuery({
    queryKey: ["notifications", page],
    queryFn: () => notificationService.list(page, 20),
    enabled: !!token,
    refetchInterval: 30_000,
  });
};
export function useNotificationMutations() {
  const qc = useQueryClient();
  const refresh = () => {
    qc.invalidateQueries({ queryKey: ["notifications"] });
    qc.invalidateQueries({ queryKey: ["unread"] });
  };
  return {
    markRead: useMutation({ mutationFn: (id: number) => notificationService.markRead(id), onSuccess: refresh }),
    markAll: useMutation({ mutationFn: notificationService.markAllRead, onSuccess: refresh }),
  };
}
