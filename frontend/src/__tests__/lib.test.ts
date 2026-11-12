import { describe, expect, it } from "vitest";
import { enumLabel, formatDate, formatDateTime, formatMoney, formatUSD, parseDate, stockLabel, fileUrl, googleMapsUrl } from "@/lib/format";
import { mapNominatim } from "@/lib/geocoder";
import { computeTotals } from "@/lib/totals";
import { stepError } from "@/lib/checkout-steps";
import { formatCountdown, merchantName, remainingFromServer } from "@/lib/khqr";
import { accuracyWarning, geolocationErrorMessage } from "@/lib/geo";
import { buildTimeline } from "@/lib/timeline";
import { canReview } from "@/lib/reviews";
import { categoryForKeyword } from "@/lib/search";
import { sortNotifications } from "@/lib/notifications";
import { canAccess, navFor } from "@/lib/admin-nav";
import { safeRedirect, homeFor } from "@/lib/redirect";
import { order, payment } from "@/test/fixtures";
import type { AppNotification, ShippingMethod } from "@/types";

describe("format", () => {
  it("formats USD", () => {
    expect(formatUSD(1299)).toBe("$1,299.00");
    expect(formatUSD(0.5)).toBe("$0.50");
    expect(formatUSD(undefined)).toBe("$0.00");
    expect(formatMoney(77.1, "USD")).toBe("$77.10");
    expect(formatMoney(316000, "KHR")).toBe("316,000 KHR");
  });
  it("parses backend local date-times with fractional seconds", () => {
    expect(parseDate("2026-11-04T15:43:17.811457943")?.getFullYear()).toBe(2026);
    expect(parseDate(undefined)).toBeNull();
    expect(parseDate("nope")).toBeNull();
    expect(formatDate("2026-11-04T15:43:17")).toContain("2026");
    expect(formatDateTime(undefined)).toBe("—");
  });
  it("enumLabel gives proper labels, never raw values like Khqr", () => {
    expect(enumLabel("KHQR")).toBe("KHQR");
    expect(enumLabel("CASH_ON_DELIVERY")).toBe("Cash on Delivery");
    expect(enumLabel("CARD")).toBe("Card");
    expect(enumLabel("BANK_TRANSFER")).toBe("Bank Transfer");
    expect(enumLabel("SAME_DAY")).toBe("Same Day");
    expect(enumLabel("STANDARD")).toBe("Standard");
    expect(enumLabel("PAID_AFTER_CANCEL")).toBe("Paid after cancel");
    expect(enumLabel("OUT_FOR_DELIVERY")).toBe("Out for delivery");
    expect(enumLabel("IN_TRANSIT")).toBe("In transit");
    expect(enumLabel("PROCESSING")).toBe("Processing");
    expect(enumLabel("PENDING")).toBe("Pending");
    expect(enumLabel(undefined)).toBe("—");
  });
  it("stock labels", () => {
    expect(stockLabel(0)).toEqual({ text: "Out of stock", tone: "out" });
    expect(stockLabel(3, 5)).toEqual({ text: "Only 3 left", tone: "low" });
    expect(stockLabel(50, 5).tone).toBe("ok");
  });
  it("builds file and map urls", () => {
    expect(fileUrl("/uploads/a.png")).toBe("http://localhost:8080/uploads/a.png");
    expect(fileUrl("https://placehold.co/x")).toBe("https://placehold.co/x");
    expect(fileUrl(undefined)).toBeUndefined();
    expect(googleMapsUrl(11.5, 104.9)).toBe("https://www.google.com/maps?q=11.5,104.9");
  });
});

describe("Nominatim mapping (Cambodia: khan in `town`, city in `state`)", () => {
  it("Khan Sen Sok", () => {
    const r = mapNominatim({ address: { road: "Street 1003", suburb: "Phumi Tuek Thla", town: "Khan Sen Sok", state: "Phnom Penh", "ISO3166-2-lvl4": "KH-12", country: "Cambodia", country_code: "kh" } });
    expect(r).toEqual({ line1: "Street 1003, Phumi Tuek Thla, Khan Sen Sok", city: "Phnom Penh" });
  });
  it("Khan Daun Penh with house number and quarter", () => {
    const r = mapNominatim({ address: { house_number: "12", road: "Street 240", quarter: "Chey Chummeah", town: "Khan Doun Penh", state: "Phnom Penh", country: "Cambodia" } });
    expect(r).toEqual({ line1: "12 Street 240, Chey Chummeah, Khan Doun Penh", city: "Phnom Penh" });
  });
  it("Siem Reap: city wins, no duplicates, never the city in the address line", () => {
    const r = mapNominatim({ address: { road: "Sivutha Boulevard", hamlet: "Phum Mondol 1", suburb: "Sangkat Sala Kamreuk", city: "Siem Reap", county: "Siem Reap", state: "Siem Reap Province", country: "Cambodia" } });
    expect(r.city).toBe("Siem Reap");
    expect(r.line1).toBe("Sivutha Boulevard, Phum Mondol 1, Sangkat Sala Kamreuk");
    expect(r.line1).not.toContain("Siem Reap,");
  });
  it("falls back to province and tolerates empty results", () => {
    expect(mapNominatim({ address: { province: "Kampot", village: "Phum Tuol" } })).toEqual({ line1: "Phum Tuol", city: "Kampot" });
    expect(mapNominatim({})).toEqual({ line1: "", city: "" });
  });
});

describe("cart totals", () => {
  const std: ShippingMethod = { code: "STANDARD", label: "Standard", fee: 5, estimatedDelivery: "3-5 days", freeShippingThreshold: 1000 };
  it("uses the backend coupon preview exactly", () => {
    const t = computeTotals(138, std, { couponCode: "WELCOME10", subtotal: 138, discount: 13.8, shippingFee: 5, total: 129.2 });
    expect(t).toMatchObject({ discount: 13.8, shippingFee: 5, total: 129.2, couponCode: "WELCOME10", fromBackend: true });
  });
  it("derives shipping from backend method data without a coupon", () => {
    expect(computeTotals(69, std)).toMatchObject({ shippingFee: 5, total: 74, discount: 0, fromBackend: false });
    expect(computeTotals(1000, std)).toMatchObject({ shippingFee: 0, total: 1000 });
    expect(computeTotals(69, undefined)).toMatchObject({ shippingFee: null, total: null });
  });
});

describe("checkout stepper validation", () => {
  const ok = { addressId: 1, shippingMethod: "STANDARD" as const, paymentMethod: "KHQR" as const };
  it("requires address, shipping and payment", () => {
    expect(stepError(0, { ...ok, addressId: null })).toMatch(/address/i);
    expect(stepError(0, ok)).toBeNull();
    expect(stepError(1, { ...ok, shippingMethod: null })).toMatch(/shipping/i);
    expect(stepError(2, { ...ok, paymentMethod: null })).toMatch(/payment/i);
    expect(stepError(3, ok)).toBeNull();
  });
});

describe("KHQR helpers", () => {
  it("measures remaining time on the server clock", () => {
    expect(remainingFromServer("2026-11-05T12:10:00", "2026-11-05T12:00:00")).toBe(600_000);
    expect(remainingFromServer("2026-11-05T12:00:02.5", "2026-11-05T12:00:00")).toBe(2500);
    expect(remainingFromServer("2026-11-05T12:00:00", "2026-11-05T12:00:05")).toBe(-5000);
  });
  it("formats countdown", () => {
    expect(formatCountdown(600_000)).toBe("10:00");
    expect(formatCountdown(61_001)).toBe("01:02");
    expect(formatCountdown(-5)).toBe("00:00");
  });
  it("reads the merchant name from MOCK and EMV payloads", () => {
    expect(merchantName("MOCK-KHQR|merchant=ECOM|order=1")).toBe("ECOM");
    const tlv = (tag: string, v: string) => `${tag}${String(v.length).padStart(2, "0")}${v}`;
    const emv = tlv("00", "01") + tlv("01", "12") + tlv("29", tlv("00", "abc@bank")) + tlv("52", "5999") + tlv("53", "840") + tlv("54", "105.00") + tlv("58", "KH") + tlv("59", "Bonin Shop") + tlv("60", "Phnom Penh") + "6304ABCD";
    expect(merchantName(emv)).toBe("Bonin Shop");
    expect(merchantName("garbage")).toBe("ecom");
  });
});

describe("geolocation helpers", () => {
  it("warns only when accuracy is worse than 100 m", () => {
    expect(accuracyWarning(25)).toBeNull();
    expect(accuracyWarning(100)).toBeNull();
    expect(accuracyWarning(250)).toBe("Your location is approximate (±250 m). Please drag the pin to your exact location.");
    expect(accuracyWarning(2500)).toBe("Your location is approximate (±2,500 m / ±2.5 km). Please drag the pin to your exact location.");
  });
  it("explains errors", () => {
    expect(geolocationErrorMessage(1)).toMatch(/denied/i);
    expect(geolocationErrorMessage(2)).toMatch(/unavailable/i);
    expect(geolocationErrorMessage(3)).toMatch(/too long/i);
  });
});

describe("order helpers", () => {
  it("timeline for a delivered order", () => {
    const t = buildTimeline(order({ status: "DELIVERED", shipment: { id: 1, orderNumber: "x", method: "EXPRESS", fee: 15, status: "DELIVERED", shippedAt: "2026-11-05T10:00:00", deliveredAt: "2026-11-05T12:00:00" } }));
    expect(t.map((s) => s.state)).toEqual(["done", "done", "done", "done", "done"]);
    expect(t[4].at).toBe("2026-11-05T12:00:00");
  });
  it("timeline for a cancelled order shows the reason", () => {
    const t = buildTimeline(order({ status: "CANCELLED", cancelledReason: "KHQR payment timeout" }));
    expect(t.map((s) => s.key)).toEqual(["PENDING", "CANCELLED"]);
    expect(t[1]).toMatchObject({ state: "cancelled", note: "KHQR payment timeout" });
  });
  it("timeline marks the current step", () => {
    const t = buildTimeline(order({ status: "PROCESSING" }));
    expect(t.find((s) => s.state === "current")?.key).toBe("PROCESSING");
  });
  it("canReview needs a delivered order and no existing review", () => {
    const delivered = [order({ status: "DELIVERED" })];
    const mine = [{ id: 1, productId: 29, productName: "", userId: 3, userName: "", rating: 5, verifiedPurchase: true, visible: true, createdAt: "" }];
    expect(canReview(delivered, 29, [], 3)).toBe(true);
    expect(canReview(delivered, 29, mine, 3)).toBe(false);
    expect(canReview([order({ status: "SHIPPED" })], 29, [], 3)).toBe(false);
    expect(canReview(delivered, 99, [], 3)).toBe(false);
    expect(canReview(undefined, 29, [], 3)).toBe(false);
  });
});

describe("search / notifications / nav / redirect", () => {
  const cats = [{ id: 1, name: "Laptop", slug: "laptop" }, { id: 3, name: "Monitor", slug: "monitor" }];
  it("keyword equal to a category name becomes a category filter", () => {
    expect(categoryForKeyword("laptop", cats)?.id).toBe(1);
    expect(categoryForKeyword(" Laptop ", cats)?.id).toBe(1);
    expect(categoryForKeyword("monitors", cats)?.id).toBe(3);
    expect(categoryForKeyword("gaming laptop", cats)).toBeUndefined();
    expect(categoryForKeyword("", cats)).toBeUndefined();
  });
  it("notifications: HIGH first, then unread, then newest", () => {
    const n = (id: number, priority: "HIGH" | "NORMAL", read: boolean, createdAt: string): AppNotification => ({ id, type: "PUSH", title: "t", message: "m", read, createdAt, priority });
    const sorted = sortNotifications([n(1, "NORMAL", true, "2026-01-03"), n(2, "NORMAL", false, "2026-01-01"), n(3, "HIGH", true, "2026-01-01"), n(4, "NORMAL", false, "2026-01-02")]);
    expect(sorted.map((x) => x.id)).toEqual([3, 4, 2, 1]);
  });
  it("staff menu is Inventory, Orders, Shipments only", () => {
    expect(navFor("STAFF").map((n) => n.label)).toEqual(["Inventory", "Orders", "Shipments"]);
    expect(navFor("ADMIN").length).toBe(11);
    expect(canAccess("/admin/users", "STAFF")).toBe(false);
    expect(canAccess("/admin/orders/ECOM-1", "STAFF")).toBe(true);
    expect(canAccess("/admin/payments", "ADMIN")).toBe(true);
  });
  it("redirect safety", () => {
    expect(safeRedirect("/orders")).toBe("/orders");
    expect(safeRedirect("//evil.com")).toBeUndefined();
    expect(safeRedirect("https://evil.com")).toBeUndefined();
    expect(safeRedirect("/login")).toBeUndefined();
    expect(homeFor("ADMIN")).toBe("/admin/dashboard");
    expect(homeFor("STAFF")).toBe("/admin/orders");
    expect(homeFor("CUSTOMER")).toBe("/");
  });
  it("payment fixture sanity", () => expect(payment().status).toBe("PENDING"));
});
