import * as React from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { addressModule, adminModule, authModule, orderModule } from "@/test/mocks";
import { page, setDefaults } from "@/test/defaults";
import { renderIn } from "@/test/render";
import { address, admin, customer, order, payment, product } from "@/test/fixtures";
import { mockNav } from "@/test/nav";
import { ApiError } from "@/lib/api-error";
import { logout } from "@/lib/session";

vi.mock("@/services/auth", async () => (await import("@/test/mocks")).authModule);
vi.mock("@/services/product", async () => (await import("@/test/mocks")).productModule);
vi.mock("@/services/cart", async () => (await import("@/test/mocks")).cartModule);
vi.mock("@/services/order", async () => (await import("@/test/mocks")).orderModule);
vi.mock("@/services/payment", async () => (await import("@/test/mocks")).paymentModule);
vi.mock("@/services/address", async () => (await import("@/test/mocks")).addressModule);
vi.mock("@/services/notification", async () => (await import("@/test/mocks")).notificationModule);
vi.mock("@/services/review", async () => (await import("@/test/mocks")).reviewModule);
vi.mock("@/services/admin", async () => (await import("@/test/mocks")).adminModule);
vi.mock("@/lib/session", async (orig) => ({ ...(await orig<typeof import("@/lib/session")>()), logout: vi.fn() }));
vi.mock("@/components/shared/address-map-loader", () => ({ StaticMap: () => <div data-testid="static-map" />, AddressMap: () => <div /> }));

const A = adminModule.adminService;
const click = (el: HTMLElement) => userEvent.click(el);

/** cancel does nothing and closes; confirm runs the action and closes. */
async function dialogFlow(o: { open: () => Promise<void>; confirm: string; cancel?: string; action: ReturnType<typeof vi.fn>; before?: (dlg: HTMLElement) => Promise<void>; args?: unknown[] }) {
  await o.open();
  let dlg = await screen.findByRole("alertdialog");
  await click(within(dlg).getByRole("button", { name: o.cancel ?? "Cancel" }));
  await waitFor(() => expect(screen.queryByRole("alertdialog")).toBeNull());
  expect(o.action).not.toHaveBeenCalled();

  await o.open();
  dlg = await screen.findByRole("alertdialog");
  await o.before?.(dlg);
  await click(within(dlg).getByRole("button", { name: o.confirm }));
  await waitFor(() => expect(o.action).toHaveBeenCalledTimes(1));
  if (o.args) expect(o.action).toHaveBeenCalledWith(...o.args);
  await waitFor(() => expect(screen.queryByRole("alertdialog")).toBeNull());
}

beforeEach(() => {
  setDefaults();
  authModule.authService.me.mockResolvedValue(admin);
});
const btn = (name: string | RegExp) => screen.findByRole("button", { name });

describe("logout dialog (real layouts)", () => {
  it("store header: opens from the account menu; cancel keeps the session, confirm logs out", async () => {
    authModule.authService.me.mockResolvedValue(customer);
    await renderIn("store", <div>page</div>, { user: customer });
    await dialogFlow({
      open: async () => {
        if (!screen.queryByRole("button", { name: "Log out" })) await click(await btn("Account menu"));
        await click(await btn("Log out"));
      },
      confirm: "Log out",
      action: vi.mocked(logout),
    });
  });

  it("admin sidebar: same behaviour", async () => {
    await renderIn("admin", <div>page</div>, { user: admin, path: "/admin/orders" });
    await dialogFlow({ open: async () => click(await btn("Log out")), confirm: "Log out", action: vi.mocked(logout) });
  });
});

describe("customer dialogs inside the store layout", () => {
  beforeEach(() => authModule.authService.me.mockResolvedValue(customer));

  it("cancel order (needs a reason)", async () => {
    const { OrderDetail } = await import("@/components/store/order-detail");
    orderModule.orderService.get.mockResolvedValue(order({ status: "PENDING" }));
    orderModule.orderService.cancel.mockResolvedValue(order({ status: "CANCELLED", cancelledReason: "Changed my mind" }));
    await renderIn("store", <OrderDetail orderNumber="ECOM-1" />, { user: customer });
    await dialogFlow({
      open: async () => click(await btn("Cancel order")),
      confirm: "Cancel order",
      cancel: "Keep order",
      action: orderModule.orderService.cancel,
      before: async (dlg) => {
        expect(within(dlg).getByRole("button", { name: "Cancel order" })).toBeDisabled(); // reason required
        await userEvent.type(within(dlg).getByLabelText("Reason"), "Changed my mind");
      },
      args: ["ECOM-1", "Changed my mind"],
    });
    expect(await screen.findByText("Order cancelled")).toBeInTheDocument();
  });

  it("a cancelled order with a late KHQR payment shows the explanation and no cancel button", async () => {
    const { OrderDetail } = await import("@/components/store/order-detail");
    orderModule.orderService.get.mockResolvedValue(order({ status: "CANCELLED", cancelledReason: "KHQR payment timeout", payment: payment({ status: "PAID_AFTER_CANCEL" }) }));
    await renderIn("store", <OrderDetail orderNumber="ECOM-1" />, { user: customer });
    expect(await screen.findByTestId("late-payment-msg")).toHaveTextContent("We received your payment after the order was cancelled. Our team will restore your order or refund you.");
    expect(screen.queryByRole("button", { name: "Cancel order" })).not.toBeInTheDocument();
    expect(screen.getAllByText(/KHQR payment timeout/).length).toBeGreaterThanOrEqual(1);
  });

  it("Pay now appears for unpaid KHQR orders only", async () => {
    const { OrderDetail } = await import("@/components/store/order-detail");
    orderModule.orderService.get.mockResolvedValue(order({ status: "PENDING" }));
    await renderIn("store", <OrderDetail orderNumber="ECOM-1" />, { user: customer });
    expect(await screen.findByRole("link", { name: /Pay now/ })).toHaveAttribute("href", "/checkout/pay/ECOM-1");
  });

  it("delete address", async () => {
    const { AddressList } = await import("@/components/store/address-list");
    addressModule.addressService.remove.mockResolvedValue(undefined);
    await renderIn("store", <AddressList />, { user: customer });
    await dialogFlow({ open: async () => click(await btn("Delete")), confirm: "Delete", action: addressModule.addressService.remove, args: [1] });
  });

  it("set default address", async () => {
    const { AddressList } = await import("@/components/store/address-list");
    addressModule.addressService.list.mockResolvedValue([address(), address({ id: 2, isDefault: false, line1: "No. 5, Street 63" })]);
    addressModule.addressService.setDefault.mockResolvedValue(address({ id: 2, isDefault: true }));
    await renderIn("store", <AddressList />, { user: customer });
    await dialogFlow({ open: async () => click(await btn(/Set default/)), confirm: "Set as default", action: addressModule.addressService.setDefault, args: [2] });
  });
});

describe("admin dialogs inside the admin shell", () => {
  it("delete product", async () => {
    const { default: Page } = await import("@/app/admin/products/page");
    A.products.mockResolvedValue(page([product()]));
    A.deleteProduct.mockResolvedValue(undefined);
    await renderIn("admin", <Page />, { user: admin, path: "/admin/products" });
    await dialogFlow({ open: async () => click(await btn(/Delete ASUS ROG/)), confirm: "Delete product", action: A.deleteProduct, args: [29] });
  });

  it("delete product blocked by orders explains what to do", async () => {
    const { default: Page } = await import("@/app/admin/products/page");
    A.products.mockResolvedValue(page([product()]));
    A.deleteProduct.mockRejectedValue(new ApiError("conflict", 409));
    await renderIn("admin", <Page />, { user: admin, path: "/admin/products" });
    await click(await btn(/Delete ASUS ROG/));
    await click(within(await screen.findByRole("alertdialog")).getByRole("button", { name: "Delete product" }));
    expect(await screen.findByText(/Deactivate it instead/)).toBeInTheDocument();
    await waitFor(() => expect(screen.queryByRole("alertdialog")).toBeNull());
  });

  it("delete category", async () => {
    const { default: Page } = await import("@/app/admin/categories/page");
    A.deleteCategory.mockResolvedValue(undefined);
    await renderIn("admin", <Page />, { user: admin, path: "/admin/categories" });
    await dialogFlow({ open: async () => click(await btn("Delete Laptop")), confirm: "Delete", action: A.deleteCategory, args: [1] });
  });

  it("delete brand", async () => {
    const { default: Page } = await import("@/app/admin/brands/page");
    A.deleteBrand.mockResolvedValue(undefined);
    await renderIn("admin", <Page />, { user: admin, path: "/admin/brands" });
    await dialogFlow({ open: async () => click(await btn("Delete Dell")), confirm: "Delete", action: A.deleteBrand, args: [1] });
  });

  it("delete coupon", async () => {
    const { default: Page } = await import("@/app/admin/coupons/page");
    A.coupons.mockResolvedValue(page([{ id: 7, code: "SAVE50", discountType: "FIXED", value: 50, usedCount: 0, active: true }]));
    A.deleteCoupon.mockResolvedValue(undefined);
    await renderIn("admin", <Page />, { user: admin, path: "/admin/coupons" });
    await dialogFlow({ open: async () => click(await btn("Delete SAVE50")), confirm: "Delete coupon", action: A.deleteCoupon, args: [7] });
  });

  it("delete review", async () => {
    const { default: Page } = await import("@/app/admin/reviews/page");
    A.reviews.mockResolvedValue(page([{ id: 4, productId: 29, productName: "Mouse", userId: 3, userName: "Demo Customer", rating: 5, comment: "Great", verifiedPurchase: true, visible: true, createdAt: "2026-11-04T10:00:00" }]));
    A.deleteReview.mockResolvedValue(undefined);
    await renderIn("admin", <Page />, { user: admin, path: "/admin/reviews" });
    await dialogFlow({ open: async () => click(await btn("Delete review by Demo Customer")), confirm: "Delete review", action: A.deleteReview, args: [4] });
  });

  describe("payments", () => {
    const late = payment({ id: 12, orderNumber: "ECOM-29", status: "PAID_AFTER_CANCEL", amount: 105, failureReason: "Paid after auto-cancel", paidAt: "2026-11-04T20:44:01" });
    beforeEach(() => {
      A.payments.mockImplementation(async (q: { status?: string; size?: number }) => (q.size === 1 ? page([late], { totalElements: 3 }) : page([late])));
    });

    it("shows the red badge and the tab count", async () => {
      const { default: Page } = await import("@/app/admin/payments/page");
      await renderIn("admin", <Page />, { user: admin, path: "/admin/payments" });
      expect(await screen.findByRole("tab", { name: /Paid after cancel\s*3/ })).toBeInTheDocument();
      expect(screen.getAllByTestId("payment-badge")[0]).toHaveTextContent("Paid after cancel");
      expect(screen.getAllByTestId("payment-badge")[0].className).toContain("bg-red-600");
    });

    it("refund", async () => {
      const { default: Page } = await import("@/app/admin/payments/page");
      A.refund.mockResolvedValue({ ...late, status: "REFUNDED" });
      await renderIn("admin", <Page />, { user: admin, path: "/admin/payments" });
      await dialogFlow({ open: async () => click(await btn("Refund")), confirm: "Refund payment", action: A.refund, args: ["ECOM-29"] });
    });

    it("restore order", async () => {
      const { default: Page } = await import("@/app/admin/payments/page");
      A.restore.mockResolvedValue(order({ status: "CONFIRMED" }));
      await renderIn("admin", <Page />, { user: admin, path: "/admin/payments" });
      await dialogFlow({ open: async () => click(await btn("Restore order")), confirm: "Restore order", action: A.restore, args: ["ECOM-29"] });
    });

    it("restore 409 says out of stock — please refund", async () => {
      const { default: Page } = await import("@/app/admin/payments/page");
      A.restore.mockRejectedValue(new ApiError("Insufficient stock for Late Laptop", 409));
      await renderIn("admin", <Page />, { user: admin, path: "/admin/payments" });
      await click(await btn("Restore order"));
      await click(within(await screen.findByRole("alertdialog")).getByRole("button", { name: "Restore order" }));
      expect(await screen.findByText("Out of stock — please refund")).toBeInTheDocument();
    });

    it("recheck is offered for pending KHQR payments and disappears after the mock-mode 400", async () => {
      const { default: Page } = await import("@/app/admin/payments/page");
      A.payments.mockImplementation(async () => page([payment({ id: 2, orderNumber: "ECOM-30", status: "PENDING" })]));
      A.recheck.mockRejectedValue(new ApiError("Re-checking is only available when payment.khqr.mode=bakong", 400));
      await renderIn("admin", <Page />, { user: admin, path: "/admin/payments" });
      await dialogFlow({ open: async () => click(await btn("Recheck with Bakong")), confirm: "Recheck", action: A.recheck, args: ["ECOM-30"] }).catch(() => undefined);
      await waitFor(() => expect(screen.queryByRole("button", { name: "Recheck with Bakong" })).not.toBeInTheDocument());
      sessionStorage.clear();
    });
  });

  it("disable user (and you cannot disable or demote yourself)", async () => {
    const { default: Page } = await import("@/app/admin/users/page");
    const { useAuthStore } = await import("@/store/authStore");
    A.users.mockResolvedValue(page([admin, customer]));
    A.setUserEnabled.mockResolvedValue({ ...customer, enabled: false });
    await renderIn("admin", <Page />, { user: admin, path: "/admin/users" });
    const row = await screen.findByText("Demo Customer");
    const customerRow = row.closest("tr") as HTMLElement;
    const selfRow = screen.getByText(/\(you\)/).closest("tr") as HTMLElement;
    expect(useAuthStore.getState().user?.id).toBe(admin.id);
    expect(within(selfRow).getByRole("button", { name: "Disable" })).toBeDisabled();
    expect(within(selfRow).getByRole("combobox")).toBeDisabled();
    await dialogFlow({ open: async () => click(within(customerRow).getByRole("button", { name: "Disable" })), confirm: "Disable account", action: A.setUserEnabled, args: [3, false] });
  });

  it("change role asks first; cancelling leaves the select unchanged", async () => {
    const { default: Page } = await import("@/app/admin/users/page");
    A.users.mockResolvedValue(page([admin, customer]));
    A.setUserRole.mockResolvedValue({ ...customer, role: "STAFF" });
    await renderIn("admin", <Page />, { user: admin, path: "/admin/users" });
    const row = (await screen.findByText("Demo Customer")).closest("tr") as HTMLElement;
    const select = within(row).getByRole("combobox");
    await dialogFlow({ open: async () => userEvent.selectOptions(select, "STAFF"), confirm: "Change role", action: A.setUserRole, args: [3, "STAFF"] });
    expect(select).toHaveValue("CUSTOMER"); // controlled by server data
  });

  it("admin order: cancel order and mark delivered", async () => {
    const { default: Page } = await import("@/app/admin/orders/[orderNumber]/page");
    A.order.mockResolvedValue(order({ status: "PROCESSING" }));
    A.setOrderStatus.mockResolvedValue(order({ status: "CANCELLED" }));
    await renderIn("admin", <Page params={{ orderNumber: "ECOM-1" }} />, { user: admin, path: "/admin/orders/ECOM-1" });
    await dialogFlow({ open: async () => click(await btn("Cancel order")), confirm: "Cancel order", cancel: "Keep order", action: A.setOrderStatus, args: ["ECOM-1", "CANCELLED"] });
  });

  it("admin order: mark delivered", async () => {
    const { default: Page } = await import("@/app/admin/orders/[orderNumber]/page");
    A.order.mockResolvedValue(order({ status: "SHIPPED", shipment: { id: 5, orderNumber: "ECOM-1", method: "EXPRESS", fee: 15, status: "OUT_FOR_DELIVERY", trackingNumber: "T1" } }));
    A.setShipmentStatus.mockResolvedValue({});
    await renderIn("admin", <Page params={{ orderNumber: "ECOM-1" }} />, { user: admin, path: "/admin/orders/ECOM-1" });
    await dialogFlow({ open: async () => click(await btn("Mark delivered")), confirm: "Mark delivered", action: A.setShipmentStatus, args: [5, "DELIVERED"] });
  });

  it("only valid next statuses are offered", async () => {
    const { default: Page } = await import("@/app/admin/orders/[orderNumber]/page");
    A.order.mockResolvedValue(order({ status: "CONFIRMED" }));
    await renderIn("admin", <Page params={{ orderNumber: "ECOM-1" }} />, { user: admin, path: "/admin/orders/ECOM-1" });
    const actions = await screen.findByTestId("order-actions");
    expect(within(actions).getAllByRole("button").map((b) => b.textContent?.trim())).toEqual(["Mark processing", "Cancel order"]);
  });

  it("staff cannot see admin-only pages and is sent to orders", async () => {
    const { staff } = await import("@/test/fixtures");
    authModule.authService.me.mockResolvedValue(staff);
    await renderIn("admin", <div>secret</div>, { user: staff, path: "/admin/users" });
    await waitFor(() => expect(mockNav.router.replace).toHaveBeenCalledWith("/admin/orders"));
    expect(screen.queryByText("secret")).not.toBeInTheDocument();
  });

  it("red banner links to payments when an unread HIGH notification exists", async () => {
    const { notificationModule } = await import("@/test/mocks");
    notificationModule.notificationService.list.mockResolvedValue(page([{ id: 1, type: "EMAIL", title: "Customer paid after cancel - refund or restore order", message: "m", read: false, createdAt: "2026-11-04T20:44:02", priority: "HIGH" }]));
    await renderIn("admin", <div>content</div>, { user: admin, path: "/admin/orders" });
    const banner = await screen.findByTestId("urgent-banner");
    expect(banner).toHaveTextContent("Customer paid after cancel");
    expect(banner).toHaveAttribute("href", "/admin/payments");
  });
});
