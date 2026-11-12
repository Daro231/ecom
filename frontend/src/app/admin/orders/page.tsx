"use client";
import * as React from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { Search } from "lucide-react";
import { Input, Select } from "@/components/ui/input";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { EmptyState, ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { Pagination } from "@/components/shared/pagination";
import { StatusBadge } from "@/components/shared/status-badge";
import { useDebounced } from "@/hooks/use-debounced";
import { adminService } from "@/services/admin";
import { ORDER_STATUSES } from "@/lib/constants";
import { enumLabel, formatDateTime, formatUSD } from "@/lib/format";

export default function AdminOrdersPage() {
  const [kw, setKw] = React.useState("");
  const keyword = useDebounced(kw, 350);
  const [status, setStatus] = React.useState("");
  const [from, setFrom] = React.useState("");
  const [to, setTo] = React.useState("");
  const [page, setPage] = React.useState(0);
  const q = useQuery({ queryKey: ["admin-orders", keyword, status, from, to, page], queryFn: () => adminService.orders({ keyword, status, from, to, page, size: 15 }) });
  const reset = (fn: () => void) => { fn(); setPage(0); };
  return (
    <div>
      <PageHeader title="Orders" />
      <div className="mb-4 flex flex-wrap items-end gap-2">
        <div className="relative min-w-56 flex-1"><Search className="pointer-events-none absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" /><Input aria-label="Search orders" className="pl-9" placeholder="Order number or customer…" value={kw} onChange={(e) => reset(() => setKw(e.target.value))} /></div>
        <Select aria-label="Status" className="w-44" value={status} onChange={(e) => reset(() => setStatus(e.target.value))}><option value="">All statuses</option>{ORDER_STATUSES.map((s) => <option key={s} value={s}>{enumLabel(s)}</option>)}</Select>
        <label className="text-sm">From <Input type="date" className="mt-1 w-40" value={from} max={to || undefined} onChange={(e) => reset(() => setFrom(e.target.value))} /></label>
        <label className="text-sm">To <Input type="date" className="mt-1 w-40" value={to} min={from || undefined} onChange={(e) => reset(() => setTo(e.target.value))} /></label>
      </div>
      {q.isLoading ? <ListSkeleton rows={6} className="h-12" /> : q.isError ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : !q.data?.content.length ? <EmptyState title="No orders match" /> : (
        <div className="rounded-lg border bg-card">
          <Table aria-label="Orders">
            <THead><TR><TH>Order</TH><TH>Customer</TH><TH>Date</TH><TH>Total</TH><TH>Status</TH><TH>Payment</TH></TR></THead>
            <TBody>{q.data.content.map((o) => (
              <TR key={o.id} data-testid="admin-order-row">
                <TD><Link className="font-semibold text-primary hover:underline" href={`/admin/orders/${o.orderNumber}`}>{o.orderNumber}</Link></TD>
                <TD><p>{o.receiverName}</p><p className="text-xs text-muted-foreground">{o.customerEmail}</p></TD>
                <TD className="whitespace-nowrap">{formatDateTime(o.createdAt)}</TD><TD className="font-medium">{formatUSD(o.total)}</TD>
                <TD><StatusBadge kind="order" value={o.status} /></TD><TD><div className="flex flex-col items-start gap-1"><StatusBadge kind="payment" value={o.payment?.status} /><span className="text-xs text-muted-foreground">{enumLabel(o.paymentMethod)}</span></div></TD>
              </TR>))}
            </TBody>
          </Table>
        </div>
      )}
      <Pagination page={q.data?.page ?? 0} totalPages={q.data?.totalPages ?? 0} onPage={setPage} />
    </div>
  );
}
