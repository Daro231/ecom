import { authModule, cartModule, notificationModule, productModule, addressModule, orderModule, paymentModule, adminModule } from "./mocks";
import { customer, address } from "./fixtures";
import type { PageResponse } from "@/types";

export const page = <T,>(content: T[], over: Partial<PageResponse<T>> = {}): PageResponse<T> => ({ content, page: 0, size: 20, totalElements: content.length, totalPages: 1, last: true, ...over });

/** Sensible defaults so layouts (header badges, guards, banners) render without noise. */
export function setDefaults() {
  authModule.authService.me.mockResolvedValue(customer);
  notificationModule.notificationService.unreadCount.mockResolvedValue(0);
  notificationModule.notificationService.list.mockResolvedValue(page([]));
  notificationModule.notificationService.markRead.mockResolvedValue({});
  notificationModule.notificationService.markAllRead.mockResolvedValue(0);
  cartModule.cartService.get.mockResolvedValue({ id: 1, items: [], totalItems: 0, subtotal: 0 });
  productModule.productService.categories.mockResolvedValue([{ id: 1, name: "Laptop", slug: "laptop" }]);
  productModule.productService.brands.mockResolvedValue([{ id: 1, name: "Dell", slug: "dell" }]);
  productModule.productService.shippingMethods.mockResolvedValue([
    { code: "STANDARD", label: "Standard", fee: 5, estimatedDelivery: "3-5 days", freeShippingThreshold: 1000 },
    { code: "EXPRESS", label: "Express", fee: 15, estimatedDelivery: "1-2 days", freeShippingThreshold: 1000 },
  ]);
  productModule.productService.reviews.mockResolvedValue(page([]));
  addressModule.addressService.list.mockResolvedValue([address()]);
  orderModule.orderService.list.mockResolvedValue(page([]));
  paymentModule.paymentService.status.mockResolvedValue({ id: 1, orderNumber: "ECOM-1", method: "KHQR", status: "PENDING", amount: 77.1 });
  Object.values(adminModule.adminService).forEach((f) => f.mockResolvedValue(page([])));
}
