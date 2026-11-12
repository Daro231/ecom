import type { Order } from "@/types";

export interface TimelineStep {
  key: string;
  label: string;
  at?: string;
  state: "done" | "current" | "pending" | "cancelled";
  note?: string;
}
const FLOW = ["PENDING", "CONFIRMED", "PROCESSING", "SHIPPED", "DELIVERED"] as const;
const LABEL: Record<string, string> = {
  PENDING: "Order placed", CONFIRMED: "Confirmed", PROCESSING: "Processing", SHIPPED: "Shipped", DELIVERED: "Delivered",
};

/** Vertical timeline; only timestamps the API really provides are shown. */
export function buildTimeline(o: Order): TimelineStep[] {
  const at = (k: string) =>
    k === "PENDING" ? o.createdAt : k === "CONFIRMED" ? o.payment?.paidAt : k === "SHIPPED" ? o.shipment?.shippedAt : k === "DELIVERED" ? o.shipment?.deliveredAt : undefined;
  if (o.status === "CANCELLED") {
    return [
      { key: "PENDING", label: LABEL.PENDING, at: o.createdAt, state: "done" },
      { key: "CANCELLED", label: "Cancelled", state: "cancelled", note: o.cancelledReason },
    ];
  }
  const idx = FLOW.indexOf(o.status as (typeof FLOW)[number]);
  return FLOW.map((k, i) => ({
    key: k,
    label: LABEL[k],
    at: i <= idx ? at(k) : undefined,
    state: i < idx ? "done" : i === idx ? (k === "DELIVERED" ? "done" : "current") : "pending",
  }));
}
