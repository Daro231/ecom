/** Only allow same-site relative redirects. */
export function safeRedirect(r?: string | null): string | undefined {
  if (!r || !r.startsWith("/") || r.startsWith("//") || r.startsWith("/login") || r.startsWith("/register")) return undefined;
  return r;
}
export function homeFor(role?: string): string {
  if (role === "ADMIN") return "/admin/dashboard";
  if (role === "STAFF") return "/admin/orders";
  return "/";
}
