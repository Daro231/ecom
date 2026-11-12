import { expect, test, type Page } from "@playwright/test";
import { createOrderViaApi, loginUI } from "./helpers";

const env = (data: unknown, timestamp = "2026-11-05T12:00:00") => ({ success: true, message: "ok", data, timestamp });
const qr = (order: string, expiresAt: string, mode = "MOCK") => env({ orderNumber: order, amount: 12.5, currency: "USD", qrString: `MOCK-KHQR|merchant=ECOM|order=${order}|amount=12.50`, md5: "abc", expiresAt, mode });
const pending = (order: string) => env({ id: 1, orderNumber: order, method: "KHQR", status: "PENDING", amount: 12.5 });

let order = "";
test.beforeAll(async ({ request }) => { order = await createOrderViaApi(request); });

async function open(page: Page) {
  await loginUI(page, "customer");
  await page.goto(`/checkout/pay/${order}`);
}

test("expired QR shows 'QR expired' and Generate new QR gets a fresh one", async ({ page }) => {
  let fresh = false;
  await page.route("**/payments/*/khqr", (r) => r.fulfill({ json: fresh ? qr(order, "2026-11-05T12:10:00") : qr(order, "2026-11-05T12:00:02") }));
  await page.route("**/payments/*/status", (r) => r.fulfill({ json: pending(order) }));
  await open(page);
  await expect(page.getByTestId("qr-expired")).toBeVisible({ timeout: 10_000 });
  fresh = true;
  await page.getByRole("button", { name: "Generate new QR" }).click();
  await expect(page.getByTestId("khqr-countdown")).toHaveText(/^(09|10):\d\d$/);
  await expect(page.getByTestId("qr-expired")).toHaveCount(0);
});

test("504 keeps polling: banner shows, then PAID moves to success", async ({ page }) => {
  let polls = 0;
  await page.route("**/payments/*/khqr", (r) => r.fulfill({ json: qr(order, "2026-11-05T12:10:00") }));
  await page.route("**/payments/*/status", (r) => {
    polls++;
    if (polls <= 2) return r.fulfill({ status: 504, json: { success: false, message: "Bakong timed out", timestamp: "2026-11-05T12:00:00" } });
    return r.fulfill({ json: env({ id: 1, orderNumber: order, method: "KHQR", status: "PAID", amount: 12.5 }) });
  });
  await open(page);
  await expect(page.getByTestId("provider-warning")).toBeVisible({ timeout: 8000 });
  await expect(page.getByTestId("khqr-failed")).toHaveCount(0);
  await expect(page).toHaveURL(/\/checkout\/success\//, { timeout: 15_000 });
  expect(polls).toBeGreaterThanOrEqual(3);
});

test("FAILED shows the failure reason", async ({ page }) => {
  await page.route("**/payments/*/khqr", (r) => r.fulfill({ json: qr(order, "2026-11-05T12:10:00") }));
  await page.route("**/payments/*/status", (r) => r.fulfill({ json: env({ id: 1, orderNumber: order, method: "KHQR", status: "FAILED", amount: 12.5, failureReason: "Amount mismatch: expected 12.50 USD" }) }));
  await open(page);
  await expect(page.getByTestId("khqr-failed")).toContainText("Amount mismatch: expected 12.50 USD", { timeout: 8000 });
  await expect(page.getByRole("button", { name: "Try again" })).toBeVisible();
});

test("BAKONG mode has no Simulate payment button", async ({ page }) => {
  await page.route("**/payments/*/khqr", (r) => r.fulfill({ json: qr(order, "2026-11-05T12:10:00", "BAKONG") }));
  await page.route("**/payments/*/status", (r) => r.fulfill({ json: pending(order) }));
  await open(page);
  await expect(page.locator("canvas")).toBeVisible();
  await expect(page.getByRole("button", { name: "Download QR" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Simulate payment" })).toHaveCount(0);
});
