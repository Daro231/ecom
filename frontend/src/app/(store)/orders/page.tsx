"use client";
import * as React from "react";
import Link from "next/link";
import { PackageOpen } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Tabs } from "@/components/ui/tabs";
import { AuthGuard } from "@/components/shared/auth-guard";
import { EmptyState, ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { StatusBadge } from "@/components/shared/status-badge";
import { Pagination } from "@/components/shared/pagination";
import { useOrders } from "@/hooks/use-account";
import { ORDER_STATUSES } from "@/lib/constants";
import { enumLabel, formatDate, formatUSD } from "@/lib/format";

function OrdersContent() {
  const [page, setPage] = React.useState(0);
  const [tab, setTab] = React.useState("ALL");
  const q = useOrders(page);
  const all = q.data?.content ?? [];
  const list = tab === "ALL" ? all : all.filter((o) => o.status === tab);
  const items = [{ value: "ALL", label: "All", count: all.length }, ...ORDER_STATUSES.map((s) => ({ value: s, label: enumLabel(s), count: all.filter((o) => o.status === s).length }))];

  if (q.isLoading) return <ListSkeleton rows={4} />;
  if (q.isError) return <ErrorState error={q.error} onRetry={() => q.refetch()} />;
  return (
    <>
      <Tabs items={items} value={tab} onChange={setTab} ariaLabel="Order status" className="mb-4" />
      {list.length === 0 ? (
        <EmptyState icon={<PackageOpen className="h-10 w-10" />} title={tab === "ALL" ? "No orders yet" : `No ${enumLabel(tab).toLowerCase()} orders`} description="Your orders will show up here." action={<Button asChild><Link href="/products">Start shopping</Link></Button>} />
      ) : (
        <ul className="space-y-3">
          {list.map((o) => (
            <li key={o.id}>
              <Link href={`/orders/${o.orderNumber}`} data-testid="order-row" className="block rounded-lg border bg-card p-4 transition hover:border-primary focus-visible:ring-2 focus-visible:ring-ring">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="font-semibold">{o.orderNumber}</span>
                  <StatusBadge kind="order" value={o.status} />
                  <StatusBadge kind="payment" value={o.payment?.status} />
                  <span className="ml-auto font-bold">{formatUSD(o.total)}</span>
                </div>
                <p className="mt-1 text-sm text-muted-foreground">{formatDate(o.createdAt)} · {o.items.reduce((n, i) => n + i.quantity, 0)} item(s) · {enumLabel(o.paymentMethod)}</p>
                <p className="mt-1 line-clamp-1 text-sm">{o.items.map((i) => i.productName).join(", ")}</p>
              </Link>
            </li>
          ))}
        </ul>
      )}
      <Pagination page={q.data?.page ?? 0} totalPages={q.data?.totalPages ?? 0} onPage={setPage} />
    </>
  );
}

export default function OrdersPage() {
  return (
    <AuthGuard>
      <div className="mx-auto max-w-[900px]">
        <PageHeader title="My orders" />
        <OrdersContent />
      </div>
    </AuthGuard>
  );
}
