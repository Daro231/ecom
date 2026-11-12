"use client";
import * as React from "react";
import Link from "next/link";
import * as Popover from "@radix-ui/react-popover";
import { Bell } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useNotificationMutations, useNotifications, useUnreadCount } from "@/hooks/use-account";
import { useBadgeStore } from "@/store/badgeStore";
import { formatDateTime } from "@/lib/format";
import { sortNotifications } from "@/lib/notifications";
import { cn } from "@/lib/utils";

export function NotificationBell({ href = "/notifications" }: { href?: string }) {
  useUnreadCount();
  const unread = useBadgeStore((s) => s.unreadCount);
  const [open, setOpen] = React.useState(false);
  const { data } = useNotifications(0);
  const { markRead, markAll } = useNotificationMutations();
  const items = sortNotifications(data?.content ?? []).slice(0, 6);
  return (
    <Popover.Root open={open} onOpenChange={setOpen}>
      <Popover.Trigger asChild>
        <Button variant="ghost" size="icon" className="relative text-inherit hover:bg-white/10" aria-label={`Notifications${unread ? `, ${unread} unread` : ""}`}>
          <Bell className="h-5 w-5" />
          {unread > 0 && (
            <span data-testid="unread-badge" className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-red-600 px-1 text-[10px] font-bold text-white">
              {unread > 99 ? "99+" : unread}
            </span>
          )}
        </Button>
      </Popover.Trigger>
      <Popover.Portal>
        <Popover.Content align="end" sideOffset={8} className="z-50 w-80 rounded-lg border bg-card p-2 text-card-foreground shadow-lg">
          <div className="flex items-center justify-between px-2 py-1">
            <span className="text-sm font-semibold">Notifications</span>
            <Button variant="link" size="sm" disabled={unread === 0} onClick={() => markAll.mutate()}>
              Mark all read
            </Button>
          </div>
          <ul className="max-h-80 overflow-y-auto">
            {items.length === 0 && <li className="px-2 py-6 text-center text-sm text-muted-foreground">No notifications yet</li>}
            {items.map((n) => (
              <li key={n.id}>
                <button
                  type="button"
                  onClick={() => !n.read && markRead.mutate(n.id)}
                  className={cn("flex w-full gap-2 rounded-md px-2 py-2 text-left hover:bg-accent", !n.read && "bg-accent/50")}
                >
                  <span className={cn("mt-1.5 h-2 w-2 shrink-0 rounded-full", n.priority === "HIGH" ? "bg-red-600" : n.read ? "bg-transparent" : "bg-primary")} aria-hidden />
                  <span className="min-w-0">
                    <span className="block truncate text-sm font-medium">{n.title}</span>
                    <span className="line-clamp-2 text-xs text-muted-foreground">{n.message}</span>
                    <span className="text-[11px] text-muted-foreground">{formatDateTime(n.createdAt)}</span>
                  </span>
                </button>
              </li>
            ))}
          </ul>
          <Link href={href} onClick={() => setOpen(false)} className="mt-1 block rounded-md px-2 py-2 text-center text-sm font-medium text-primary hover:bg-accent">
            View all
          </Link>
        </Popover.Content>
      </Popover.Portal>
    </Popover.Root>
  );
}
