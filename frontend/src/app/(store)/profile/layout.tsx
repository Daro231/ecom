"use client";
import { AuthGuard } from "@/components/shared/auth-guard";
import { ProfileNav } from "@/components/store/profile-nav";
import { PageHeader } from "@/components/shared/states";

export default function ProfileLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard>
      <div className="mx-auto max-w-[900px]">
        <PageHeader title="My account" />
        <ProfileNav />
        {children}
      </div>
    </AuthGuard>
  );
}
