"use client";
import * as React from "react";
import { Ban, CheckCircle2, PackageCheck, Truck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Field, Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { useAdminAction } from "@/hooks/use-admin-action";
import { adminService } from "@/services/admin";
import { NEXT_STATUSES } from "@/lib/constants";
import { enumLabel } from "@/lib/format";
import type { Order, OrderStatus } from "@/types";

const INVALIDATE = ["admin-order", "admin-orders", "admin-dashboard", "admin-payments", "admin-shipments"];

/** Only valid next steps are offered: status change, ship with tracking, out-for-delivery, delivered. */
export function OrderActions({ order }: { order: Order }) {
  const [confirm, setConfirm] = React.useState<OrderStatus | "OUT_FOR_DELIVERY" | "DELIVERED" | null>(null);
  const [shipOpen, setShipOpen] = React.useState(false);
  const [tracking, setTracking] = React.useState("");
  const n = order.orderNumber;
  const setStatus = useAdminAction((s: OrderStatus) => adminService.setOrderStatus(n, s), { success: (o) => `Order is now ${enumLabel(o.status)}`, invalidate: INVALIDATE });
  const ship = useAdminAction((t: string) => adminService.ship(n, t), { success: "Order shipped", invalidate: INVALIDATE });
  const shipment = useAdminAction((s: "OUT_FOR_DELIVERY" | "DELIVERED") => adminService.setShipmentStatus(order.shipment!.id, s), { success: (s) => `Shipment ${enumLabel(s.status).toLowerCase()}`, invalidate: INVALIDATE });

  const next = (NEXT_STATUSES[order.status] ?? []).filter((s) => s !== "CANCELLED");
  const canCancel = (NEXT_STATUSES[order.status] ?? []).includes("CANCELLED");
  const canShip = order.status === "PROCESSING";
  const sh = order.shipment?.status;
  const canOut = order.status === "SHIPPED" && sh === "IN_TRANSIT";
  const canDeliver = order.status === "SHIPPED" && sh === "OUT_FOR_DELIVERY";
  if (!next.length && !canCancel && !canShip && !canOut && !canDeliver) return <p className="text-sm text-muted-foreground">No further actions for this order.</p>;

  return (
    <div className="flex flex-wrap gap-2" data-testid="order-actions">
      {next.map((s) => <Button key={s} onClick={() => setStatus.mutate(s as OrderStatus)} disabled={setStatus.isPending}><CheckCircle2 className="h-4 w-4" /> Mark {enumLabel(s).toLowerCase()}</Button>)}
      {canShip && <Button onClick={() => setShipOpen(true)}><Truck className="h-4 w-4" /> Ship order</Button>}
      {canOut && <Button onClick={() => shipment.mutate("OUT_FOR_DELIVERY")} disabled={shipment.isPending}><Truck className="h-4 w-4" /> Out for delivery</Button>}
      {canDeliver && <Button onClick={() => setConfirm("DELIVERED")}><PackageCheck className="h-4 w-4" /> Mark delivered</Button>}
      {canCancel && <Button variant="destructive" onClick={() => setConfirm("CANCELLED")}><Ban className="h-4 w-4" /> Cancel order</Button>}

      <Dialog open={shipOpen} onOpenChange={setShipOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>Ship order {n}</DialogTitle><DialogDescription>Enter the courier tracking number. The customer is notified.</DialogDescription></DialogHeader>
          <form noValidate className="space-y-4" onSubmit={async (e) => { e.preventDefault(); if (!tracking.trim()) return; try { await ship.mutateAsync(tracking.trim()); setShipOpen(false); setTracking(""); } catch { /* toast */ } }}>
            <Field label="Tracking number" htmlFor="tracking"><Input id="tracking" value={tracking} onChange={(e) => setTracking(e.target.value)} placeholder="e.g. KH-TRK-123456" autoFocus /></Field>
            <div className="flex justify-end gap-2"><Button variant="outline" onClick={() => setShipOpen(false)}>Cancel</Button><Button type="submit" disabled={!tracking.trim() || ship.isPending}>{ship.isPending ? "Shipping…" : "Ship order"}</Button></div>
          </form>
        </DialogContent>
      </Dialog>
      <ConfirmDialog open={confirm === "CANCELLED"} onOpenChange={(o) => !o && setConfirm(null)} title={`Cancel order ${n}?`} description="Stock is restored and a paid order is refunded. The customer is notified." confirmLabel="Cancel order" cancelLabel="Keep order" destructive onConfirm={() => setStatus.mutateAsync("CANCELLED")} />
      <ConfirmDialog open={confirm === "DELIVERED"} onOpenChange={(o) => !o && setConfirm(null)} title="Mark as delivered?" description="The order is completed, cash-on-delivery payments become paid, and the customer can review the items." confirmLabel="Mark delivered" onConfirm={() => shipment.mutateAsync("DELIVERED")} />
    </div>
  );
}
