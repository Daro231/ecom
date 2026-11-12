"use client";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ChevronLeft, ExternalLink } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ErrorState, ListSkeleton } from "@/components/shared/states";
import { StatusBadge } from "@/components/shared/status-badge";
import { StaticMap } from "@/components/shared/address-map-loader";
import { OrderTimeline } from "@/components/store/order-timeline";
import { OrderSummary } from "@/components/store/order-summary";
import { OrderActions } from "@/components/admin/order-actions";
import { PaymentActions } from "@/components/admin/payment-actions";
import { adminService } from "@/services/admin";
import { enumLabel, formatDateTime, formatUSD, googleMapsUrl } from "@/lib/format";
import { LATE_PAYMENT_MESSAGE } from "@/components/store/order-detail";

export default function AdminOrderPage({ params }: { params: { orderNumber: string } }) {
  const q = useQuery({ queryKey: ["admin-order", params.orderNumber], queryFn: () => adminService.order(params.orderNumber) });
  if (q.isLoading) return <ListSkeleton rows={4} className="h-32" />;
  if (q.isError || !q.data) return <ErrorState title="Order not found" error={q.error} onRetry={() => q.refetch()} />;
  const o = q.data;
  const pin = o.deliveryLatitude !== undefined && o.deliveryLongitude !== undefined;
  const totals = { subtotal: o.subtotal, discount: o.discountAmount, shippingFee: o.shippingFee, total: o.total, couponCode: o.couponCode, fromBackend: true };
  return (
    <div className="mx-auto max-w-[1000px] space-y-5">
      <Link href="/admin/orders" className="inline-flex items-center text-sm text-muted-foreground hover:text-foreground"><ChevronLeft className="h-4 w-4" /> Orders</Link>
      <div className="flex flex-wrap items-center gap-3">
        <div><h1 className="text-2xl font-bold" data-testid="order-number">{o.orderNumber}</h1><p className="text-sm text-muted-foreground">{formatDateTime(o.createdAt)} · {o.customerEmail}</p></div>
        <div className="flex gap-2"><StatusBadge kind="order" value={o.status} /><StatusBadge kind="payment" value={o.payment?.status} /></div>
      </div>
      {o.payment?.status === "PAID_AFTER_CANCEL" && (
        <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-red-300 bg-red-50 p-4 text-sm text-red-900 dark:border-red-800 dark:bg-red-950/40 dark:text-red-100">
          <span className="font-medium">Customer paid after cancel. {LATE_PAYMENT_MESSAGE.replace("Our team will", "You should")}</span>
          <PaymentActions payment={o.payment} orderNumber={o.orderNumber} />
        </div>
      )}
      <Card><CardHeader><CardTitle>Actions</CardTitle></CardHeader><CardContent><OrderActions order={o} /></CardContent></Card>
      <div className="grid gap-5 md:grid-cols-[1fr_260px]">
        <div className="space-y-5">
          <Card><CardHeader><CardTitle>Items</CardTitle></CardHeader><CardContent>
            <ul className="divide-y">{o.items.map((i) => <li key={i.id} className="flex justify-between gap-3 py-2.5 text-sm"><span>{i.quantity} × {i.productName} <span className="text-muted-foreground">@ {formatUSD(i.unitPrice)}</span></span><span className="font-semibold">{formatUSD(i.lineTotal)}</span></li>)}</ul>
            <div className="mt-3 border-t pt-3"><OrderSummary totals={totals} /></div>
          </CardContent></Card>
          <Card><CardHeader><CardTitle>Delivery &amp; payment</CardTitle></CardHeader>
            <CardContent className="grid gap-4 text-sm sm:grid-cols-2">
              <div><p className="font-medium">Receiver</p><p className="text-muted-foreground">{o.receiverName} · {o.receiverPhone}</p></div>
              <div><p className="font-medium">Address</p><p className="text-muted-foreground">{o.shippingAddress}</p></div>
              <div><p className="font-medium">Shipping</p><p className="text-muted-foreground">{enumLabel(o.shippingMethod)} · {formatUSD(o.shippingFee)}</p></div>
              <div><p className="font-medium">Payment</p><p className="text-muted-foreground">{enumLabel(o.paymentMethod)} · {enumLabel(o.payment?.status)}{o.payment?.transactionRef ? ` · ${o.payment.transactionRef}` : ""}</p></div>
              {o.payment?.failureReason && <div className="sm:col-span-2"><p className="font-medium">Failure reason</p><p className="text-muted-foreground">{o.payment.failureReason}</p></div>}
              {o.shipment && <div><p className="font-medium">Shipment</p><StatusBadge kind="shipment" value={o.shipment.status} /></div>}
              {o.shipment?.trackingNumber && <div><p className="font-medium">Tracking number</p><p className="font-mono text-muted-foreground" data-testid="tracking-number">{o.shipment.trackingNumber}</p></div>}
              {o.cancelledReason && <div className="sm:col-span-2"><p className="font-medium">Cancelled reason</p><p className="text-muted-foreground">{o.cancelledReason}</p></div>}
              {o.note && <div className="sm:col-span-2"><p className="font-medium">Customer note</p><p className="text-muted-foreground">{o.note}</p></div>}
              {pin ? (
                <div className="sm:col-span-2">
                  <div className="mb-1 flex items-center justify-between"><p className="font-medium">Delivery pin</p>
                    <Button asChild size="sm" variant="outline"><a href={googleMapsUrl(o.deliveryLatitude as number, o.deliveryLongitude as number)} target="_blank" rel="noopener noreferrer"><ExternalLink className="h-4 w-4" /> Open in Google Maps</a></Button></div>
                  <StaticMap lat={o.deliveryLatitude as number} lng={o.deliveryLongitude as number} height={220} />
                </div>
              ) : <p className="text-xs text-muted-foreground sm:col-span-2">The customer did not drop a map pin for this address.</p>}
            </CardContent></Card>
        </div>
        <Card className="h-fit"><CardHeader><CardTitle>Timeline</CardTitle></CardHeader><CardContent><OrderTimeline order={o} /></CardContent></Card>
      </div>
    </div>
  );
}
