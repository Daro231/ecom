import { Badge } from "@/components/ui/badge";
import { enumLabel } from "@/lib/format";

type Tone = "gray" | "blue" | "amber" | "green" | "red" | "redSolid" | "purple" | "orange";
const ORDER: Record<string, Tone> = {
  PENDING: "amber", CONFIRMED: "blue", PROCESSING: "purple", SHIPPED: "orange", DELIVERED: "green", CANCELLED: "red",
};
const PAYMENT: Record<string, Tone> = {
  PENDING: "amber", PAID: "green", FAILED: "red", REFUNDED: "gray", PAID_AFTER_CANCEL: "redSolid",
};
const SHIPMENT: Record<string, Tone> = {
  PREPARING: "amber", IN_TRANSIT: "blue", OUT_FOR_DELIVERY: "orange", DELIVERED: "green",
};
const MAPS = { order: ORDER, payment: PAYMENT, shipment: SHIPMENT };

export function StatusBadge({ kind, value }: { kind: keyof typeof MAPS; value?: string }) {
  if (!value) return null;
  return (
    <Badge tone={MAPS[kind][value] ?? "gray"} data-testid={`${kind}-badge`}>
      {enumLabel(value)}
    </Badge>
  );
}
