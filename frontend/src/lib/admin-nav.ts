import type { Role } from "@/types";

export interface AdminNavItem { href: string; label: string; roles: Role[]; icon: string }
export const ADMIN_NAV: AdminNavItem[] = [
  { href: "/admin/dashboard", label: "Dashboard", roles: ["ADMIN"], icon: "dashboard" },
  { href: "/admin/products", label: "Products", roles: ["ADMIN"], icon: "products" },
  { href: "/admin/categories", label: "Categories", roles: ["ADMIN"], icon: "categories" },
  { href: "/admin/brands", label: "Brands", roles: ["ADMIN"], icon: "brands" },
  { href: "/admin/inventory", label: "Inventory", roles: ["ADMIN", "STAFF"], icon: "inventory" },
  { href: "/admin/orders", label: "Orders", roles: ["ADMIN", "STAFF"], icon: "orders" },
  { href: "/admin/shipments", label: "Shipments", roles: ["ADMIN", "STAFF"], icon: "shipments" },
  { href: "/admin/payments", label: "Payments", roles: ["ADMIN"], icon: "payments" },
  { href: "/admin/coupons", label: "Coupons", roles: ["ADMIN"], icon: "coupons" },
  { href: "/admin/reviews", label: "Reviews", roles: ["ADMIN"], icon: "reviews" },
  { href: "/admin/users", label: "Users", roles: ["ADMIN"], icon: "users" },
];
export function navFor(role?: Role) {
  return ADMIN_NAV.filter((n) => role && n.roles.includes(role));
}
export function canAccess(path: string, role?: Role): boolean {
  if (!role) return false;
  const item = ADMIN_NAV.find((n) => path === n.href || path.startsWith(n.href + "/"));
  return !item || item.roles.includes(role);
}
