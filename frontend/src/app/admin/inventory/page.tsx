"use client";
import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { History, PackagePlus, Search, SlidersHorizontal } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Field, Input, Textarea } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { Tabs } from "@/components/ui/tabs";
import { EmptyState, ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { Pagination } from "@/components/shared/pagination";
import { useAdminAction } from "@/hooks/use-admin-action";
import { useDebounced } from "@/hooks/use-debounced";
import { adminService } from "@/services/admin";
import { enumLabel, formatDateTime } from "@/lib/format";
import type { InventoryItem } from "@/types";

type Mode = "restock" | "adjust";
const restockSchema = z.object({ amount: z.string().refine((v) => Number.isInteger(Number(v)) && Number(v) > 0, "Enter a whole number greater than 0"), note: z.string() });
const adjustSchema = z.object({ amount: z.string().refine((v) => Number.isInteger(Number(v)) && Number(v) !== 0, "Enter a whole number, not 0 (negative removes stock)"), note: z.string().min(3, "A note is required for adjustments") });

function StockDialog({ item, mode, onClose }: { item: InventoryItem; mode: Mode; onClose: () => void }) {
  const { register, handleSubmit, formState: { errors } } = useForm<{ amount: string; note: string }>({ resolver: zodResolver(mode === "restock" ? restockSchema : adjustSchema), defaultValues: { amount: "", note: "" } });
  const act = useAdminAction(
    (v: { amount: string; note: string }) => (mode === "restock" ? adminService.restock(item.productId, { quantity: Number(v.amount), note: v.note || undefined }) : adminService.adjust(item.productId, { delta: Number(v.amount), note: v.note })),
    { success: (r) => `Stock is now ${r.stockQuantity}`, invalidate: ["admin-inventory", "admin-inventory-logs", "admin-dashboard"] },
  );
  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent>
        <DialogHeader><DialogTitle>{mode === "restock" ? "Restock" : "Adjust stock"} — {item.name}</DialogTitle></DialogHeader>
        <p className="text-sm text-muted-foreground">Current stock: <strong>{item.stockQuantity}</strong></p>
        <form noValidate className="space-y-4" onSubmit={handleSubmit(async (v) => { try { await act.mutateAsync(v); onClose(); } catch { /* toast */ } })}>
          <Field label={mode === "restock" ? "Quantity to add" : "Change (+/−)"} htmlFor="amount" error={errors.amount?.message}><Input id="amount" inputMode="numeric" {...register("amount")} /></Field>
          <Field label={mode === "restock" ? "Note (optional)" : "Note"} htmlFor="note" error={errors.note?.message}><Textarea id="note" rows={2} {...register("note")} /></Field>
          <div className="flex justify-end gap-2"><Button variant="outline" onClick={onClose}>Cancel</Button><Button type="submit" disabled={act.isPending}>{act.isPending ? "Saving…" : mode === "restock" ? "Add stock" : "Apply"}</Button></div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function LogsDialog({ item, onClose }: { item: InventoryItem; onClose: () => void }) {
  const [page, setPage] = React.useState(0);
  const q = useQuery({ queryKey: ["admin-inventory-logs", item.productId, page], queryFn: () => adminService.inventoryLogs(item.productId, page) });
  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-2xl">
        <DialogHeader><DialogTitle>Stock history — {item.name}</DialogTitle></DialogHeader>
        {q.isLoading ? <ListSkeleton rows={4} className="h-10" /> : q.isError ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : q.data?.content.length === 0 ? <p className="py-6 text-center text-muted-foreground">No history yet</p> : (
          <>
            <Table aria-label="Inventory log"><THead><TR><TH>When</TH><TH>Reason</TH><TH>Change</TH><TH>Stock after</TH><TH>Note</TH></TR></THead>
              <TBody>{q.data?.content.map((l) => (
                <TR key={l.id}><TD className="whitespace-nowrap">{formatDateTime(l.createdAt)}</TD><TD>{enumLabel(l.reason)}</TD>
                  <TD className={l.changeQuantity < 0 ? "font-semibold text-red-600" : "font-semibold text-green-600"}>{l.changeQuantity > 0 ? `+${l.changeQuantity}` : l.changeQuantity}</TD><TD>{l.stockAfter}</TD><TD className="text-muted-foreground">{l.note ?? "—"}</TD></TR>
              ))}</TBody></Table>
            <Pagination page={q.data?.page ?? 0} totalPages={q.data?.totalPages ?? 0} onPage={setPage} />
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}

export default function InventoryPage() {
  const [tab, setTab] = React.useState("all");
  const [kw, setKw] = React.useState("");
  const keyword = useDebounced(kw, 350);
  const [page, setPage] = React.useState(0);
  const [dlg, setDlg] = React.useState<{ item: InventoryItem; kind: Mode | "logs" } | null>(null);
  const all = useQuery({ queryKey: ["admin-inventory", keyword, page], queryFn: () => adminService.inventory({ keyword, page, size: 20 }), enabled: tab === "all" });
  const low = useQuery({ queryKey: ["admin-inventory", "low"], queryFn: adminService.lowStock });
  const q = tab === "all" ? all : low;
  const rows = tab === "all" ? all.data?.content : low.data;

  return (
    <div>
      <PageHeader title="Inventory" description="Stock levels, restocks and adjustments" />
      <Tabs ariaLabel="Inventory views" className="mb-4" value={tab} onChange={(v) => { setTab(v); setPage(0); }} items={[{ value: "all", label: "All products" }, { value: "low", label: "Low stock", count: low.data?.length }]} />
      {tab === "all" && <div className="relative mb-4 max-w-sm"><Search className="pointer-events-none absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" /><Input aria-label="Search inventory" className="pl-9" placeholder="Search name or SKU…" value={kw} onChange={(e) => { setKw(e.target.value); setPage(0); }} /></div>}
      {q.isLoading ? <ListSkeleton rows={6} className="h-12" /> : q.isError ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : !rows?.length ? <EmptyState title={tab === "low" ? "No low-stock products" : "No products found"} /> : (
        <div className="rounded-lg border bg-card">
          <Table aria-label="Stock">
            <THead><TR><TH>Product</TH><TH>Category</TH><TH>Stock</TH><TH>Threshold</TH><TH className="text-right">Actions</TH></TR></THead>
            <TBody>{rows.map((i) => (
              <TR key={i.productId} data-testid="inventory-row" data-lowstock={i.lowStock} className={i.lowStock ? "bg-red-50 hover:bg-red-50 dark:bg-red-950/30 dark:hover:bg-red-950/40" : ""}>
                <TD><p className="font-medium">{i.name}</p><p className="text-xs text-muted-foreground">{i.sku}</p></TD><TD>{i.category}</TD>
                <TD><span className="flex items-center gap-2 font-semibold">{i.stockQuantity}{i.lowStock && <Badge tone="red">Low</Badge>}</span></TD><TD>{i.lowStockThreshold}</TD>
                <TD><div className="flex justify-end gap-1">
                  <Button size="sm" variant="outline" onClick={() => setDlg({ item: i, kind: "restock" })}><PackagePlus className="h-4 w-4" /> Restock</Button>
                  <Button size="sm" variant="outline" onClick={() => setDlg({ item: i, kind: "adjust" })}><SlidersHorizontal className="h-4 w-4" /> Adjust</Button>
                  <Button size="icon" variant="ghost" aria-label={`History for ${i.name}`} onClick={() => setDlg({ item: i, kind: "logs" })}><History className="h-4 w-4" /></Button>
                </div></TD>
              </TR>))}
            </TBody>
          </Table>
        </div>
      )}
      {tab === "all" && <Pagination page={all.data?.page ?? 0} totalPages={all.data?.totalPages ?? 0} onPage={setPage} />}
      {dlg && dlg.kind !== "logs" && <StockDialog item={dlg.item} mode={dlg.kind} onClose={() => setDlg(null)} />}
      {dlg && dlg.kind === "logs" && <LogsDialog item={dlg.item} onClose={() => setDlg(null)} />}
    </div>
  );
}
