"use client";
import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { Eye, EyeOff, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { EmptyState, ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { Pagination } from "@/components/shared/pagination";
import { Stars } from "@/components/shared/rating";
import { useAdminAction } from "@/hooks/use-admin-action";
import { adminService } from "@/services/admin";
import { formatDate } from "@/lib/format";
import type { Review } from "@/types";

export default function AdminReviewsPage() {
  const [page, setPage] = React.useState(0);
  const [del, setDel] = React.useState<Review | null>(null);
  const q = useQuery({ queryKey: ["admin-reviews", page], queryFn: () => adminService.reviews(page, 20) });
  const vis = useAdminAction((r: Review) => adminService.setReviewVisible(r.id, !r.visible), { success: (r) => (r.visible ? "Review is visible" : "Review hidden"), invalidate: ["admin-reviews", "reviews", "product"] });
  const rm = useAdminAction((r: Review) => adminService.deleteReview(r.id), { success: "Review deleted", invalidate: ["admin-reviews", "reviews", "product"] });
  return (
    <div>
      <PageHeader title="Reviews" />
      {q.isLoading ? <ListSkeleton rows={5} className="h-14" /> : q.isError ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : !q.data?.content.length ? <EmptyState title="No reviews yet" /> : (
        <div className="rounded-lg border bg-card">
          <Table aria-label="Reviews">
            <THead><TR><TH>Product</TH><TH>Customer</TH><TH>Rating</TH><TH>Comment</TH><TH>Date</TH><TH>Status</TH><TH className="text-right">Actions</TH></TR></THead>
            <TBody>{q.data.content.map((r) => (
              <TR key={r.id} data-testid="review-row">
                <TD className="max-w-[180px] truncate font-medium">{r.productName}</TD><TD>{r.userName}</TD><TD><Stars value={r.rating} size={14} /></TD>
                <TD className="max-w-[260px] truncate text-muted-foreground">{r.comment ?? "—"}</TD><TD className="whitespace-nowrap">{formatDate(r.createdAt)}</TD>
                <TD><Badge tone={r.visible ? "green" : "gray"}>{r.visible ? "Visible" : "Hidden"}</Badge></TD>
                <TD><div className="flex justify-end gap-1">
                  <Button size="sm" variant="outline" onClick={() => vis.mutate(r)} disabled={vis.isPending}>{r.visible ? <><EyeOff className="h-4 w-4" /> Hide</> : <><Eye className="h-4 w-4" /> Show</>}</Button>
                  <Button size="icon" variant="ghost" className="text-destructive" aria-label={`Delete review by ${r.userName}`} onClick={() => setDel(r)}><Trash2 className="h-4 w-4" /></Button>
                </div></TD>
              </TR>))}
            </TBody>
          </Table>
        </div>
      )}
      <Pagination page={q.data?.page ?? 0} totalPages={q.data?.totalPages ?? 0} onPage={setPage} />
      <ConfirmDialog open={!!del} onOpenChange={(o) => !o && setDel(null)} title="Delete review?" description="The review is removed permanently and the product rating is recalculated." confirmLabel="Delete review" destructive onConfirm={() => (del ? rm.mutateAsync(del) : undefined)} />
    </div>
  );
}
