"use client";
import * as React from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Banknote, Check, CreditCard, Landmark, MapPin, Plus, QrCode } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Textarea } from "@/components/ui/input";
import { EmptyState, ErrorState, ListSkeleton } from "@/components/shared/states";
import { AddressForm } from "./address-form";
import { OrderSummary } from "./order-summary";
import { CouponBox } from "./coupon-box";
import { useCart } from "@/hooks/use-cart";
import { useAddressMutations, useAddresses } from "@/hooks/use-account";
import { useCartTotals } from "@/hooks/use-totals";
import { orderService } from "@/services/order";
import { useAuthStore, isStaffRole } from "@/store/authStore";
import { useBadgeStore } from "@/store/badgeStore";
import { useCheckoutStore } from "@/store/checkoutStore";
import { STEPS, stepError } from "@/lib/checkout-steps";
import { enumLabel, formatUSD } from "@/lib/format";
import { errorMessage } from "@/lib/api-error";
import { cn } from "@/lib/utils";
import type { PaymentMethod } from "@/types";
import Link from "next/link";

const PAYMENTS: { code: PaymentMethod; label: string; desc: string; icon: React.ReactNode }[] = [
  { code: "KHQR", label: "KHQR", desc: "Scan with any Bakong banking app", icon: <QrCode className="h-6 w-6" /> },
  { code: "CASH_ON_DELIVERY", label: "Cash on Delivery", desc: "Pay when your order arrives", icon: <Banknote className="h-6 w-6" /> },
  { code: "CARD", label: "Card", desc: "Credit or debit card", icon: <CreditCard className="h-6 w-6" /> },
  { code: "BANK_TRANSFER", label: "Bank Transfer", desc: "Transfer from your bank account", icon: <Landmark className="h-6 w-6" /> },
];

export function CheckoutFlow() {
  const router = useRouter();
  const qc = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const setCartCount = useBadgeStore((s) => s.setCartCount);
  const cart = useCart();
  const addresses = useAddresses();
  const { create } = useAddressMutations();
  const sel = useCheckoutStore();
  const [step, setStep] = React.useState(0);
  const [adding, setAdding] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const subtotal = cart.data?.subtotal ?? 0;
  const { totals, couponError, applying, methods } = useCartTotals(subtotal);

  // preselect the default address
  React.useEffect(() => {
    if (!addresses.data || addresses.data.length === 0) return;
    if (!sel.addressId || !addresses.data.some((a) => a.id === sel.addressId)) {
      sel.set({ addressId: (addresses.data.find((a) => a.isDefault) ?? addresses.data[0]).id });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [addresses.data]);

  const place = useMutation({
    mutationFn: () => orderService.checkout({
      addressId: sel.addressId as number,
      shippingMethod: sel.shippingMethod,
      paymentMethod: sel.paymentMethod,
      couponCode: sel.couponCode ?? undefined,
      note: sel.note.trim() || undefined,
    }),
    onSuccess: (order) => {
      console.info("Order placed:", order.orderNumber);
      sel.reset();
      setCartCount(0);
      qc.invalidateQueries({ queryKey: ["cart"] });
      qc.invalidateQueries({ queryKey: ["orders"] });
      router.replace(order.paymentMethod === "KHQR" ? `/checkout/pay/${order.orderNumber}` : `/checkout/success/${order.orderNumber}`);
    },
    onError: (e) => {
      toast.error(errorMessage(e));
      qc.invalidateQueries({ queryKey: ["cart"] });
    },
  });

  if (user && isStaffRole(user.role)) {
    return <EmptyState title="Admin accounts cannot place orders" description="Sign in with a customer account to check out. You can keep browsing the store." action={<Button asChild><Link href="/admin/dashboard">Go to admin panel</Link></Button>} />;
  }
  if (cart.isLoading || addresses.isLoading) return <ListSkeleton rows={3} />;
  if (cart.isError) return <ErrorState error={cart.error} onRetry={() => cart.refetch()} />;
  if (!cart.data || cart.data.items.length === 0) {
    return <EmptyState title="Your cart is empty" action={<Button asChild><Link href="/products">Start shopping</Link></Button>} />;
  }

  const selection = { addressId: sel.addressId, shippingMethod: sel.shippingMethod, paymentMethod: sel.paymentMethod };
  const next = () => {
    const err = stepError(step, selection);
    setError(err);
    if (!err) setStep((s) => Math.min(3, s + 1));
  };
  const addr = addresses.data?.find((a) => a.id === sel.addressId);
  const ship = methods.data?.find((m) => m.code === sel.shippingMethod);

  return (
    <div className="mx-auto max-w-[900px]">
      <ol className="mb-6 flex items-center gap-2" aria-label="Checkout steps">
        {STEPS.map((s, i) => (
          <li key={s} className="flex flex-1 items-center gap-2" aria-current={i === step ? "step" : undefined}>
            <span className={cn("flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-sm font-bold", i < step ? "bg-green-600 text-white" : i === step ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground")}>
              {i < step ? <Check className="h-4 w-4" /> : i + 1}
            </span>
            <span className={cn("hidden text-sm font-medium sm:inline", i === step ? "text-foreground" : "text-muted-foreground")}>{s}</span>
            {i < STEPS.length - 1 && <span className="h-px flex-1 bg-border" />}
          </li>
        ))}
      </ol>

      <div className="grid gap-6 md:grid-cols-[1fr_300px]">
        <div>
          {step === 0 && (
            <section aria-label="Delivery address" className="space-y-3">
              <h2 className="text-lg font-semibold">Delivery address</h2>
              {addresses.isError && <ErrorState error={addresses.error} onRetry={() => addresses.refetch()} />}
              {!adding && (
                <>
                  <ul className="space-y-2">
                    {addresses.data?.map((a) => (
                      <li key={a.id}>
                        <label className={cn("flex cursor-pointer items-start gap-3 rounded-lg border bg-card p-3", sel.addressId === a.id && "border-primary ring-1 ring-primary")}>
                          <input type="radio" name="address" className="mt-1 accent-[hsl(var(--primary))]" checked={sel.addressId === a.id} onChange={() => { sel.set({ addressId: a.id }); setError(null); }} />
                          <span className="text-sm">
                            <span className="block font-medium">{a.receiverName} · {a.phone} {a.isDefault && <span className="ml-1 rounded bg-accent px-1.5 text-xs text-accent-foreground">Default</span>}</span>
                            <span className="block text-muted-foreground">{a.line1}, {a.city}</span>
                            {a.latitude !== undefined && <span className="flex items-center gap-1 text-xs text-muted-foreground"><MapPin className="h-3 w-3" /> Pin saved</span>}
                          </span>
                        </label>
                      </li>
                    ))}
                  </ul>
                  <Button variant="outline" onClick={() => setAdding(true)}><Plus className="h-4 w-4" /> Add new address</Button>
                </>
              )}
              {adding && (
                <Card><CardContent className="p-4">
                  <AddressForm
                    defaults={{ receiverName: user?.fullName, phone: user?.phone }}
                    submitLabel="Save and use this address"
                    onCancel={() => setAdding(false)}
                    onSubmit={async (input) => {
                      const created = await create.mutateAsync(input);
                      sel.set({ addressId: created.id });
                      setAdding(false);
                      setError(null);
                    }}
                  />
                </CardContent></Card>
              )}
            </section>
          )}

          {step === 1 && (
            <section aria-label="Shipping method" className="space-y-3">
              <h2 className="text-lg font-semibold">Shipping method</h2>
              {methods.isLoading && <ListSkeleton rows={3} />}
              {methods.isError && <ErrorState error={methods.error} onRetry={() => methods.refetch()} />}
              {methods.data?.map((m) => {
                const free = m.freeShippingThreshold !== undefined && subtotal >= m.freeShippingThreshold;
                return (
                  <label key={m.code} className={cn("flex cursor-pointer items-center gap-3 rounded-lg border bg-card p-3", sel.shippingMethod === m.code && "border-primary ring-1 ring-primary")}>
                    <input type="radio" name="shipping" className="accent-[hsl(var(--primary))]" checked={sel.shippingMethod === m.code} onChange={() => { sel.set({ shippingMethod: m.code }); setError(null); }} />
                    <span className="flex-1 text-sm"><span className="block font-medium">{m.label}</span><span className="text-muted-foreground">{m.estimatedDelivery}</span></span>
                    <span className="font-semibold">{free ? "Free" : formatUSD(m.fee)}</span>
                  </label>
                );
              })}
            </section>
          )}

          {step === 2 && (
            <section aria-label="Payment method" className="space-y-3">
              <h2 className="text-lg font-semibold">Payment method</h2>
              {PAYMENTS.map((p) => (
                <label key={p.code} className={cn("flex cursor-pointer items-center gap-3 rounded-lg border bg-card p-3", sel.paymentMethod === p.code && "border-primary ring-1 ring-primary")}>
                  <input type="radio" name="payment" className="accent-[hsl(var(--primary))]" checked={sel.paymentMethod === p.code} onChange={() => { sel.set({ paymentMethod: p.code }); setError(null); }} />
                  <span className="text-primary">{p.icon}</span>
                  <span className="text-sm"><span className="block font-medium">{p.label}</span><span className="text-muted-foreground">{p.desc}</span></span>
                </label>
              ))}
            </section>
          )}

          {step === 3 && (
            <section aria-label="Review order" className="space-y-4">
              <h2 className="text-lg font-semibold">Review &amp; place order</h2>
              <Card><CardContent className="space-y-3 p-4 text-sm">
                <div><p className="font-medium">Deliver to</p><p className="text-muted-foreground">{addr ? `${addr.receiverName} · ${addr.phone} — ${addr.line1}, ${addr.city}` : "—"}</p></div>
                <div><p className="font-medium">Shipping</p><p className="text-muted-foreground">{ship ? `${ship.label} (${ship.estimatedDelivery})` : enumLabel(sel.shippingMethod)}</p></div>
                <div><p className="font-medium">Payment</p><p className="text-muted-foreground">{enumLabel(sel.paymentMethod)}</p></div>
                <ul className="divide-y border-t pt-2">
                  {cart.data.items.map((i) => (
                    <li key={i.id} className="flex justify-between py-1.5"><span>{i.quantity} × {i.productName}</span><span>{formatUSD(i.lineTotal)}</span></li>
                  ))}
                </ul>
              </CardContent></Card>
              <div className="space-y-1.5">
                <label htmlFor="note" className="text-sm font-medium">Note for the courier (optional)</label>
                <Textarea id="note" value={sel.note} maxLength={250} onChange={(e) => sel.set({ note: e.target.value })} placeholder="e.g. Please call before delivery" />
              </div>
            </section>
          )}

          {error && <p role="alert" className="mt-3 text-sm text-destructive">{error}</p>}
          <div className="mt-6 flex justify-between">
            <Button variant="outline" disabled={step === 0} onClick={() => { setError(null); setStep((s) => s - 1); }}>Back</Button>
            {step < 3 ? (
              <Button onClick={next} disabled={adding}>Continue</Button>
            ) : (
              <Button size="lg" onClick={() => place.mutate()} disabled={place.isPending}>{place.isPending ? "Placing order…" : "Place order"}</Button>
            )}
          </div>
        </div>

        <Card className="h-fit"><CardContent className="space-y-4 p-5">
          <h2 className="font-semibold">Summary</h2>
          <CouponBox error={couponError} applying={applying} />
          <OrderSummary totals={totals} shippingNote="Choose shipping" shippingLabel={ship ? `Shipping (${ship.label})` : "Shipping"} />
        </CardContent></Card>
      </div>
    </div>
  );
}
