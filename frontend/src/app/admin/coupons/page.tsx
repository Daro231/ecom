"use client";
import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Pencil, Plus, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Field, Input, Select } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { EmptyState, ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { Pagination } from "@/components/shared/pagination";
import { useAdminAction } from "@/hooks/use-admin-action";
import { adminService } from "@/services/admin";
import { ApiError } from "@/lib/api-error";
import { formatDate, formatUSD } from "@/lib/format";
import type { Coupon, CouponInput } from "@/types";

const num = (label: string) => z.string().refine((v) => v.trim() === "" || (!Number.isNaN(Number(v)) && Number(v) >= 0), `${label} must be a number ≥ 0`);
const couponSchema = z.object({
  code: z.string().trim().min(3, "At least 3 characters").regex(/^[A-Za-z0-9_-]+$/, "Letters, numbers, - and _ only"),
  discountType: z.enum(["PERCENT", "FIXED"]),
  value: z.string().refine((v) => v.trim() !== "" && Number(v) > 0, "Value must be greater than 0"),
  minOrderAmount: num("Minimum amount"),
  maxUses: z.string().refine((v) => v.trim() === "" || (Number.isInteger(Number(v)) && Number(v) > 0), "Whole number greater than 0"),
  startAt: z.string(), endAt: z.string(), active: z.boolean(),
}).refine((v) => v.discountType !== "PERCENT" || Number(v.value) <= 100, { path: ["value"], message: "Percent cannot exceed 100" })
  .refine((v) => !v.startAt || !v.endAt || v.startAt <= v.endAt, { path: ["endAt"], message: "End must be after start" });
type Values = z.infer<typeof couponSchema>;

const toLocal = (s?: string) => (s ? s.slice(0, 16) : "");
const toApi = (s: string) => (s ? `${s}:00` : undefined);
function toCouponInput(v: Values): CouponInput {
  return {
    code: v.code.trim().toUpperCase(), discountType: v.discountType, value: Number(v.value),
    minOrderAmount: v.minOrderAmount.trim() === "" ? undefined : Number(v.minOrderAmount),
    maxUses: v.maxUses.trim() === "" ? undefined : Number(v.maxUses), startAt: toApi(v.startAt), endAt: toApi(v.endAt), active: v.active,
  };
}

function CouponDialog({ coupon, onClose }: { coupon: Coupon | null; onClose: () => void }) {
  const { register, handleSubmit, setError, formState: { errors } } = useForm<Values>({
    resolver: zodResolver(couponSchema),
    defaultValues: { code: coupon?.code ?? "", discountType: coupon?.discountType ?? "PERCENT", value: coupon ? String(coupon.value) : "", minOrderAmount: coupon?.minOrderAmount !== undefined ? String(coupon.minOrderAmount) : "", maxUses: coupon?.maxUses !== undefined ? String(coupon.maxUses) : "", startAt: toLocal(coupon?.startAt), endAt: toLocal(coupon?.endAt), active: coupon?.active ?? true },
  });
  const save = useAdminAction((v: Values) => (coupon ? adminService.updateCoupon(coupon.id, toCouponInput(v)) : adminService.createCoupon(toCouponInput(v))), {
    success: coupon ? "Coupon updated" : "Coupon created", invalidate: ["admin-coupons"],
    onError: (e) => { if (e instanceof ApiError && e.status === 409) { setError("code", { message: "This code already exists" }); return "Coupon code already exists"; } },
  });
  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-xl">
        <DialogHeader><DialogTitle>{coupon ? "Edit coupon" : "New coupon"}</DialogTitle></DialogHeader>
        <form noValidate className="grid gap-4 sm:grid-cols-2" onSubmit={handleSubmit(async (v) => { try { await save.mutateAsync(v); onClose(); } catch { /* toast */ } })}>
          <Field label="Code" htmlFor="code" error={errors.code?.message}><Input id="code" className="uppercase" {...register("code")} /></Field>
          <Field label="Type" htmlFor="discountType"><Select id="discountType" {...register("discountType")}><option value="PERCENT">Percent (%)</option><option value="FIXED">Fixed amount ($)</option></Select></Field>
          <Field label="Value" htmlFor="value" error={errors.value?.message}><Input id="value" inputMode="decimal" {...register("value")} /></Field>
          <Field label="Minimum order ($)" htmlFor="minOrderAmount" error={errors.minOrderAmount?.message}><Input id="minOrderAmount" inputMode="decimal" {...register("minOrderAmount")} /></Field>
          <Field label="Max uses" htmlFor="maxUses" error={errors.maxUses?.message} hint="Leave empty for unlimited"><Input id="maxUses" inputMode="numeric" {...register("maxUses")} /></Field>
          <label className="flex items-end gap-2 pb-2 text-sm font-medium"><input type="checkbox" className="h-4 w-4 accent-[hsl(var(--primary))]" {...register("active")} /> Active</label>
          <Field label="Starts" htmlFor="startAt"><Input id="startAt" type="datetime-local" {...register("startAt")} /></Field>
          <Field label="Ends" htmlFor="endAt" error={errors.endAt?.message}><Input id="endAt" type="datetime-local" {...register("endAt")} /></Field>
          <div className="flex justify-end gap-2 sm:col-span-2"><Button variant="outline" onClick={onClose}>Cancel</Button><Button type="submit" disabled={save.isPending}>{save.isPending ? "Saving…" : "Save coupon"}</Button></div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export default function CouponsPage() {
  const [page, setPage] = React.useState(0);
  const [editing, setEditing] = React.useState<Coupon | "new" | null>(null);
  const [del, setDel] = React.useState<Coupon | null>(null);
  const q = useQuery({ queryKey: ["admin-coupons", page], queryFn: () => adminService.coupons(page, 20) });
  const rm = useAdminAction((c: Coupon) => adminService.deleteCoupon(c.id), { success: "Coupon deleted", invalidate: ["admin-coupons"], onError: (e) => (e instanceof ApiError && e.status === 409 ? "This coupon was used by orders. Deactivate it instead." : undefined) });
  return (
    <div>
      <PageHeader title="Coupons" actions={<Button onClick={() => setEditing("new")}><Plus className="h-4 w-4" /> New coupon</Button>} />
      {q.isLoading ? <ListSkeleton rows={4} className="h-12" /> : q.isError ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : !q.data?.content.length ? <EmptyState title="No coupons yet" /> : (
        <div className="rounded-lg border bg-card">
          <Table aria-label="Coupons">
            <THead><TR><TH>Code</TH><TH>Discount</TH><TH>Min order</TH><TH>Used</TH><TH>Valid</TH><TH>Status</TH><TH className="text-right">Actions</TH></TR></THead>
            <TBody>{q.data.content.map((c) => (
              <TR key={c.id} data-testid="coupon-row">
                <TD className="font-mono font-semibold">{c.code}</TD>
                <TD>{c.discountType === "PERCENT" ? `${c.value}%` : formatUSD(c.value)}</TD>
                <TD>{c.minOrderAmount ? formatUSD(c.minOrderAmount) : "—"}</TD>
                <TD>{c.usedCount}{c.maxUses ? ` / ${c.maxUses}` : ""}</TD>
                <TD className="whitespace-nowrap text-xs">{c.startAt || c.endAt ? `${formatDate(c.startAt)} → ${formatDate(c.endAt)}` : "Always"}</TD>
                <TD><Badge tone={c.active ? "green" : "gray"}>{c.active ? "Active" : "Inactive"}</Badge></TD>
                <TD><div className="flex justify-end gap-1">
                  <Button size="icon" variant="ghost" aria-label={`Edit ${c.code}`} onClick={() => setEditing(c)}><Pencil className="h-4 w-4" /></Button>
                  <Button size="icon" variant="ghost" className="text-destructive" aria-label={`Delete ${c.code}`} onClick={() => setDel(c)}><Trash2 className="h-4 w-4" /></Button>
                </div></TD>
              </TR>))}
            </TBody>
          </Table>
        </div>
      )}
      <Pagination page={q.data?.page ?? 0} totalPages={q.data?.totalPages ?? 0} onPage={setPage} />
      {editing && <CouponDialog coupon={editing === "new" ? null : editing} onClose={() => setEditing(null)} />}
      <ConfirmDialog open={!!del} onOpenChange={(o) => !o && setDel(null)} title="Delete coupon?" description={del ? <>Coupon <strong>{del.code}</strong> will be deleted.</> : undefined} confirmLabel="Delete coupon" destructive onConfirm={() => (del ? rm.mutateAsync(del) : undefined)} />
    </div>
  );
}
