"use client";
import { AuthGuard } from "@/components/shared/auth-guard";
import { CheckoutFlow } from "@/components/store/checkout-flow";
import { PageHeader } from "@/components/shared/states";

export default function CheckoutPage() {
  return (
    <AuthGuard>
      <div className="mx-auto max-w-[900px]"><PageHeader title="Checkout" /></div>
      <CheckoutFlow />
    </AuthGuard>
  );
}
