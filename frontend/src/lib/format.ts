const usd = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" });
export function formatUSD(n: number | undefined | null): string {
  return usd.format(Number(n ?? 0));
}
export function formatMoney(n: number, currency = "USD"): string {
  if (currency === "USD") return formatUSD(n);
  return `${new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 }).format(n)} ${currency}`;
}

/** Backend timestamps are local date-times without zone (maybe with fractional seconds). */
export function parseDate(s?: string | null): Date | null {
  if (!s) return null;
  const d = new Date(s.length > 23 ? s.slice(0, 23) : s);
  return Number.isNaN(d.getTime()) ? null : d;
}
export function formatDate(s?: string | null): string {
  const d = parseDate(s);
  return d ? d.toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" }) : "—";
}
export function formatDateTime(s?: string | null): string {
  const d = parseDate(s);
  return d
    ? d.toLocaleString("en-US", { year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })
    : "—";
}

const LABELS: Record<string, string> = {
  KHQR: "KHQR",
  CASH_ON_DELIVERY: "Cash on Delivery",
  CARD: "Card",
  BANK_TRANSFER: "Bank Transfer",
  STANDARD: "Standard",
  EXPRESS: "Express",
  SAME_DAY: "Same Day",
  PAID_AFTER_CANCEL: "Paid after cancel",
  OUT_FOR_DELIVERY: "Out for delivery",
  IN_TRANSIT: "In transit",
  COD: "Cash on Delivery",
};
/** Human label for any backend enum value; never returns raw values like "Khqr". */
export function enumLabel(v?: string | null): string {
  if (!v) return "—";
  if (LABELS[v]) return LABELS[v];
  const w = v.toLowerCase().split("_").join(" ");
  return w.charAt(0).toUpperCase() + w.slice(1);
}

export function stockLabel(stock: number, threshold = 5): { text: string; tone: "ok" | "low" | "out" } {
  if (stock <= 0) return { text: "Out of stock", tone: "out" };
  if (stock <= threshold) return { text: `Only ${stock} left`, tone: "low" };
  return { text: "In stock", tone: "ok" };
}

export function fileUrl(path?: string | null): string | undefined {
  if (!path) return undefined;
  if (/^https?:\/\//i.test(path)) return path;
  return `${process.env.NEXT_PUBLIC_FILE_URL ?? "http://localhost:8080"}${path.startsWith("/") ? "" : "/"}${path}`;
}

export function googleMapsUrl(lat: number, lng: number): string {
  return `https://www.google.com/maps?q=${lat},${lng}`;
}
export function toDateParam(d: Date): string {
  const p = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}
