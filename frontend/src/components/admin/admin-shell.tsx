"use client";
import * as React from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { BarChart3, Boxes, CreditCard, FolderTree, Menu, MessageSquare, Package, ShoppingBag, Store, Tag, Ticket, Truck, Users, X, AlertOctagon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AuthGuard } from "@/components/shared/auth-guard";
import { LogoutButton } from "@/components/shared/logout-button";
import { ThemeToggle } from "@/components/shared/theme-toggle";
import { NotificationBell } from "@/components/store/notification-bell";
import { notificationService } from "@/services/notification";
import { useAuthStore } from "@/store/authStore";
import { canAccess, navFor } from "@/lib/admin-nav";
import { cn } from "@/lib/utils";

const ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  dashboard: BarChart3, products: Package, categories: FolderTree, brands: Tag, inventory: Boxes,
  orders: ShoppingBag, shipments: Truck, payments: CreditCard, coupons: Ticket, reviews: MessageSquare, users: Users,
};

function UrgentBanner({ isAdmin }: { isAdmin: boolean }) {
  const q = useQuery({ queryKey: ["notifications", 0], queryFn: () => notificationService.list(0, 20), refetchInterval: 30_000 });
  const urgent = (q.data?.content ?? []).filter((n) => n.priority === "HIGH" && !n.read);
  if (urgent.length === 0) return null;
  return (
    <Link href={isAdmin ? "/admin/payments" : "/admin/orders"} data-testid="urgent-banner" className="flex items-center gap-2 bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700">
      <AlertOctagon className="h-4 w-4 shrink-0" />
      <span className="min-w-0 flex-1 truncate">{urgent.length} urgent: {urgent[0].title}</span>
      <span className="underline">{isAdmin ? "Open payments" : "Open orders"}</span>
    </Link>
  );
}

function Shell({ children }: { children: React.ReactNode }) {
  const path = usePathname();
  const router = useRouter();
  const user = useAuthStore((s) => s.user);
  const [open, setOpen] = React.useState(false);
  const nav = navFor(user?.role);
  React.useEffect(() => setOpen(false), [path]);
  React.useEffect(() => {
    if (user && !canAccess(path, user.role)) router.replace("/admin/orders");
  }, [path, user, router]);
  if (user && !canAccess(path, user.role)) return null;

  const sidebar = (
    <div className="flex h-full flex-col bg-navy text-slate-200">
      <div className="flex h-16 items-center gap-2 px-5 text-lg font-extrabold text-white">
        <span className="flex h-8 w-8 items-center justify-center rounded-md bg-brand text-navy">e</span> ecom admin
      </div>
      <nav aria-label="Admin" className="flex-1 space-y-1 overflow-y-auto px-3 py-2">
        {nav.map((n) => {
          const Icon = ICONS[n.icon] ?? Package;
          const active = path === n.href || path.startsWith(n.href + "/");
          return (
            <Link key={n.href} href={n.href} aria-current={active ? "page" : undefined}
              className={cn("flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium focus-visible:ring-2 focus-visible:ring-brand", active ? "bg-brand text-navy" : "hover:bg-white/10")}>
              <Icon className="h-4 w-4" /> {n.label}
            </Link>
          );
        })}
      </nav>
      <div className="space-y-1 border-t border-white/10 p-3">
        <Link href="/" className="flex items-center gap-3 rounded-md px-3 py-2 text-sm hover:bg-white/10"><Store className="h-4 w-4" /> View store</Link>
        <p className="truncate px-3 pt-1 text-xs text-slate-400">{user?.fullName} · {user?.role}</p>
        <LogoutButton className="w-full text-inherit hover:bg-white/10" />
      </div>
    </div>
  );

  return (
    <div className="flex min-h-screen">
      <aside className="no-print sticky top-0 hidden h-screen w-60 shrink-0 lg:block">{sidebar}</aside>
      {open && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div className="absolute inset-0 bg-black/60" onClick={() => setOpen(false)} aria-hidden />
          <div className="relative h-full w-64">{sidebar}</div>
        </div>
      )}
      <div className="flex min-w-0 flex-1 flex-col">
        <UrgentBanner isAdmin={user?.role === "ADMIN"} />
        <header className="no-print flex h-14 items-center gap-2 border-b bg-card px-4">
          <Button variant="ghost" size="icon" className="lg:hidden" onClick={() => setOpen((o) => !o)} aria-label={open ? "Close menu" : "Open menu"}>{open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}</Button>
          <span className="font-semibold lg:hidden">ecom admin</span>
          <div className="ml-auto flex items-center gap-1"><ThemeToggle /><NotificationBell /></div>
        </header>
        <main className="flex-1 p-4 md:p-6">{children}</main>
      </div>
    </div>
  );
}

export function AdminShell({ children }: { children: React.ReactNode }) {
  return <AuthGuard staffOnly><Shell>{children}</Shell></AuthGuard>;
}
