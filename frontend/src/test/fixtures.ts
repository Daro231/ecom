import type { Address, Order, Payment, Product, User } from "@/types";

export const customer: User = { id: 3, fullName: "Demo Customer", email: "customer@ecom.com", phone: "012345678", role: "CUSTOMER", enabled: true, createdAt: "2026-11-04T15:43:13" };
export const admin: User = { ...customer, id: 1, fullName: "Admin", email: "admin@ecom.com", role: "ADMIN" };
export const staff: User = { ...customer, id: 2, fullName: "Staff", email: "staff@ecom.com", role: "STAFF" };

export const payment = (over: Partial<Payment> = {}): Payment => ({ id: 1, orderNumber: "ECOM-1", method: "KHQR", status: "PENDING", amount: 77.1, ...over });
export const order = (over: Partial<Order> = {}): Order => ({
  id: 1, orderNumber: "ECOM-1", status: "PENDING", subtotal: 69, discountAmount: 6.9, shippingFee: 15, total: 77.1, receiverName: "Demo Customer", receiverPhone: "012345678",
  shippingAddress: "No. 12, Street 271, Toul Kork, Phnom Penh", shippingMethod: "EXPRESS", paymentMethod: "KHQR", customerEmail: "customer@ecom.com",
  items: [{ id: 1, productId: 29, productName: "ASUS ROG Gladius III Gaming Mouse", unitPrice: 69, quantity: 1, lineTotal: 69 }],
  payment: payment(), createdAt: "2026-11-04T15:43:17", ...over,
});
export const address = (over: Partial<Address> = {}): Address => ({ id: 1, receiverName: "Demo Customer", phone: "012345678", line1: "No. 12, Street 271, Toul Kork", city: "Phnom Penh", isDefault: true, ...over });
export const product = (over: Partial<Product> = {}): Product => ({
  id: 29, sku: "ACC-1", name: "ASUS ROG Gladius III Gaming Mouse", slug: "asus-rog", price: 69, category: { id: 5, name: "Accessory", slug: "accessory" }, brand: { id: 4, name: "ASUS", slug: "asus" },
  stockQuantity: 38, lowStockThreshold: 5, active: true, averageRating: 4, reviewCount: 1, soldCount: 3, images: [], createdAt: "2026-11-04T15:43:04", ...over,
});
