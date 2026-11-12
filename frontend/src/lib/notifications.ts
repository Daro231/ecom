import type { AppNotification } from "@/types";

/** HIGH priority first, then unread first, then newest. */
export function sortNotifications(list: AppNotification[]): AppNotification[] {
  return [...list].sort((a, b) => {
    if (a.priority !== b.priority) return a.priority === "HIGH" ? -1 : 1;
    if (a.read !== b.read) return a.read ? 1 : -1;
    return b.createdAt.localeCompare(a.createdAt);
  });
}
