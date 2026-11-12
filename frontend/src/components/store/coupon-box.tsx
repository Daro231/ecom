"use client";
import * as React from "react";
import { X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useCheckoutStore } from "@/store/checkoutStore";

export function CouponBox({ error, applying }: { error?: string | null; applying?: boolean }) {
  const couponCode = useCheckoutStore((s) => s.couponCode);
  const set = useCheckoutStore((s) => s.set);
  const [code, setCode] = React.useState("");
  if (couponCode) {
    return (
      <div className="flex items-center justify-between rounded-md border border-green-600/40 bg-green-50 px-3 py-2 text-sm dark:bg-green-950/30" data-testid="coupon-applied">
        <span>Coupon <strong>{couponCode}</strong> applied</span>
        <Button variant="ghost" size="sm" onClick={() => { set({ couponCode: null }); toast.info("Coupon removed"); }} aria-label="Remove coupon"><X className="h-4 w-4" /> Remove</Button>
      </div>
    );
  }
  return (
    <form onSubmit={(e) => { e.preventDefault(); const c = code.trim().toUpperCase(); if (c) set({ couponCode: c }); }} className="space-y-1.5" aria-label="Apply coupon">
      <label htmlFor="coupon" className="text-sm font-medium">Coupon code</label>
      <div className="flex gap-2">
        <Input id="coupon" value={code} onChange={(e) => setCode(e.target.value)} placeholder="e.g. WELCOME10" autoComplete="off" />
        <Button type="submit" variant="secondary" disabled={!code.trim() || applying}>Apply</Button>
      </div>
      {error && <p role="alert" className="text-xs text-destructive">{error}</p>}
    </form>
  );
}
