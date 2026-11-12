"use client";
import * as React from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { Info } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { Tabs } from "@/components/ui/tabs";
import { EmptyState, ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { Pagination } from "@/components/shared/pagination";
import { StatusBadge } from "@/components/shared/status-badge";
import { PaymentActions } from "@/components/admin/payment-actions";
import { adminService } from "@/services/admin";
import { enumLabel, formatDateTime, formatUSD } from "@/lib/format";
import type { Payment } from "@/types";

const TABS = [
  { value: "", label: "All" },
  { value: "PAID_AFTER_CANCEL", label: "Paid after cancel" },
  { value: "PENDING", label: "Pending" },
  { value: "PAID", label: "Paid" },
  { value: "FAILED", label: "Failed" },
  { value: "REFUNDED", label: "Refunded" },
];
const METHODS = ["KHQR", "CASH_ON_DELIVERY", "CARD", "BANK_TRANSFER"];

function Detail({ p, onClose }: { p: Payment; onClose: () => void }) {
  const rows: [string, React.ReactNode][] = [
    ["Order", p.orderNumber], ["Method", enumLabel(p.method)], ["Status", <StatusBadge key="s" kind="payment" value={p.status} />], ["Amount", formatUSD(p.amount)],
    ["Transaction reference / hash", p.transactionRef ? <span className="break-all font-mono text-xs">{p.transactionRef}</span> : "—"],
    ["Paid at", formatDateTime(p.paidAt)], ["Failure reason", p.failureReason ?? "—"],
  ];
  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent>
        <DialogHeader><DialogTitle>Payment #{p.id}</DialogTitle></DialogHeader>
        <dl className="divide-y text-sm">{rows.map(([k, v]) => <div key={k} className="flex justify-between gap-4 py-2"><dt className="text-muted-foreground">{k}</dt><dd className="text-right font-medium">{v}</dd></div>)}</dl>
        <PaymentActions payment={p} orderNumber={p.orderNumber} size="default" />
      </DialogContent>
    </Dialog>
  );
}

export default function PaymentsPage() {
  const [tab, setTab] = React.useState("");
  const [method, setMethod] = React.useState("");
  const [page, setPage] = React.useState(0);
  const [detail, setDetail] = React.useState<Payment | null>(null);
  const q = useQuery({ queryKey: ["admin-payments", tab, page], queryFn: () => adminService.payments({ status: tab || undefined, page, size: 20 }), refetchInterval: 30_000 });
  const late = useQuery({ queryKey: ["admin-payments-late"], queryFn: () => adminService.payments({ status: "PAID_AFTER_CANCEL", page: 0, size: 1 }), refetchInterval: 30_000 });
  const rows = (q.data?.content ?? []).filter((p) => !method || p.method === method);
  const items = TABS.map((t) => (t.value === "PAID_AFTER_CANCEL" ? { ...t, count: late.data?.totalElements ?? 0 } : t));
  return (
    <div>
      <PageHeader title="Payments" actions={<Select aria-label="Payment method" className="w-48" value={method} onChange={(e) => setMethod(e.target.value)}><option value="">All methods</option>{METHODS.map((m) => <option key={m} value={m}>{enumLabel(m)}</option>)}</Select>} />
      <Tabs items={items} value={tab} onChange={(v) => { setTab(v); setPage(0); }} ariaLabel="Payment status" className="mb-4" />
      {tab === "PAID_AFTER_CANCEL" && <p className="mb-3 flex items-start gap-2 rounded-md bg-red-50 p-3 text-sm text-red-900 dark:bg-red-950/40 dark:text-red-100"><Info className="mt-0.5 h-4 w-4 shrink-0" /> These customers paid after the order was auto-cancelled. Restore the order (if stock allows) or refund the payment.</p>}
      {q.isLoading ? <ListSkeleton rows={6} className="h-12" /> : q.isError ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : rows.length === 0 ? <EmptyState title="No payments found" /> : (
        <div className="rounded-lg border bg-card">
          <Table aria-label="Payments">
            <THead><TR><TH>Order</TH><TH>Method</TH><TH>Status</TH><TH>Amount</TH><TH>Paid at</TH><TH>Failure reason</TH><TH className="text-right">Actions</TH></TR></THead>
            <TBody>{rows.map((p) => (
              <TR key={p.id} data-testid="payment-row" data-status={p.status}>
                <TD><Link className="font-semibold text-primary hover:underline" href={`/admin/orders/${p.orderNumber}`}>{p.orderNumber}</Link></TD>
                <TD>{enumLabel(p.method)}</TD><TD><StatusBadge kind="payment" value={p.status} /></TD><TD className="font-medium">{formatUSD(p.amount)}</TD>
                <TD className="whitespace-nowrap">{formatDateTime(p.paidAt)}</TD><TD className="max-w-[200px] truncate text-muted-foreground">{p.failureReason ?? "—"}</TD>
                <TD><div className="flex items-center justify-end gap-1"><PaymentActions payment={p} orderNumber={p.orderNumber} /><Button size="sm" variant="ghost" onClick={() => setDetail(p)}>Details</Button></div></TD>
              </TR>))}
            </TBody>
          </Table>
        </div>
      )}
      {method && <p className="mt-2 text-xs text-muted-foreground">Method filter applies to the current page (the API filters by status only).</p>}
      <Pagination page={q.data?.page ?? 0} totalPages={q.data?.totalPages ?? 0} onPage={setPage} />
      {detail && <Detail p={detail} onClose={() => setDetail(null)} />}
    </div>
  );
}
