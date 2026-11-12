"use client";
import { AuthGuard } from "@/components/shared/auth-guard";
import { KhqrPayment } from "@/components/store/khqr-payment";
import { PageHeader } from "@/components/shared/states";

export default function PayPage({ params }: { params: { orderNumber: string } }) {
  return (
    <AuthGuard>
      <div className="mx-auto max-w-[900px]"><PageHeader title="Pay with KHQR" description={`Order ${params.orderNumber}`} /></div>
      <KhqrPayment orderNumber={params.orderNumber} />
    </AuthGuard>
  );
}
