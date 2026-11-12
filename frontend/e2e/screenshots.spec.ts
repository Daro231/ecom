import { expect, test } from "@playwright/test";
import { API, apiGet, apiToken, clearCart, createOrderViaApi, loginUI, logoutUI, shot } from "./helpers";

interface Product { id: number; slug: string }
interface Order { orderNumber: string }

test.describe.configure({ mode: "serial" });

test("public pages", async ({ page }) => {
  await page.goto("/login");
  await expect(page.getByRole("heading", { name: "Log in" })).toBeVisible();
  await shot(page, "01-login");
  await page.goto("/register");
  await shot(page, "01-register");
  await page.goto("/");
  await expect(page.getByTestId("promo-code")).toBeVisible();
  await expect(page.getByTestId("product-card").first()).toBeVisible();
  await shot(page, "01-home");
  await page.goto("/products");
  await expect(page.getByTestId("product-card").first()).toBeVisible();
  await shot(page, "02-products");
});

test("dark mode and mobile layouts", async ({ browser }) => {
  const dark = await browser.newContext({ colorScheme: "dark", viewport: { width: 1280, height: 900 } });
  const p1 = await dark.newPage();
  await p1.addInitScript(() => localStorage.setItem("theme", "dark"));
  await p1.goto("/");
  await expect(p1.locator("html")).toHaveClass(/dark/);
  await shot(p1, "30-home-dark");
  await dark.close();
  const mobile = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p2 = await mobile.newPage();
  await p2.goto("/products");
  await expect(p2.getByTestId("product-card").first()).toBeVisible();
  const overflow = await p2.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  expect(overflow).toBeLessThanOrEqual(1); // no horizontal scroll on phones
  await shot(p2, "31-products-mobile");
  await mobile.close();
});

test("customer pages", async ({ page, request }) => {
  await clearCart(request);
  const products = await apiGet<{ content: Product[] }>(request, "/products?inStock=true&size=3");
  const t = await apiToken(request, "customer");
  await request.post(`${API}/cart/items`, { headers: { Authorization: `Bearer ${t}` }, data: { productId: products.content[0].id, quantity: 1 } });
  const pending = await createOrderViaApi(request); // leaves the cart empty, order waiting for KHQR payment
  await request.post(`${API}/cart/items`, { headers: { Authorization: `Bearer ${t}` }, data: { productId: products.content[0].id, quantity: 1 } });
  const orders = await apiGet<{ content: Order[] }>(request, "/orders?size=5", "customer");

  await loginUI(page, "customer");
  await page.goto(`/products/${products.content[0].slug}`);
  await expect(page.getByRole("button", { name: "Add to cart" })).toBeVisible();
  await shot(page, "03-product-detail");
  await page.goto("/cart");
  await expect(page.getByTestId("cart-item")).toHaveCount(1);
  await shot(page, "04-cart");
  await page.goto("/checkout");
  await expect(page.getByRole("heading", { name: "Delivery address" })).toBeVisible();
  await shot(page, "05-checkout");
  await page.goto(`/checkout/pay/${pending}`);
  await expect(page.locator("canvas")).toBeVisible();
  await shot(page, "07-khqr-payment");
  await page.goto("/orders");
  await expect(page.getByTestId("order-row").first()).toBeVisible();
  await shot(page, "10-orders");
  await page.goto(`/orders/${pending}`);
  await expect(page.getByRole("link", { name: /Pay now/ })).toBeVisible();
  await shot(page, "09-order-detail-unpaid");
  await page.goto(`/orders/${orders.content[0].orderNumber}/invoice`);
  await expect(page.getByRole("article", { name: "Invoice" })).toBeVisible();
  await shot(page, "11-invoice");
  for (const [route, name] of [["/profile", "12-profile"], ["/profile/addresses", "13-addresses"], ["/profile/password", "14-password"], ["/notifications", "16-notifications"]] as const) {
    await page.goto(route);
    await page.waitForTimeout(400);
    await shot(page, name);
  }
  await clearCart(request);
});

test("admin panel pages", async ({ page, request }) => {
  const products = await apiGet<{ content: Product[] }>(request, "/products?size=1");
  const orders = await apiGet<{ content: Order[] }>(request, "/admin/orders?size=1", "admin");
  await loginUI(page, "admin");
  const pages: [string, string, string][] = [
    ["/admin/dashboard", "20-admin-dashboard", "Dashboard"],
    ["/admin/products", "21-admin-products", "Products"],
    ["/admin/products/new", "21-admin-product-new", "New product"],
    [`/admin/products/${products.content[0].id}`, "21-admin-product-edit", "Edit"],
    ["/admin/categories", "22-admin-categories", "Categories"],
    ["/admin/brands", "22-admin-brands", "Brands"],
    ["/admin/inventory", "23-admin-inventory", "Inventory"],
    ["/admin/orders", "24-admin-orders", "Orders"],
    [`/admin/orders/${orders.content[0].orderNumber}`, "24-admin-order-detail", orders.content[0].orderNumber],
    ["/admin/shipments", "24-admin-shipments", "Shipments"],
    ["/admin/payments", "25-admin-payments", "Payments"],
    ["/admin/coupons", "26-admin-coupons", "Coupons"],
    ["/admin/reviews", "27-admin-reviews", "Reviews"],
    ["/admin/users", "28-admin-users", "Users"],
  ];
  for (const [route, name, heading] of pages) {
    await page.goto(route);
    await expect(page.getByRole("heading", { name: new RegExp(heading) }).first()).toBeVisible();
    await page.waitForTimeout(600);
    await shot(page, name);
  }
  await logoutUI(page);
});
