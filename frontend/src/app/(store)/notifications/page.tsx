"use client";
import { AuthGuard } from "@/components/shared/auth-guard";
import { NotificationList } from "@/components/shared/notification-list";
import { PageHeader } from "@/components/shared/states";

export default function NotificationsPage() {
  return (
    <AuthGuard>
      <div className="mx-auto max-w-[900px]">
        <PageHeader title="Notifications" />
        <NotificationList />
      </div>
    </AuthGuard>
  );
}
