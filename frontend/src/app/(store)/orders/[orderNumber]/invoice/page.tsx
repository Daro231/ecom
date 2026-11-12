"use client";
import { useQuery } from "@tanstack/react-query";
import { Printer } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AuthGuard } from "@/components/shared/auth-guard";
import { ErrorState, ListSkeleton } from "@/components/shared/states";
import { orderService } from "@/services/order";
import { enumLabel, formatDateTime, formatUSD } from "@/lib/format";

export default function InvoicePage({ params }: { params: { orderNumber: string } }) {
  const q = useQuery({ queryKey: ["invoice", params.orderNumber], queryFn: () => orderService.invoice(params.orderNumber) });
  const inv = q.data;
  return (
    <AuthGuard>
      <div className="mx-auto max-w-[800px]">
        <div className="no-print mb-4 flex justify-end"><Button onClick={() => window.print()}><Printer className="h-4 w-4" /> Print invoice</Button></div>
        {q.isLoading ? <ListSkeleton rows={3} /> : q.isError || !inv ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : (
          <article className="rounded-lg border bg-white p-8 text-black shadow-sm" aria-label="Invoice">
            <header className="flex flex-wrap justify-between gap-4 border-b pb-4">
              <div><h1 className="text-2xl font-extrabold">INVOICE</h1><p className="text-sm text-gray-600">{inv.invoiceNumber}</p></div>
              <div className="text-right text-sm"><p className="font-bold">ecom</p><p className="text-gray-600">Issued {formatDateTime(inv.issuedAt)}</p><p className="text-gray-600">Order {inv.orderNumber}</p></div>
            </header>
            <section className="grid gap-4 py-4 text-sm sm:grid-cols-2">
              <div><p className="font-semibold">Billed to</p><p>{inv.customerName}</p><p className="text-gray-600">{inv.customerEmail}</p></div>
              <div><p className="font-semibold">Ship to</p><p>{inv.receiverName} · {inv.receiverPhone}</p><p className="text-gray-600">{inv.shippingAddress}</p></div>
            </section>
            <table className="w-full text-sm">
              <thead><tr className="border-b text-left"><th className="py-2">Item</th><th className="py-2 text-right">Qty</th><th className="py-2 text-right">Price</th><th className="py-2 text-right">Total</th></tr></thead>
              <tbody>{inv.items.map((i) => <tr key={i.id} className="border-b"><td className="py-2">{i.productName}</td><td className="py-2 text-right">{i.quantity}</td><td className="py-2 text-right">{formatUSD(i.unitPrice)}</td><td className="py-2 text-right">{formatUSD(i.lineTotal)}</td></tr>)}</tbody>
            </table>
            <dl className="ml-auto mt-4 w-64 space-y-1 text-sm">
              <div className="flex justify-between"><dt>Subtotal</dt><dd>{formatUSD(inv.subtotal)}</dd></div>
              {inv.discountAmount > 0 && <div className="flex justify-between"><dt>Discount{inv.couponCode ? ` (${inv.couponCode})` : ""}</dt><dd>−{formatUSD(inv.discountAmount)}</dd></div>}
              <div className="flex justify-between"><dt>Shipping</dt><dd>{formatUSD(inv.shippingFee)}</dd></div>
              <div className="flex justify-between border-t pt-1 text-base font-bold"><dt>Total</dt><dd>{formatUSD(inv.total)}</dd></div>
            </dl>
            <footer className="mt-6 border-t pt-3 text-sm text-gray-600">Payment: {enumLabel(inv.payment?.method)} — {enumLabel(inv.payment?.status)}</footer>
          </article>
        )}
      </div>
    </AuthGuard>
  );
}
