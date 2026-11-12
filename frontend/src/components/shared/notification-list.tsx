"use client";
import * as React from "react";
import { BellOff, CheckCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { EmptyState, ErrorState, ListSkeleton } from "@/components/shared/states";
import { Pagination } from "@/components/shared/pagination";
import { useNotificationMutations, useNotifications } from "@/hooks/use-account";
import { sortNotifications } from "@/lib/notifications";
import { formatDateTime } from "@/lib/format";
import { cn } from "@/lib/utils";

export function NotificationList() {
  const [page, setPage] = React.useState(0);
  const q = useNotifications(page);
  const { markRead, markAll } = useNotificationMutations();
  if (q.isLoading) return <ListSkeleton rows={4} />;
  if (q.isError) return <ErrorState error={q.error} onRetry={() => q.refetch()} />;
  const items = sortNotifications(q.data?.content ?? []);
  const unread = items.filter((n) => !n.read).length;
  return (
    <div>
      <div className="mb-4 flex justify-end">
        <Button variant="outline" size="sm" disabled={unread === 0 || markAll.isPending} onClick={() => markAll.mutate()}><CheckCheck className="h-4 w-4" /> Mark all as read</Button>
      </div>
      {items.length === 0 ? <EmptyState icon={<BellOff className="h-10 w-10" />} title="No notifications" description="Order updates will appear here." /> : (
        <ul className="space-y-2">
          {items.map((n) => (
            <li key={n.id}>
              <button type="button" onClick={() => !n.read && markRead.mutate(n.id)} data-testid="notification" data-priority={n.priority}
                className={cn("flex w-full gap-3 rounded-lg border bg-card p-4 text-left transition hover:border-primary focus-visible:ring-2 focus-visible:ring-ring", !n.read && "border-l-4 border-l-primary bg-accent/40", n.priority === "HIGH" && "border-l-4 border-l-red-600")}>
                <span className={cn("mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full", n.priority === "HIGH" ? "bg-red-600" : n.read ? "bg-transparent" : "bg-primary")} aria-label={n.priority === "HIGH" ? "High priority" : n.read ? "Read" : "Unread"} />
                <span className="min-w-0 flex-1">
                  <span className="flex flex-wrap items-center gap-2"><span className="font-semibold">{n.title}</span>{n.priority === "HIGH" && <span className="rounded bg-red-600 px-1.5 text-[10px] font-bold uppercase text-white">Urgent</span>}</span>
                  <span className="block text-sm text-muted-foreground">{n.message}</span>
                  <span className="text-xs text-muted-foreground">{formatDateTime(n.createdAt)}</span>
                </span>
              </button>
            </li>
          ))}
        </ul>
      )}
      <Pagination page={q.data?.page ?? 0} totalPages={q.data?.totalPages ?? 0} onPage={setPage} />
    </div>
  );
}
