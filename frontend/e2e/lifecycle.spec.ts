import { expect, test } from "@playwright/test";
import { apiGet, createOrderViaApi, deleteMyReview, loginUI, logoutUI, readState, shot } from "./helpers";

interface Order { status: string; items: { productId: number }[] }
interface Product { id: number; averageRating: number; reviewCount: number; slug: string }

test("full lesson flow: admin fulfils the order, customer reviews it", async ({ page, request }) => {
  // the order paid in purchase.spec.ts, or a fresh paid one when that spec was not run
  let orderNumber = readState().orderNumber;
  if (orderNumber) {
    const o = await apiGet<Order>(request, `/orders/${orderNumber}`, "customer");
    if (o.status !== "CONFIRMED") orderNumber = undefined;
  }
  orderNumber ??= await createOrderViaApi(request, { pay: true });
  console.log("Lifecycle order:", orderNumber);
  const order = await apiGet<Order>(request, `/orders/${orderNumber}`, "customer");
  const productId = order.items[0].productId;
  await deleteMyReview(request, productId); // keep the run repeatable

  // ---- admin ----
  await loginUI(page, "admin");
  await expect(page).toHaveURL(/\/admin\/dashboard/);
  await expect(page.getByTestId("kpi-total-sales")).toBeVisible();
  await shot(page, "20-admin-dashboard");
  await page.goto("/admin/orders");
  await page.getByLabel("Search orders").fill(orderNumber);
  await page.getByRole("link", { name: orderNumber }).click();
  await expect(page.getByTestId("order-number")).toHaveText(orderNumber);
  await expect(page.getByTestId("order-badge")).toHaveText("Confirmed");

  await page.getByRole("button", { name: "Mark processing" }).click();
  await expect(page.getByTestId("order-badge")).toHaveText("Processing");

  await page.getByRole("button", { name: "Ship order" }).click();
  await page.getByLabel("Tracking number").fill(`KH-TRK-${Date.now()}`);
  await page.getByRole("dialog").getByRole("button", { name: "Ship order" }).click();
  await expect(page.getByTestId("order-badge")).toHaveText("Shipped");
  await expect(page.getByTestId("tracking-number")).toContainText("KH-TRK-");

  await page.getByRole("button", { name: "Out for delivery" }).click();
  await expect(page.getByTestId("shipment-badge")).toHaveText("Out for delivery");

  await page.getByRole("button", { name: "Mark delivered" }).click();
  await page.getByRole("alertdialog").getByRole("button", { name: "Mark delivered" }).click();
  await expect(page.getByTestId("order-badge")).toHaveText("Delivered");
  await shot(page, "21-admin-order-delivered");
  await logoutUI(page);

  // ---- customer ----
  const before = await apiGet<Product>(request, `/products/${productId}`);
  await loginUI(page, "customer", `/orders/${orderNumber}`);
  await expect(page.getByTestId("order-badge")).toHaveText("Delivered");
  await page.getByRole("button", { name: "Write review" }).click();
  await page.getByRole("radio", { name: "5 stars" }).click();
  await page.getByLabel("Your review").fill("Excellent, fast delivery!");
  await page.getByRole("button", { name: "Submit review" }).click();
  await expect(page.getByText("Reviewed ✓")).toBeVisible();

  const after = await apiGet<Product>(request, `/products/${productId}`);
  expect(after.reviewCount).toBe(before.reviewCount + 1);
  expect(after.averageRating).toBeGreaterThan(0);
  await page.goto(`/products/${after.slug}`);
  await expect(page.getByText(`${after.averageRating.toFixed(1)} · ${after.reviewCount} review`)).toBeVisible();
  await expect(page.getByText("Excellent, fast delivery!")).toBeVisible();

  await page.goto("/notifications");
  await expect(page.getByTestId("notification").filter({ hasText: /shipped/i }).first()).toBeVisible();
  await expect(page.getByTestId("notification").filter({ hasText: /delivered/i }).first()).toBeVisible();
  await shot(page, "22-notifications");
});
