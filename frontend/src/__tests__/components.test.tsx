import * as React from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { act, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { addressModule, authModule, cartModule, orderModule, paymentModule, productModule, notificationModule } from "@/test/mocks";
import { setDefaults, page } from "@/test/defaults";
import { renderIn } from "@/test/render";
import { address, admin, customer, order } from "@/test/fixtures";
import { mockNav } from "@/test/nav";
import { ApiError } from "@/lib/api-error";

vi.mock("@/services/auth", async () => (await import("@/test/mocks")).authModule);
vi.mock("@/services/product", async () => (await import("@/test/mocks")).productModule);
vi.mock("@/services/cart", async () => (await import("@/test/mocks")).cartModule);
vi.mock("@/services/order", async () => (await import("@/test/mocks")).orderModule);
vi.mock("@/services/payment", async () => (await import("@/test/mocks")).paymentModule);
vi.mock("@/services/address", async () => (await import("@/test/mocks")).addressModule);
vi.mock("@/services/notification", async () => (await import("@/test/mocks")).notificationModule);
vi.mock("@/services/review", async () => (await import("@/test/mocks")).reviewModule);
vi.mock("qrcode.react", () => ({ QRCodeCanvas: ({ value }: { value: string }) => <div data-testid="qr" data-value={value} /> }));
vi.mock("@/components/shared/address-map-loader", () => ({
  StaticMap: () => <div data-testid="static-map" />,
  AddressMap: ({ value, onChange }: { value: { lat: number; lng: number } | null; onChange: (p: { lat: number; lng: number } | null, s: string) => void }) => (
    <div data-testid="map-stub">
      <span data-testid="pin">{value ? `${value.lat},${value.lng}` : "none"}</span>
      <button type="button" onClick={() => onChange({ lat: 11.5564, lng: 104.9282 }, "click")}>Drop pin</button>
      <button type="button" onClick={() => onChange(null, "remove")}>Remove pin</button>
    </div>
  ),
}));
vi.mock("@/lib/geocoder", async (orig) => ({ ...(await orig<typeof import("@/lib/geocoder")>()), reverseGeocode: vi.fn() }));

beforeEach(() => setDefaults());

describe("LoginForm", () => {
  it("validates before calling the API", async () => {
    const { LoginForm } = await import("@/components/auth/login-form");
    await renderIn("none", <LoginForm />);
    await userEvent.click(screen.getByRole("button", { name: "Log in" }));
    expect(await screen.findByText("Email is required")).toBeInTheDocument();
    expect(screen.getByText("Password is required")).toBeInTheDocument();
    await userEvent.type(screen.getByLabelText("Email"), "not-an-email");
    await userEvent.type(screen.getByLabelText("Password"), "x");
    await userEvent.click(screen.getByRole("button", { name: "Log in" }));
    expect(await screen.findByText("Enter a valid email")).toBeInTheDocument();
    expect(authModule.authService.login).not.toHaveBeenCalled();
  });

  it("signs a customer in, stores the token and goes to the redirect target", async () => {
    const { LoginForm } = await import("@/components/auth/login-form");
    const { useAuthStore } = await import("@/store/authStore");
    mockNav.search = "redirect=%2Forders";
    authModule.authService.login.mockResolvedValue({ accessToken: "tok", tokenType: "Bearer", expiresInSeconds: 86400, user: customer });
    await renderIn("none", <LoginForm />);
    await userEvent.type(screen.getByLabelText("Email"), "customer@ecom.com");
    await userEvent.type(screen.getByLabelText("Password"), "Customer@123");
    await userEvent.click(screen.getByRole("button", { name: "Log in" }));
    await waitFor(() => expect(mockNav.router.replace).toHaveBeenCalledWith("/orders"));
    expect(authModule.authService.login).toHaveBeenCalledWith("customer@ecom.com", "Customer@123");
    expect(useAuthStore.getState().token).toBe("tok");
    expect(document.cookie).toContain("ecom_token=tok");
  });

  it("sends admins to the dashboard and ignores unsafe redirects", async () => {
    const { LoginForm } = await import("@/components/auth/login-form");
    mockNav.search = "redirect=%2F%2Fevil.com";
    authModule.authService.login.mockResolvedValue({ accessToken: "t", tokenType: "Bearer", expiresInSeconds: 1, user: admin });
    await renderIn("none", <LoginForm />);
    await userEvent.type(screen.getByLabelText("Email"), "admin@ecom.com");
    await userEvent.type(screen.getByLabelText("Password"), "Admin@123");
    await userEvent.click(screen.getByRole("button", { name: "Log in" }));
    await waitFor(() => expect(mockNav.router.replace).toHaveBeenCalledWith("/admin/dashboard"));
  });

  it("stays on the page when credentials are wrong; password can be shown", async () => {
    const { LoginForm } = await import("@/components/auth/login-form");
    authModule.authService.login.mockRejectedValue(new ApiError("Invalid email or password", 401));
    await renderIn("none", <LoginForm />);
    const pw = screen.getByLabelText("Password");
    expect(pw).toHaveAttribute("type", "password");
    await userEvent.click(screen.getByRole("button", { name: "Show password" }));
    expect(pw).toHaveAttribute("type", "text");
    await userEvent.type(screen.getByLabelText("Email"), "a@b.co");
    await userEvent.type(pw, "wrong");
    await userEvent.click(screen.getByRole("button", { name: "Log in" }));
    expect(await screen.findByText("Invalid email or password")).toBeInTheDocument();
    expect(mockNav.router.replace).not.toHaveBeenCalled();
  });
});

describe("session wipe", () => {
  it("clearSession removes token, cookies, persisted state, caches, badges", async () => {
    const { clearSession } = await import("@/lib/session");
    const { useAuthStore } = await import("@/store/authStore");
    const { useBadgeStore } = await import("@/store/badgeStore");
    const { useCheckoutStore } = await import("@/store/checkoutStore");
    const { queryClient } = await import("@/lib/query-client");
    useAuthStore.getState().setAuth("tok", customer);
    useBadgeStore.setState({ cartCount: 3, unreadCount: 4 });
    useCheckoutStore.getState().set({ couponCode: "WELCOME10" });
    queryClient.setQueryData(["orders"], [1]);
    expect(localStorage.getItem("ecom-auth")).toContain("tok");
    clearSession();
    expect(useAuthStore.getState()).toMatchObject({ token: null, user: null });
    expect(localStorage.getItem("ecom-auth")).toBeNull();
    expect(document.cookie).not.toContain("ecom_token");
    expect(queryClient.getQueryData(["orders"])).toBeUndefined();
    expect(useBadgeStore.getState()).toMatchObject({ cartCount: 0, unreadCount: 0 });
    expect(useCheckoutStore.getState().couponCode).toBeNull();
  });
});

describe("ProductImage fallback", () => {
  it("shows gradient + category icon + brand name when there is no image", async () => {
    const { ProductImage } = await import("@/components/shared/product-image");
    await renderIn("none", <ProductImage alt="x" category="Laptop" brand="Dell" />);
    const fb = screen.getByTestId("image-fallback");
    expect(fb).toHaveTextContent("Dell");
    expect(fb.className).toContain("bg-gradient-to-br");
    expect(fb.querySelector("svg")).not.toBeNull();
  });
  it("falls back when the image fails to load", async () => {
    const { ProductImage } = await import("@/components/shared/product-image");
    await renderIn("none", <ProductImage src="https://placehold.co/a.png" alt="Dell XPS" category="Laptop" brand="Dell" />);
    const img = screen.getByAltText("Dell XPS");
    act(() => { img.dispatchEvent(new Event("error")); });
    expect(await screen.findByTestId("image-fallback")).toBeInTheDocument();
  });
});

describe("cart totals display", () => {
  it("shows backend discount, shipping and total once a coupon is applied", async () => {
    const { default: CartPage } = await import("@/app/(store)/cart/page");
    cartModule.cartService.get.mockResolvedValue({ id: 1, items: [{ id: 1, productId: 29, productName: "Mouse", unitPrice: 69, quantity: 2, lineTotal: 138, stockQuantity: 38 }], totalItems: 2, subtotal: 138 });
    cartModule.cartService.applyCoupon.mockResolvedValue({ couponCode: "WELCOME10", subtotal: 138, discount: 13.8, shippingFee: 5, total: 129.2 });
    await renderIn("store", <CartPage />, { user: customer });
    expect(await screen.findByTestId("sum-subtotal")).toHaveTextContent("$138.00");
    // no coupon: shipping derived from the backend's STANDARD method data (fee $5, free from $1,000)
    expect(screen.getByTestId("sum-shipping")).toHaveTextContent("$5.00");
    expect(screen.getByTestId("sum-total")).toHaveTextContent("$143.00");
    await userEvent.type(screen.getByLabelText("Coupon code"), "welcome10");
    await userEvent.click(screen.getByRole("button", { name: "Apply" }));
    expect(await screen.findByTestId("sum-discount")).toHaveTextContent("−$13.80");
    expect(screen.getByTestId("sum-shipping")).toHaveTextContent("$5.00");
    expect(screen.getByTestId("sum-total")).toHaveTextContent("$129.20");
    expect(cartModule.cartService.applyCoupon).toHaveBeenCalledWith("WELCOME10", "STANDARD");
    await userEvent.click(screen.getByRole("button", { name: "Remove coupon" }));
    await waitFor(() => expect(screen.queryByTestId("sum-discount")).not.toBeInTheDocument());
  });

  it("changes quantity and shows the empty state", async () => {
    const { default: CartPage } = await import("@/app/(store)/cart/page");
    cartModule.cartService.get.mockResolvedValueOnce({ id: 1, items: [{ id: 7, productId: 29, productName: "Mouse", unitPrice: 69, quantity: 1, lineTotal: 69, stockQuantity: 38 }], totalItems: 1, subtotal: 69 });
    cartModule.cartService.update.mockResolvedValue({ id: 1, items: [], totalItems: 0, subtotal: 0 });
    await renderIn("store", <CartPage />, { user: customer });
    await userEvent.click(await screen.findByRole("button", { name: "Increase quantity" }));
    expect(cartModule.cartService.update).toHaveBeenCalledWith(7, 2);
    expect(await screen.findByText("Your cart is empty")).toBeInTheDocument();
  });
});

describe("AddressForm keeps coordinates", () => {
  const initial = address({ latitude: 11.556374, longitude: 104.928207 });
  it("editing only the text still sends the current latitude/longitude", async () => {
    const { AddressForm } = await import("@/components/store/address-form");
    const onSubmit = vi.fn();
    await renderIn("none", <AddressForm initial={initial} onSubmit={onSubmit} />);
    expect(screen.getByTestId("pin")).toHaveTextContent("11.556374,104.928207");
    const line = screen.getByLabelText("Address");
    await userEvent.clear(line);
    await userEvent.type(line, "No. 9, Street 63");
    await userEvent.click(screen.getByRole("button", { name: "Save address" }));
    await waitFor(() => expect(onSubmit).toHaveBeenCalled());
    expect(onSubmit.mock.calls[0][0]).toMatchObject({ line1: "No. 9, Street 63", city: "Phnom Penh", latitude: 11.556374, longitude: 104.928207 });
  });
  it("removing the pin sends no coordinates", async () => {
    const { AddressForm } = await import("@/components/store/address-form");
    const onSubmit = vi.fn();
    await renderIn("none", <AddressForm initial={initial} onSubmit={onSubmit} />);
    await userEvent.click(screen.getByRole("button", { name: "Remove pin" }));
    await userEvent.click(screen.getByRole("button", { name: "Save address" }));
    await waitFor(() => expect(onSubmit).toHaveBeenCalled());
    const body = onSubmit.mock.calls[0][0];
    expect(body).not.toHaveProperty("latitude");
    expect(body).not.toHaveProperty("longitude");
  });
  it("validates required fields", async () => {
    const { AddressForm } = await import("@/components/store/address-form");
    const onSubmit = vi.fn();
    await renderIn("none", <AddressForm onSubmit={onSubmit} />);
    await userEvent.click(screen.getByRole("button", { name: "Save address" }));
    expect(await screen.findByText("Enter the street address")).toBeInTheDocument();
    expect(onSubmit).not.toHaveBeenCalled();
  });
});

describe("AddressForm reverse geocoding", () => {
  it("fills empty address/city from the pin but never overwrites typed text; failure keeps the pin", async () => {
    const { AddressForm } = await import("@/components/store/address-form");
    const { reverseGeocode } = await import("@/lib/geocoder");
    const geo = vi.mocked(reverseGeocode);
    geo.mockResolvedValue({ line1: "Street 1003, Khan Sen Sok", city: "Phnom Penh" });
    await renderIn("none", <AddressForm onSubmit={vi.fn()} />);
    await userEvent.click(screen.getByRole("button", { name: "Drop pin" }));
    await waitFor(() => expect(screen.getByLabelText("Address")).toHaveValue("Street 1003, Khan Sen Sok"), { timeout: 3000 });
    expect(screen.getByLabelText("City")).toHaveValue("Phnom Penh");
    expect(geo).toHaveBeenCalledTimes(1);

    // the user now types their own address; a new pin must not overwrite it
    const line = screen.getByLabelText("Address");
    await userEvent.clear(line);
    await userEvent.type(line, "My own street");
    geo.mockResolvedValue({ line1: "Another road", city: "Siem Reap" });
    await userEvent.click(screen.getByRole("button", { name: "Drop pin" }));
    await waitFor(() => expect(geo).toHaveBeenCalledTimes(2), { timeout: 3000 });
    expect(screen.getByLabelText("Address")).toHaveValue("My own street");
    expect(screen.getByLabelText("City")).toHaveValue("Siem Reap"); // city was auto-filled (not typed), so a new pin may refill it
  }, 20000);

  it("on failure keeps the pin and asks the user to type", async () => {
    const { AddressForm } = await import("@/components/store/address-form");
    const { reverseGeocode } = await import("@/lib/geocoder");
    vi.mocked(reverseGeocode).mockRejectedValue(new Error("Nominatim 429"));
    await renderIn("none", <AddressForm onSubmit={vi.fn()} />);
    await userEvent.click(screen.getByRole("button", { name: "Drop pin" }));
    expect(await screen.findByText(/Please type the address and city/, {}, { timeout: 3000 })).toBeInTheDocument();
    expect(screen.getByTestId("pin")).toHaveTextContent("11.5564,104.9282");
  }, 10000);
});

describe("CheckoutFlow", () => {
  const withCart = () => cartModule.cartService.get.mockResolvedValue({ id: 1, items: [{ id: 1, productId: 29, productName: "Mouse", unitPrice: 69, quantity: 1, lineTotal: 69, stockQuantity: 38 }], totalItems: 1, subtotal: 69 });

  it("blocks admin accounts", async () => {
    const { CheckoutFlow } = await import("@/components/store/checkout-flow");
    authModule.authService.me.mockResolvedValue(admin);
    await renderIn("store", <CheckoutFlow />, { user: admin });
    expect(await screen.findByText("Admin accounts cannot place orders")).toBeInTheDocument();
  });

  it("requires an address before continuing and lets you add one", async () => {
    const { CheckoutFlow } = await import("@/components/store/checkout-flow");
    withCart();
    addressModule.addressService.list.mockResolvedValue([]);
    orderModule.orderService.checkout.mockResolvedValue(order({ orderNumber: "ECOM-9", paymentMethod: "KHQR" }));
    await renderIn("store", <CheckoutFlow />, { user: customer });
    await screen.findByRole("heading", { name: "Delivery address" });
    await userEvent.click(screen.getByRole("button", { name: "Continue" }));
    expect(await screen.findByText("Choose or add a delivery address to continue.")).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: "Add new address" }));
    expect(await screen.findByRole("form", { name: "New address" })).toBeInTheDocument();
  });

  it("places an order with the chosen options and opens the KHQR page", async () => {
    const { CheckoutFlow } = await import("@/components/store/checkout-flow");
    withCart();
    orderModule.orderService.checkout.mockResolvedValue(order({ orderNumber: "ECOM-9", paymentMethod: "KHQR" }));
    await renderIn("store", <CheckoutFlow />, { user: customer });
    await screen.findByRole("heading", { name: "Delivery address" });
    await waitFor(() => expect(screen.getByRole("radio", { name: /Demo Customer/ })).toBeChecked());
    const next = () => userEvent.click(screen.getByRole("button", { name: "Continue" }));
    await next();
    await userEvent.click(await screen.findByRole("radio", { name: /Express/ }));
    await next();
    expect(screen.getByRole("radio", { name: /KHQR/ })).toBeChecked();
    await userEvent.click(screen.getByRole("radio", { name: /Cash on Delivery/ }));
    await userEvent.click(screen.getByRole("radio", { name: /KHQR/ }));
    await next();
    expect(await screen.findByRole("heading", { name: /Review/ })).toBeInTheDocument();
    expect(screen.getByTestId("sum-shipping")).toHaveTextContent("$15.00");
    expect(screen.getByTestId("sum-total")).toHaveTextContent("$84.00");
    await userEvent.click(screen.getByRole("button", { name: "Place order" }));
    await waitFor(() => expect(orderModule.orderService.checkout).toHaveBeenCalled());
    expect(orderModule.orderService.checkout.mock.calls[0][0]).toEqual({ addressId: 1, shippingMethod: "EXPRESS", paymentMethod: "KHQR", couponCode: undefined, note: undefined });
    await waitFor(() => expect(mockNav.router.replace).toHaveBeenCalledWith("/checkout/pay/ECOM-9"));
  });
});

describe("KhqrPayment states", () => {
  const SERVER = "2026-11-05T12:00:00";
  const qr = (over = {}) => ({ orderNumber: "ECOM-1", amount: 12.5, currency: "USD", qrString: "MOCK-KHQR|merchant=ECOM|order=ECOM-1", md5: "x", expiresAt: "2026-11-05T12:10:00", mode: "MOCK", serverTime: SERVER, ...over });
  const status = (s: string, extra = {}) => ({ id: 1, orderNumber: "ECOM-1", method: "KHQR", status: s, amount: 12.5, ...extra });

  beforeEach(() => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    orderModule.orderService.get.mockResolvedValue(order());
  });
  const advance = (ms: number) => act(async () => { await vi.advanceTimersByTimeAsync(ms); });
  const mountPage = async () => {
    const { KhqrPayment } = await import("@/components/store/khqr-payment");
    return renderIn("none", <KhqrPayment orderNumber="ECOM-1" />, { user: customer });
  };

  it("renders the red KHQR card with QR, merchant, amount, server-based countdown and Simulate in MOCK mode", async () => {
    paymentModule.paymentService.khqr.mockResolvedValue(qr());
    await mountPage();
    expect(await screen.findByTestId("qr")).toHaveAttribute("data-value", "MOCK-KHQR|merchant=ECOM|order=ECOM-1");
    expect(screen.getByText("KHQR").className).toContain("tracking");
    expect(screen.getByTestId("khqr-amount")).toHaveTextContent("$12.50");
    expect(screen.getByText("ECOM")).toBeInTheDocument();
    expect(screen.getByTestId("khqr-countdown")).toHaveTextContent("10:00");
    expect(screen.getByRole("button", { name: "Simulate payment" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Download QR" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Pay later – view order" })).toHaveAttribute("href", "/orders/ECOM-1");
  });

  it("hides Simulate payment in BAKONG mode", async () => {
    paymentModule.paymentService.khqr.mockResolvedValue(qr({ mode: "BAKONG" }));
    await mountPage();
    await screen.findByTestId("qr");
    expect(screen.queryByRole("button", { name: "Simulate payment" })).not.toBeInTheDocument();
  });

  it("expired: shows 'QR expired' and Generate new QR fetches another", async () => {
    paymentModule.paymentService.khqr.mockResolvedValueOnce(qr({ expiresAt: "2026-11-05T12:00:01" })).mockResolvedValue(qr());
    await mountPage();
    await screen.findByTestId("qr");
    await advance(1600);
    expect(await screen.findByTestId("qr-expired")).toHaveTextContent("QR expired");
    await userEvent.click(screen.getByRole("button", { name: "Generate new QR" }));
    await waitFor(() => expect(screen.queryByTestId("qr-expired")).not.toBeInTheDocument());
    expect(paymentModule.paymentService.khqr).toHaveBeenCalledTimes(2);
    expect(screen.getByTestId("khqr-countdown")).toHaveTextContent("10:00");
  });

  it("FAILED shows the failure reason with retry", async () => {
    paymentModule.paymentService.khqr.mockResolvedValue(qr());
    paymentModule.paymentService.status.mockResolvedValue(status("FAILED", { failureReason: "Wrong amount" }));
    await mountPage();
    await screen.findByTestId("qr");
    await advance(3100);
    expect(await screen.findByTestId("khqr-failed")).toHaveTextContent("Wrong amount");
    expect(screen.getByRole("button", { name: "Try again" })).toBeInTheDocument();
  });

  it("failure reason 'QR expired' is shown as expired, not as a failure", async () => {
    paymentModule.paymentService.khqr.mockResolvedValue(qr());
    paymentModule.paymentService.status.mockResolvedValue(status("FAILED", { failureReason: "QR expired" }));
    await mountPage();
    await screen.findByTestId("qr");
    await advance(3100);
    expect(await screen.findByTestId("qr-expired")).toBeInTheDocument();
    expect(screen.queryByTestId("khqr-failed")).not.toBeInTheDocument();
  });

  it("504/502 keep polling with a small warning, then PAID goes to success", async () => {
    paymentModule.paymentService.khqr.mockResolvedValue(qr());
    paymentModule.paymentService.status
      .mockRejectedValueOnce(new ApiError("Bakong timed out", 504))
      .mockRejectedValueOnce(new ApiError("Provider unusable", 502))
      .mockResolvedValue(status("PAID"));
    await mountPage();
    await screen.findByTestId("qr");
    await advance(3100);
    expect(await screen.findByTestId("provider-warning")).toBeInTheDocument();
    expect(screen.queryByTestId("khqr-failed")).not.toBeInTheDocument();
    await advance(3100);
    await advance(3100);
    await waitFor(() => expect(mockNav.router.replace).toHaveBeenCalledWith("/checkout/success/ECOM-1"));
    expect(paymentModule.paymentService.status.mock.calls.length).toBeGreaterThanOrEqual(3);
  });

  it("does not poll while the tab is hidden and checks at once when it becomes visible", async () => {
    paymentModule.paymentService.khqr.mockResolvedValue(qr());
    await mountPage();
    await screen.findByTestId("qr");
    Object.defineProperty(document, "hidden", { configurable: true, get: () => true });
    await advance(9500);
    expect(paymentModule.paymentService.status).not.toHaveBeenCalled();
    Object.defineProperty(document, "hidden", { configurable: true, get: () => false });
    await act(async () => { document.dispatchEvent(new Event("visibilitychange")); });
    await waitFor(() => expect(paymentModule.paymentService.status).toHaveBeenCalledTimes(1));
  });

  it("Simulate payment calls the mock callback then re-checks", async () => {
    paymentModule.paymentService.khqr.mockResolvedValue(qr());
    paymentModule.paymentService.simulate.mockResolvedValue(status("PAID"));
    paymentModule.paymentService.status.mockResolvedValue(status("PAID"));
    await mountPage();
    await userEvent.click(await screen.findByRole("button", { name: "Simulate payment" }));
    expect(paymentModule.paymentService.simulate).toHaveBeenCalledWith("ECOM-1", expect.stringMatching(/^MOCK-/));
    await waitFor(() => expect(mockNav.router.replace).toHaveBeenCalledWith("/checkout/success/ECOM-1"));
  });

  it("a cancelled order shows no QR; a late payment explains what happens", async () => {
    paymentModule.paymentService.khqr.mockRejectedValue(new ApiError("Order is cancelled", 400));
    orderModule.orderService.get.mockResolvedValue(order({ status: "CANCELLED", cancelledReason: "KHQR payment timeout", payment: { id: 1, orderNumber: "ECOM-1", method: "KHQR", status: "PAID_AFTER_CANCEL", amount: 12.5 } }));
    await mountPage();
    expect(await screen.findByText("Payment received after cancellation")).toBeInTheDocument();
    expect(screen.getByText(/We received your payment after the order was cancelled/)).toBeInTheDocument();
    expect(screen.queryByTestId("qr")).not.toBeInTheDocument();
  });
});

describe("notifications", () => {
  it("lists HIGH priority first with a red marker", async () => {
    const { NotificationList } = await import("@/components/shared/notification-list");
    const n = (id: number, priority: "HIGH" | "NORMAL", title: string) => ({ id, type: "PUSH", title, message: "m", read: false, createdAt: `2026-11-0${id}T10:00:00`, priority });
    notificationModule.notificationService.list.mockResolvedValue(page([n(1, "NORMAL", "Order shipped"), n(2, "HIGH", "Customer paid after cancel")]));
    await renderIn("none", <NotificationList />, { user: customer });
    const items = await screen.findAllByTestId("notification");
    expect(items[0]).toHaveAttribute("data-priority", "HIGH");
    expect(within(items[0]).getByLabelText("High priority").className).toContain("bg-red-600");
    expect(items[1]).toHaveAttribute("data-priority", "NORMAL");
    await userEvent.click(screen.getByRole("button", { name: /Mark all as read/ }));
    expect(notificationModule.notificationService.markAllRead).toHaveBeenCalled();
  });
});

describe("product catalog pieces", () => {
  it("hides empty spec rows", async () => {
    const { specRows } = await import("@/components/store/product-detail");
    const { product } = await import("@/test/fixtures");
    expect(specRows(product({ cpu: "i7", ram: 16, gpu: "  ", warrantyMonths: 24 }))).toEqual([["CPU", "i7"], ["RAM", "16 GB"], ["Warranty", "24 months"]]);
  });
  it("search 'laptop' becomes the category filter with a removable chip", async () => {
    const { ProductsView } = await import("@/components/store/products-view");
    mockNav.path = "/products";
    mockNav.search = "keyword=laptop";
    productModule.productService.list.mockResolvedValue(page([]));
    await renderIn("none", <ProductsView />);
    await waitFor(() => expect(mockNav.router.replace).toHaveBeenCalledWith("/products?categoryId=1", { scroll: false }));
    expect(productModule.productService.list).not.toHaveBeenCalled(); // no wasted request with the raw keyword
  });
  it("renders the chip for an active category and removes it", async () => {
    const { ProductsView } = await import("@/components/store/products-view");
    mockNav.path = "/products";
    mockNav.search = "categoryId=1&ram=16";
    productModule.productService.list.mockResolvedValue(page([]));
    await renderIn("none", <ProductsView />);
    const chip = await screen.findByTestId("chip-cat");
    expect(chip).toHaveTextContent("Laptop");
    await userEvent.click(chip);
    expect(mockNav.router.replace).toHaveBeenCalledWith("/products?ram=16", { scroll: false });
    expect(await screen.findByText("No products found")).toBeInTheDocument();
    expect(productModule.productService.list).toHaveBeenCalledWith(expect.objectContaining({ categoryId: 1, ram: 16 }));
  });
});
