import { get, post } from "@/lib/api";
import type { CheckoutInput, Invoice, Order, PageResponse, Shipment } from "@/types";

export const orderService = {
  checkout: (b: CheckoutInput) => post<Order>("/orders/checkout", b),
  list: (page = 0, size = 50) => get<PageResponse<Order>>("/orders", { page, size }),
  get: (n: string) => get<Order>(`/orders/${n}`),
  invoice: (n: string) => get<Invoice>(`/orders/${n}/invoice`),
  tracking: (n: string) => get<Shipment>(`/orders/${n}/tracking`),
  cancel: (n: string, reason: string) => post<Order>(`/orders/${n}/cancel`, { reason }),
};
