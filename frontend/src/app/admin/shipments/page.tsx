"use client";
import * as React from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { Tabs } from "@/components/ui/tabs";
import { Card, CardContent } from "@/components/ui/card";
import { EmptyState, ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { Pagination } from "@/components/shared/pagination";
import { StatusBadge } from "@/components/shared/status-badge";
import { OrderActions } from "@/components/admin/order-actions";
import { adminService } from "@/services/admin";
import { enumLabel, formatDateTime } from "@/lib/format";

const TABS = [{ value: "PROCESSING", label: "Ready to ship" }, { value: "SHIPPED", label: "On the way" }, { value: "DELIVERED", label: "Delivered" }];

export default function ShipmentsPage() {
  const [tab, setTab] = React.useState("PROCESSING");
  const [page, setPage] = React.useState(0);
  const q = useQuery({ queryKey: ["admin-orders", "shipments", tab, page], queryFn: () => adminService.orders({ status: tab, page, size: 10 }) });
  return (
    <div>
      <PageHeader title="Shipments" description="Ship orders, track them and mark them delivered" />
      <Tabs items={TABS} value={tab} onChange={(v) => { setTab(v); setPage(0); }} ariaLabel="Shipment stage" className="mb-4" />
      {q.isLoading ? <ListSkeleton rows={3} className="h-28" /> : q.isError ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : !q.data?.content.length ? <EmptyState title="Nothing here" description="No orders at this stage right now." /> : (
        <ul className="space-y-3">{q.data.content.map((o) => (
          <li key={o.id}><Card data-testid="shipment-card"><CardContent className="space-y-3 p-4">
            <div className="flex flex-wrap items-center gap-2">
              <Link href={`/admin/orders/${o.orderNumber}`} className="font-semibold text-primary hover:underline">{o.orderNumber}</Link>
              <StatusBadge kind="order" value={o.status} /><StatusBadge kind="shipment" value={o.shipment?.status} />
              <span className="ml-auto text-xs text-muted-foreground">{enumLabel(o.shippingMethod)} · {formatDateTime(o.createdAt)}</span>
            </div>
            <p className="text-sm"><span className="font-medium">{o.receiverName}</span> · {o.receiverPhone}<br /><span className="text-muted-foreground">{o.shippingAddress}</span></p>
            {o.shipment?.trackingNumber && <p className="text-sm">Tracking: <span className="font-mono">{o.shipment.trackingNumber}</span></p>}
            <OrderActions order={o} />
          </CardContent></Card></li>))}
        </ul>
      )}
      <Pagination page={q.data?.page ?? 0} totalPages={q.data?.totalPages ?? 0} onPage={setPage} />
    </div>
  );
}
