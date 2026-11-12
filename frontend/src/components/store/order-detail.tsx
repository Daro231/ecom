"use client";
import * as React from "react";
import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { FileText, QrCode, Star } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Textarea } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { ErrorState, ListSkeleton } from "@/components/shared/states";
import { StatusBadge } from "@/components/shared/status-badge";
import { StaticMap } from "@/components/shared/address-map-loader";
import { OrderTimeline } from "./order-timeline";
import { OrderSummary } from "./order-summary";
import { ReviewForm } from "./review-form";
import { useOrder } from "@/hooks/use-account";
import { orderService } from "@/services/order";
import { productService } from "@/services/product";
import { useAuthStore } from "@/store/authStore";
import { CANCELLABLE } from "@/lib/constants";
import { enumLabel, formatDateTime, formatUSD, googleMapsUrl } from "@/lib/format";
import { errorMessage } from "@/lib/api-error";
import type { OrderItem } from "@/types";

export const LATE_PAYMENT_MESSAGE = "We received your payment after the order was cancelled. Our team will restore your order or refund you.";

function ItemReview({ item }: { item: OrderItem }) {
  const userId = useAuthStore((s) => s.user?.id);
  const [open, setOpen] = React.useState(false);
  const reviews = useQuery({ queryKey: ["reviews-all", item.productId], queryFn: () => productService.reviews(item.productId, 0, 100) });
  if (reviews.isLoading) return null;
  if (reviews.data?.content.some((r) => r.userId === userId)) return <span className="text-xs font-medium text-green-700 dark:text-green-400">Reviewed ✓</span>;
  return (
    <>
      <Button size="sm" variant="outline" onClick={() => setOpen(true)}><Star className="h-4 w-4" /> Write review</Button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>Review {item.productName}</DialogTitle></DialogHeader>
          <ReviewForm productId={item.productId} productName={item.productName} onDone={() => setOpen(false)} />
        </DialogContent>
      </Dialog>
    </>
  );
}

export function OrderDetail({ orderNumber }: { orderNumber: string }) {
  const qc = useQueryClient();
  const q = useOrder(orderNumber);
  const [cancelOpen, setCancelOpen] = React.useState(false);
  const [reason, setReason] = React.useState("");
  const cancel = useMutation({
    mutationFn: () => orderService.cancel(orderNumber, reason.trim()),
    onSuccess: (o) => {
      qc.setQueryData(["order", orderNumber], o);
      qc.invalidateQueries({ queryKey: ["orders"] });
      toast.success("Order cancelled");
      setReason("");
    },
    onError: (e) => toast.error(errorMessage(e)),
  });

  if (q.isLoading) return <ListSkeleton rows={4} />;
  if (q.isError || !q.data) return <ErrorState title="Order not found" error={q.error} onRetry={() => q.refetch()} />;
  const o = q.data;
  const canCancel = CANCELLABLE.includes(o.status);
  const payNow = o.paymentMethod === "KHQR" && o.payment?.status === "PENDING" && o.status !== "CANCELLED";
  const late = o.payment?.status === "PAID_AFTER_CANCEL";
  const hasPin = o.deliveryLatitude !== undefined && o.deliveryLongitude !== undefined;
  const totals = { subtotal: o.subtotal, discount: o.discountAmount, shippingFee: o.shippingFee, total: o.total, couponCode: o.couponCode, fromBackend: true };

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center gap-3">
        <div>
          <h1 className="text-2xl font-bold" data-testid="order-number">{o.orderNumber}</h1>
          <p className="text-sm text-muted-foreground">Placed {formatDateTime(o.createdAt)}</p>
        </div>
        <div className="flex gap-2"><StatusBadge kind="order" value={o.status} /><StatusBadge kind="payment" value={o.payment?.status} /></div>
        <div className="ml-auto flex flex-wrap gap-2">
          {payNow && <Button asChild><Link href={`/checkout/pay/${o.orderNumber}`}><QrCode className="h-4 w-4" /> Pay now</Link></Button>}
          <Button asChild variant="outline"><Link href={`/orders/${o.orderNumber}/invoice`}><FileText className="h-4 w-4" /> Invoice</Link></Button>
          {canCancel && <Button variant="destructive" onClick={() => setCancelOpen(true)}>Cancel order</Button>}
        </div>
      </div>

      {late && <div role="alert" data-testid="late-payment-msg" className="rounded-lg border border-red-300 bg-red-50 p-4 text-sm font-medium text-red-900 dark:border-red-800 dark:bg-red-950/40 dark:text-red-100">{LATE_PAYMENT_MESSAGE}</div>}
      {o.status === "CANCELLED" && o.cancelledReason && <p className="rounded-lg border bg-card p-3 text-sm"><span className="font-medium">Cancelled:</span> {o.cancelledReason}</p>}

      <div className="grid gap-5 md:grid-cols-[1fr_280px]">
        <div className="space-y-5">
          <Card>
            <CardHeader><CardTitle>Items</CardTitle></CardHeader>
            <CardContent>
              <ul className="divide-y">
                {o.items.map((i) => (
                  <li key={i.id} className="flex flex-wrap items-center gap-3 py-3 text-sm">
                    <div className="min-w-0 flex-1"><p className="font-medium">{i.productName}</p><p className="text-muted-foreground">{i.quantity} × {formatUSD(i.unitPrice)}</p></div>
                    {o.status === "DELIVERED" && <ItemReview item={i} />}
                    <span className="font-semibold">{formatUSD(i.lineTotal)}</span>
                  </li>
                ))}
              </ul>
              <div className="mt-3 border-t pt-3"><OrderSummary totals={totals} /></div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader><CardTitle>Delivery &amp; payment</CardTitle></CardHeader>
            <CardContent className="grid gap-4 text-sm sm:grid-cols-2">
              <div><p className="font-medium">Receiver</p><p className="text-muted-foreground">{o.receiverName} · {o.receiverPhone}</p></div>
              <div><p className="font-medium">Address</p><p className="text-muted-foreground">{o.shippingAddress}</p></div>
              <div><p className="font-medium">Shipping</p><p className="text-muted-foreground">{enumLabel(o.shippingMethod)}</p></div>
              <div><p className="font-medium">Payment</p><p className="text-muted-foreground">{enumLabel(o.paymentMethod)}</p></div>
              {o.shipment && <div><p className="font-medium">Shipment</p><p className="text-muted-foreground"><StatusBadge kind="shipment" value={o.shipment.status} /></p></div>}
              {o.shipment?.trackingNumber && <div><p className="font-medium">Tracking number</p><p className="font-mono text-muted-foreground" data-testid="tracking-number">{o.shipment.trackingNumber}</p></div>}
              {o.note && <div className="sm:col-span-2"><p className="font-medium">Note</p><p className="text-muted-foreground">{o.note}</p></div>}
              {hasPin && (
                <div className="sm:col-span-2">
                  <p className="mb-1 font-medium">Delivery pin</p>
                  <StaticMap lat={o.deliveryLatitude as number} lng={o.deliveryLongitude as number} />
                  <a className="mt-1 inline-block text-xs text-primary hover:underline" target="_blank" rel="noopener noreferrer" href={googleMapsUrl(o.deliveryLatitude as number, o.deliveryLongitude as number)}>Open in Google Maps</a>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
        <Card className="h-fit"><CardHeader><CardTitle>Status</CardTitle></CardHeader><CardContent><OrderTimeline order={o} /></CardContent></Card>
      </div>

      <ConfirmDialog
        open={cancelOpen}
        onOpenChange={setCancelOpen}
        title={`Cancel order ${o.orderNumber}?`}
        description="Stock is returned and any payment you made will be refunded."
        confirmLabel="Cancel order"
        cancelLabel="Keep order"
        destructive
        confirmDisabled={reason.trim().length < 3}
        onConfirm={() => cancel.mutateAsync()}
      >
        <div className="space-y-1.5">
          <label htmlFor="cancel-reason" className="text-sm font-medium">Reason</label>
          <Textarea id="cancel-reason" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Why are you cancelling?" maxLength={250} />
        </div>
      </ConfirmDialog>
    </div>
  );
}
