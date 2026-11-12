import { vi } from "vitest";

/** Mock modules for every service; tests set resolved values per case. */
export const authModule = { authService: { login: vi.fn(), register: vi.fn(), me: vi.fn(), updateMe: vi.fn(), changePassword: vi.fn() } };
export const productModule = { productService: { list: vi.fn(), byId: vi.fn(), bySlug: vi.fn(), categories: vi.fn(), brands: vi.fn(), shippingMethods: vi.fn(), reviews: vi.fn() } };
export const cartModule = { cartService: { get: vi.fn(), add: vi.fn(), update: vi.fn(), remove: vi.fn(), clear: vi.fn(), applyCoupon: vi.fn() } };
export const orderModule = { orderService: { checkout: vi.fn(), list: vi.fn(), get: vi.fn(), invoice: vi.fn(), tracking: vi.fn(), cancel: vi.fn() } };
export const paymentModule = { paymentService: { khqr: vi.fn(), status: vi.fn(), simulate: vi.fn() } };
export const addressModule = { addressService: { list: vi.fn(), create: vi.fn(), update: vi.fn(), remove: vi.fn(), setDefault: vi.fn() } };
export const notificationModule = { notificationService: { list: vi.fn(), unreadCount: vi.fn(), markRead: vi.fn(), markAllRead: vi.fn() } };
export const reviewModule = { reviewService: { create: vi.fn(), update: vi.fn(), remove: vi.fn() } };
export const adminModule = {
  adminService: Object.fromEntries(
    ["dashboard", "sales", "products", "product", "createProduct", "updateProduct", "deleteProduct", "setProductActive", "upload", "createCategory", "updateCategory", "deleteCategory", "createBrand", "updateBrand", "deleteBrand", "inventory", "lowStock", "restock", "adjust", "inventoryLogs", "orders", "order", "setOrderStatus", "ship", "setShipmentStatus", "restore", "payments", "refund", "recheck", "coupons", "createCoupon", "updateCoupon", "deleteCoupon", "reviews", "setReviewVisible", "deleteReview", "users", "setUserRole", "setUserEnabled"].map((k) => [k, vi.fn()]),
  ) as Record<string, ReturnType<typeof vi.fn>>,
};
