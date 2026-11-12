import { get, patch } from "@/lib/api";
import type { AppNotification, PageResponse } from "@/types";

export const notificationService = {
  list: (page = 0, size = 20) => get<PageResponse<AppNotification>>("/notifications", { page, size }),
  unreadCount: () => get<number>("/notifications/unread-count"),
  markRead: (id: number) => patch<AppNotification>(`/notifications/${id}/read`),
  markAllRead: () => patch<number>("/notifications/read-all"),
};
