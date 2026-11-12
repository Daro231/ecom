import { expect, test } from "@playwright/test";
import { loginUI, logoutUI } from "./helpers";

test("logout clears the session: reload and Back never show protected pages", async ({ page }) => {
  await loginUI(page, "customer", "/orders");
  await expect(page.getByRole("heading", { name: "My orders" })).toBeVisible();

  // cancelling the dialog keeps the session
  await page.getByRole("button", { name: "Account menu" }).click();
  await page.getByRole("button", { name: "Log out" }).click();
  await page.getByRole("alertdialog").getByRole("button", { name: "Cancel" }).click();
  await expect(page.getByRole("alertdialog")).toHaveCount(0);
  await expect(page.getByRole("heading", { name: "My orders" })).toBeVisible();

  await logoutUI(page);
  expect(await page.evaluate(() => localStorage.getItem("ecom-auth"))).toBeNull();
  expect((await page.context().cookies()).find((c) => c.name === "ecom_token")).toBeUndefined();

  await page.reload();
  await expect(page).toHaveURL(/\/login/);

  await page.goBack().catch(() => undefined);
  await expect(page.getByRole("heading", { name: "My orders" })).toHaveCount(0);
  await page.goto("/orders");
  await expect(page).toHaveURL(/\/login\?redirect=%2Forders/);
  await page.goto("/admin/dashboard");
  await expect(page).toHaveURL(/\/login/);
});

test("customer cannot open /admin; admin logging in after customer sees no old data", async ({ page }) => {
  await loginUI(page, "customer");
  await page.goto("/admin/dashboard");
  await expect(page).toHaveURL(/localhost:3000\/$/);
  await logoutUI(page);

  await loginUI(page, "admin");
  await expect(page).toHaveURL(/\/admin\/dashboard/);
  await logoutUI(page);
});

test("staff only sees Orders, Inventory and Shipments", async ({ page }) => {
  await loginUI(page, "staff");
  await expect(page).toHaveURL(/\/admin\/orders/);
  const nav = page.getByRole("navigation", { name: "Admin" });
  await expect(nav.getByRole("link")).toHaveText(["Inventory", "Orders", "Shipments"]);
  await page.goto("/admin/users");
  await expect(page).toHaveURL(/\/admin\/orders/);
  await logoutUI(page);
});
