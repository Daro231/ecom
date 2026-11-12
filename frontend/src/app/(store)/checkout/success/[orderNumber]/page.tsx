"use client";
import Link from "next/link";
import { CheckCircle2, Clock } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AuthGuard } from "@/components/shared/auth-guard";
import { ErrorState, ListSkeleton } from "@/components/shared/states";
import { useOrder } from "@/hooks/use-account";
import { enumLabel, formatUSD } from "@/lib/format";

export default function SuccessPage({ params }: { params: { orderNumber: string } }) {
  const q = useOrder(params.orderNumber);
  const paid = q.data?.payment?.status === "PAID";
  return (
    <AuthGuard>
      <div className="mx-auto max-w-md py-8 text-center">
        {q.isLoading ? <ListSkeleton rows={2} /> : q.isError ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : (
          <>
            {paid ? <CheckCircle2 className="mx-auto h-16 w-16 text-green-600" /> : <Clock className="mx-auto h-16 w-16 text-primary" />}
            <h1 className="mt-4 text-2xl font-bold" data-testid="success-title">{paid ? "Payment received!" : "Order placed"}</h1>
            <p className="mt-2 text-muted-foreground">
              {paid ? "Thank you! Your payment was confirmed and we are preparing your order." : q.data?.paymentMethod === "KHQR" ? "Your order is waiting for payment. Open it to pay with KHQR." : "Thank you! We will confirm your order shortly."}
            </p>
            <div className="mt-5 rounded-lg border bg-card p-4 text-sm">
              <p>Order number</p>
              <p className="text-lg font-bold" data-testid="success-order-number">{params.orderNumber}</p>
              {q.data && <p className="mt-1 text-muted-foreground">{formatUSD(q.data.total)} · {enumLabel(q.data.paymentMethod)}</p>}
            </div>
            <div className="mt-6 flex flex-col gap-2 sm:flex-row sm:justify-center">
              <Button asChild><Link href={`/orders/${params.orderNumber}`}>View order</Link></Button>
              <Button asChild variant="outline"><Link href="/products">Continue shopping</Link></Button>
            </div>
          </>
        )}
      </div>
    </AuthGuard>
  );
}
