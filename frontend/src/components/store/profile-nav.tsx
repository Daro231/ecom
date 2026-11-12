"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const LINKS = [{ href: "/profile", label: "Profile" }, { href: "/profile/addresses", label: "Addresses" }, { href: "/profile/password", label: "Password" }];
export function ProfileNav() {
  const path = usePathname();
  return (
    <nav aria-label="Profile sections" className="mb-6 flex gap-1 border-b">
      {LINKS.map((l) => (
        <Link key={l.href} href={l.href} aria-current={path === l.href ? "page" : undefined}
          className={cn("-mb-px border-b-2 px-4 py-2 text-sm font-medium", path === l.href ? "border-primary text-primary" : "border-transparent text-muted-foreground hover:text-foreground")}>
          {l.label}
        </Link>
      ))}
    </nav>
  );
}
