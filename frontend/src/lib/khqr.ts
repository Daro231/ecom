import { parseDate } from "./format";

/** Milliseconds until expiry, measured on the SERVER clock (expiresAt − server time of the response). */
export function remainingFromServer(expiresAt: string, serverTime?: string): number {
  const exp = parseDate(expiresAt)?.getTime();
  const now = parseDate(serverTime)?.getTime();
  if (exp === undefined || now === undefined || Number.isNaN(exp) || Number.isNaN(now)) {
    return exp !== undefined ? exp - Date.now() : 0;
  }
  return exp - now;
}

export function formatCountdown(ms: number): string {
  const s = Math.max(0, Math.ceil(ms / 1000));
  return `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
}

/** Merchant name from the QR: MOCK strings carry `merchant=…`, real KHQR is EMV TLV (tag 59). */
export function merchantName(qr: string): string {
  const mock = /merchant=([^|]+)/i.exec(qr);
  if (mock) return mock[1].trim();
  let i = 0;
  while (i + 4 <= qr.length) {
    const tag = qr.slice(i, i + 2);
    const len = parseInt(qr.slice(i + 2, i + 4), 10);
    if (Number.isNaN(len)) break;
    const val = qr.slice(i + 4, i + 4 + len);
    if (tag === "59") return val.trim();
    i += 4 + len;
  }
  return "ecom";
}

export const QR_EXPIRED_REASON = "QR expired";
