import { expect, type APIRequestContext, type Page } from "@playwright/test";
import fs from "node:fs";
import path from "node:path";

export const API = "http://localhost:8080/api/v1";
export const ACCOUNTS = {
  customer: { email: "customer@ecom.com", password: "Customer@123" },
  admin: { email: "admin@ecom.com", password: "Admin@123" },
  staff: { email: "staff@ecom.com", password: "Staff@123" },
};
export const STATE_FILE = path.join(__dirname, ".state.json");
export const SHOTS = path.join(__dirname, "..", "screenshots");

export async function apiToken(request: APIRequestContext, who: keyof typeof ACCOUNTS): Promise<string> {
  const res = await request.post(`${API}/auth/login`, { data: ACCOUNTS[who] });
  expect(res.ok(), `login ${who}`).toBeTruthy();
  return (await res.json()).data.accessToken;
}
const auth = (t: string) => ({ Authorization: `Bearer ${t}` });

/** Repeatable runs: empty the customer's cart first. */
export async function clearCart(request: APIRequestContext) {
  const t = await apiToken(request, "customer");
  const res = await request.delete(`${API}/cart`, { headers: auth(t) });
  expect(res.ok(), "DELETE /cart").toBeTruthy();
}

export async function ensureAddress(request: APIRequestContext): Promise<number> {
  const t = await apiToken(request, "customer");
  const list = (await (await request.get(`${API}/users/me/addresses`, { headers: auth(t) })).json()).data as { id: number }[];
  if (list.length) return list[0].id;
  const res = await request.post(`${API}/users/me/addresses`, { headers: auth(t), data: { receiverName: "Demo Customer", phone: "012345678", line1: "No. 12, Street 271, Toul Kork", city: "Phnom Penh", isDefault: true } });
  return (await res.json()).data.id;
}

/** Create + (optionally) pay an order through the API. */
export async function createOrderViaApi(request: APIRequestContext, opts: { pay?: boolean; method?: string } = {}): Promise<string> {
  const t = await apiToken(request, "customer");
  await clearCart(request);
  const products = (await (await request.get(`${API}/products?inStock=true&size=5&sort=price_asc`)).json()).data.content as { id: number }[];
  await request.post(`${API}/cart/items`, { headers: auth(t), data: { productId: products[0].id, quantity: 1 } });
  const addressId = await ensureAddress(request);
  const res = await request.post(`${API}/orders/checkout`, { headers: auth(t), data: { addressId, shippingMethod: "STANDARD", paymentMethod: opts.method ?? "KHQR" } });
  expect(res.ok(), "checkout").toBeTruthy();
  const order = (await res.json()).data;
  if (opts.pay) {
    const cb = await request.post(`${API}/payments/callback`, { data: { transactionRef: `E2E-${Date.now()}`, orderNumber: order.orderNumber, status: "PAID" } });
    expect(cb.ok(), "callback").toBeTruthy();
  }
  console.log("Order created via API:", order.orderNumber);
  return order.orderNumber;
}

export async function loginUI(page: Page, who: keyof typeof ACCOUNTS, redirect?: string) {
  await page.goto(redirect ? `/login?redirect=${encodeURIComponent(redirect)}` : "/login");
  await page.getByLabel("Email").fill(ACCOUNTS[who].email);
  await page.getByLabel("Password", { exact: true }).fill(ACCOUNTS[who].password);
  await page.getByRole("button", { name: "Log in" }).click();
  await expect(page).not.toHaveURL(/\/login/);
}

export async function logoutUI(page: Page) {
  // customer header menu or admin sidebar
  const logout = page.getByRole("button", { name: "Log out" }).first();
  const menu = page.getByRole("button", { name: "Account menu" });
  if (!(await logout.isVisible().catch(() => false)) && (await menu.isVisible().catch(() => false))) await menu.click();
  await logout.click();
  await page.getByRole("alertdialog").getByRole("button", { name: "Log out" }).click();
  await expect(page).toHaveURL(/\/login/);
}

export function readState(): { orderNumber?: string } {
  try { return JSON.parse(fs.readFileSync(STATE_FILE, "utf8")); } catch { return {}; }
}
export function writeState(s: object) { fs.writeFileSync(STATE_FILE, JSON.stringify(s)); }
export async function shot(page: Page, name: string) {
  await page.waitForLoadState("networkidle").catch(() => undefined);
  await page.waitForFunction(() => [...document.images].every((i) => i.complete)).catch(() => undefined);
  await page.screenshot({ path: path.join(SHOTS, `${name}.png`), fullPage: true });
}

export async function deleteMyReview(request: APIRequestContext, productId: number) {
  const t = await apiToken(request, "customer");
  const me = (await (await request.get(`${API}/users/me`, { headers: auth(t) })).json()).data;
  const reviews = (await (await request.get(`${API}/products/${productId}/reviews?size=100`)).json()).data.content as { id: number; userId: number }[];
  for (const r of reviews.filter((x) => x.userId === me.id)) await request.delete(`${API}/reviews/${r.id}`, { headers: auth(t) });
}
export async function apiGet<T>(request: APIRequestContext, url: string, who?: keyof typeof ACCOUNTS): Promise<T> {
  const headers = who ? auth(await apiToken(request, who)) : undefined;
  return (await (await request.get(`${API}${url}`, { headers })).json()).data as T;
}
