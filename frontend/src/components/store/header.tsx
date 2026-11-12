"use client";
import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import * as Popover from "@radix-ui/react-popover";
import { LayoutDashboard, Package, Search, ShoppingCart, User as UserIcon, MapPin, KeyRound } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ThemeToggle } from "@/components/shared/theme-toggle";
import { LogoutButton } from "@/components/shared/logout-button";
import { NotificationBell } from "./notification-bell";
import { useAuthStore, isStaffRole } from "@/store/authStore";
import { useBadgeStore } from "@/store/badgeStore";
import { useCart } from "@/hooks/use-cart";

export function Header() {
  const router = useRouter();
  const { token, user, hydrated } = useAuthStore();
  const cartCount = useBadgeStore((s) => s.cartCount);
  useCart();
  const [q, setQ] = React.useState("");
  const loggedIn = hydrated && !!token && !!user;

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    const kw = q.trim();
    router.push(kw ? `/products?keyword=${encodeURIComponent(kw)}` : "/products");
  };
  return (
    <header className="no-print sticky top-0 z-40 bg-navy text-white shadow">
      <div className="container flex h-16 items-center gap-3">
        <Link href="/" className="flex items-center gap-2 text-xl font-extrabold tracking-tight" aria-label="ecom home">
          <span className="flex h-8 w-8 items-center justify-center rounded-md bg-brand text-navy">e</span>
          <span className="hidden sm:inline">ecom</span>
        </Link>
        <form onSubmit={submit} role="search" className="relative mx-2 hidden max-w-xl flex-1 md:block">
          <label htmlFor="site-search" className="sr-only">Search products</label>
          <Search className="pointer-events-none absolute left-3 top-2.5 h-5 w-5 text-slate-400" />
          <input
            id="site-search"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search laptops, monitors, parts…"
            className="h-10 w-full rounded-md bg-white/10 pl-10 pr-3 text-sm text-white placeholder:text-slate-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
          />
        </form>
        <nav className="ml-auto flex items-center gap-1" aria-label="Main">
          <Link href="/products" className="hidden rounded-md px-3 py-2 text-sm font-medium hover:bg-white/10 sm:block">Shop</Link>
          <ThemeToggle className="text-inherit hover:bg-white/10" />
          {loggedIn && <NotificationBell />}
          <Link href="/cart" aria-label={`Cart${cartCount ? `, ${cartCount} items` : ""}`} className="relative flex h-9 w-9 items-center justify-center rounded-md hover:bg-white/10">
            <ShoppingCart className="h-5 w-5" />
            {cartCount > 0 && (
              <span data-testid="cart-badge" className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-brand px-1 text-[10px] font-bold text-navy">
                {cartCount}
              </span>
            )}
          </Link>
          {loggedIn ? (
            <Popover.Root>
              <Popover.Trigger asChild>
                <Button variant="ghost" className="gap-2 px-2 text-inherit hover:bg-white/10" aria-label="Account menu">
                  <UserIcon className="h-5 w-5" />
                  <span className="hidden max-w-[8rem] truncate text-sm lg:inline">{user.fullName}</span>
                </Button>
              </Popover.Trigger>
              <Popover.Portal>
                <Popover.Content align="end" sideOffset={8} className="z-50 w-56 rounded-lg border bg-card p-1.5 text-card-foreground shadow-lg">
                  <div className="px-2 py-1.5 text-xs text-muted-foreground">{user.email}</div>
                  {isStaffRole(user.role) && <MenuLink href="/admin/dashboard" icon={<LayoutDashboard className="h-4 w-4" />}>Admin panel</MenuLink>}
                  <MenuLink href="/orders" icon={<Package className="h-4 w-4" />}>My orders</MenuLink>
                  <MenuLink href="/profile" icon={<UserIcon className="h-4 w-4" />}>Profile</MenuLink>
                  <MenuLink href="/profile/addresses" icon={<MapPin className="h-4 w-4" />}>Addresses</MenuLink>
                  <MenuLink href="/profile/password" icon={<KeyRound className="h-4 w-4" />}>Password</MenuLink>
                  <div className="my-1 border-t" />
                  <LogoutButton className="w-full" />
                </Popover.Content>
              </Popover.Portal>
            </Popover.Root>
          ) : (
            <>
              <Button asChild variant="ghost" size="sm" className="text-inherit hover:bg-white/10"><Link href="/login">Log in</Link></Button>
              <Button asChild size="sm"><Link href="/register">Sign up</Link></Button>
            </>
          )}
        </nav>
      </div>
      <form onSubmit={submit} role="search" className="container pb-3 md:hidden">
        <label htmlFor="site-search-m" className="sr-only">Search products</label>
        <input id="site-search-m" value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search products…" className="h-10 w-full rounded-md bg-white/10 px-3 text-sm text-white placeholder:text-slate-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand" />
      </form>
    </header>
  );
}

function MenuLink({ href, icon, children }: { href: string; icon: React.ReactNode; children: React.ReactNode }) {
  return (
    <Popover.Close asChild>
      <Link href={href} className="flex items-center gap-2 rounded-md px-2 py-2 text-sm hover:bg-accent">
        {icon} {children}
      </Link>
    </Popover.Close>
  );
}
