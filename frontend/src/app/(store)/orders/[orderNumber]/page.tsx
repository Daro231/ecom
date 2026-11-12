"use client";
import Link from "next/link";
import { ChevronLeft } from "lucide-react";
import { AuthGuard } from "@/components/shared/auth-guard";
import { OrderDetail } from "@/components/store/order-detail";

export default function OrderPage({ params }: { params: { orderNumber: string } }) {
  return (
    <AuthGuard>
      <div className="mx-auto max-w-[900px]">
        <Link href="/orders" className="mb-3 inline-flex items-center text-sm text-muted-foreground hover:text-foreground"><ChevronLeft className="h-4 w-4" /> My orders</Link>
        <OrderDetail orderNumber={params.orderNumber} />
      </div>
    </AuthGuard>
  );
}
