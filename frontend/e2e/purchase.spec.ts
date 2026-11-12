import { expect, test } from "@playwright/test";
import { clearCart, ensureAddress, loginUI, shot, writeState } from "./helpers";

test("customer buys a laptop with a coupon and pays with KHQR", async ({ page, request }) => {
  await clearCart(request);
  await ensureAddress(request);
  await loginUI(page, "customer");

  // search "laptop" -> exact category name becomes a removable Laptop chip
  await page.getByRole("searchbox").or(page.locator("#site-search")).first().fill("laptop");
  await page.keyboard.press("Enter");
  await expect(page).toHaveURL(/categoryId=/);
  await expect(page).not.toHaveURL(/keyword=/);
  await expect(page.getByTestId("chip-cat")).toContainText("Laptop");
  await expect(page.getByTestId("product-card").first()).toBeVisible();
  await shot(page, "02-products-laptop");

  // product -> add to cart
  await page.getByTestId("product-card").first().click();
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  await shot(page, "03-product-detail");
  await page.getByRole("button", { name: "Add to cart" }).click();
  await expect(page.getByTestId("cart-badge")).toHaveText("1");

  // cart + coupon WELCOME10
  await page.goto("/cart");
  await page.getByLabel("Coupon code").fill("WELCOME10");
  await page.getByRole("button", { name: "Apply" }).click();
  await expect(page.getByTestId("coupon-applied")).toContainText("WELCOME10");
  await expect(page.getByTestId("sum-discount")).toBeVisible();
  await shot(page, "04-cart");

  // checkout: address -> shipping -> payment (KHQR) -> review
  await page.getByRole("link", { name: "Proceed to checkout" }).click();
  await expect(page.getByRole("heading", { name: "Delivery address" })).toBeVisible();
  await shot(page, "05-checkout-address");
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByLabel(/Standard/).check();
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByLabel(/KHQR/).check();
  await page.getByRole("button", { name: "Continue" }).click();
  await expect(page.getByRole("heading", { name: /Review/ })).toBeVisible();
  await shot(page, "06-checkout-review");
  await page.getByRole("button", { name: "Place order" }).click();

  // KHQR page (mock mode): QR, header, simulate
  await expect(page).toHaveURL(/\/checkout\/pay\/ECOM-/);
  const orderNumber = page.url().split("/").pop() as string;
  console.log("Order placed in UI:", orderNumber);
  await expect(page.getByText("KHQR", { exact: true }).first()).toBeVisible();
  await expect(page.locator("canvas")).toBeVisible();
  await expect(page.getByTestId("khqr-countdown")).toBeVisible();
  await shot(page, "07-khqr-payment");
  await page.getByRole("button", { name: "Simulate payment" }).click();

  await expect(page).toHaveURL(/\/checkout\/success\//);
  await expect(page.getByTestId("success-title")).toHaveText("Payment received!");
  await shot(page, "08-order-success");
  writeState({ orderNumber });

  await page.getByRole("link", { name: "View order" }).click();
  await expect(page.getByTestId("order-badge")).toHaveText("Confirmed");
  await expect(page.getByTestId("payment-badge")).toHaveText("Paid");
  await expect(page.getByText("KHQR").first()).toBeVisible();
  await shot(page, "09-order-detail");
});
