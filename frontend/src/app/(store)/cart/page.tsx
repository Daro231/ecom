"use client";
import Link from "next/link";
import { Minus, Plus, ShoppingBag, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { AuthGuard } from "@/components/shared/auth-guard";
import { EmptyState, ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { ProductImage } from "@/components/shared/product-image";
import { OrderSummary } from "@/components/store/order-summary";
import { CouponBox } from "@/components/store/coupon-box";
import { useCart, useCartMutations } from "@/hooks/use-cart";
import { useCartTotals } from "@/hooks/use-totals";
import { formatUSD } from "@/lib/format";

function CartContent() {
  const cart = useCart();
  const { update, remove } = useCartMutations();
  const subtotal = cart.data?.subtotal ?? 0;
  const { totals, couponError, applying, method } = useCartTotals(subtotal);

  if (cart.isLoading) return <ListSkeleton rows={3} />;
  if (cart.isError) return <ErrorState error={cart.error} onRetry={() => cart.refetch()} />;
  const items = cart.data?.items ?? [];
  if (items.length === 0) {
    return <EmptyState icon={<ShoppingBag className="h-10 w-10" />} title="Your cart is empty" description="Browse our laptops, monitors and components." action={<Button asChild><Link href="/products">Start shopping</Link></Button>} />;
  }
  return (
    <div className="grid gap-6 md:grid-cols-[1fr_320px]">
      <ul className="space-y-3" aria-label="Cart items">
        {items.map((it) => (
          <li key={it.id} className="flex gap-4 rounded-lg border bg-card p-3" data-testid="cart-item">
            <ProductImage src={it.imageUrl} alt={it.productName} className="h-20 w-24 shrink-0 rounded-md" sizes="96px" />
            <div className="flex min-w-0 flex-1 flex-col gap-2">
              <span className="line-clamp-2 font-medium">{it.productName}</span>
              <p className="text-sm text-muted-foreground">{formatUSD(it.unitPrice)} each</p>
              <div className="mt-auto flex flex-wrap items-center gap-3">
                <div className="flex items-center rounded-md border" role="group" aria-label={`Quantity for ${it.productName}`}>
                  <Button variant="ghost" size="icon" aria-label="Decrease quantity" disabled={it.quantity <= 1 || update.isPending} onClick={() => update.mutate({ itemId: it.id, quantity: it.quantity - 1 })}><Minus className="h-4 w-4" /></Button>
                  <span className="w-9 text-center text-sm font-medium" data-testid="item-qty">{it.quantity}</span>
                  <Button variant="ghost" size="icon" aria-label="Increase quantity" disabled={it.quantity >= it.stockQuantity || update.isPending} onClick={() => update.mutate({ itemId: it.id, quantity: it.quantity + 1 })}><Plus className="h-4 w-4" /></Button>
                </div>
                <Button variant="ghost" size="sm" className="text-destructive" onClick={() => remove.mutate(it.id)} aria-label={`Remove ${it.productName}`}><Trash2 className="h-4 w-4" /> Remove</Button>
                <span className="ml-auto font-semibold">{formatUSD(it.lineTotal)}</span>
              </div>
              {it.quantity >= it.stockQuantity && <p className="text-xs text-amber-600">Maximum available quantity</p>}
            </div>
          </li>
        ))}
      </ul>
      <Card className="h-fit">
        <CardContent className="space-y-4 p-5">
          <h2 className="text-lg font-semibold">Order summary</h2>
          <CouponBox error={couponError} applying={applying} />
          <OrderSummary totals={totals} shippingLabel={method ? `Shipping (${method.label})` : "Shipping"} />
          <Button asChild size="lg" className="w-full"><Link href="/checkout">Proceed to checkout</Link></Button>
          <Button asChild variant="link" className="w-full"><Link href="/products">Continue shopping</Link></Button>
        </CardContent>
      </Card>
    </div>
  );
}

export default function CartPage() {
  return (
    <AuthGuard>
      <div className="mx-auto max-w-[900px]">
        <PageHeader title="Shopping cart" />
        <CartContent />
      </div>
    </AuthGuard>
  );
}
