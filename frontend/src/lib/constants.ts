export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080/api/v1";
export const FILE_URL = process.env.NEXT_PUBLIC_FILE_URL ?? "http://localhost:8080";
export const PROMO_COUPON = process.env.NEXT_PUBLIC_PROMO_COUPON ?? "";
export const NOMINATIM_CONTACT = process.env.NEXT_PUBLIC_NOMINATIM_CONTACT ?? "";

export const TOKEN_COOKIE = "ecom_token";
export const ROLE_COOKIE = "ecom_role";
export const AUTH_STORAGE_KEY = "ecom-auth";

export const PHNOM_PENH: [number, number] = [11.5564, 104.9282];
export const KHQR_POLL_MS = 3000;
export const RAM_OPTIONS = [8, 16, 32, 64];
export const CATEGORY_NAMES = ["laptop", "desktop", "monitor", "component", "accessory"];
export const ORDER_STATUSES = ["PENDING", "CONFIRMED", "PROCESSING", "SHIPPED", "DELIVERED", "CANCELLED"] as const;
export const CANCELLABLE = ["PENDING", "CONFIRMED", "PROCESSING"];
export const NEXT_STATUSES: Record<string, string[]> = {
  PENDING: ["CONFIRMED", "CANCELLED"],
  CONFIRMED: ["PROCESSING", "CANCELLED"],
  PROCESSING: ["CANCELLED"],
  SHIPPED: [],
  DELIVERED: [],
  CANCELLED: [],
};
export const SORT_OPTIONS = [
  { value: "newest", label: "Newest" },
  { value: "price_asc", label: "Price: low to high" },
  { value: "price_desc", label: "Price: high to low" },
  { value: "rating", label: "Top rated" },
  { value: "popular", label: "Most popular" },
];
