import { api, del, get, patch, post, put } from "@/lib/api";
import type {
  Brand, Category, Coupon, CouponInput, Dashboard, InventoryItem, InventoryLog, Order, OrderStatus, PageResponse,
  Payment, Product, ProductInput, Review, SalesPoint, Shipment, ShipmentStatus, UploadResult, User, ApiResponse, Role,
} from "@/types";

const clean = (q: object) => Object.fromEntries(Object.entries(q).filter(([, v]) => v !== undefined && v !== ""));

export const adminService = {
  dashboard: () => get<Dashboard>("/admin/reports/dashboard"),
  sales: (from: string, to: string) => get<SalesPoint[]>("/admin/reports/sales", { from, to }),

  products: (q: object) => get<PageResponse<Product>>("/admin/products", clean(q)),
  product: (id: number) => get<Product>(`/admin/products/${id}`),
  createProduct: (b: ProductInput) => post<Product>("/admin/products", b),
  updateProduct: (id: number, b: ProductInput) => put<Product>(`/admin/products/${id}`, b),
  deleteProduct: (id: number) => del(`/admin/products/${id}`),
  setProductActive: (id: number, value: boolean) => patch<Product>(`/admin/products/${id}/active`, undefined, { value }),
  upload: async (file: File) => {
    const fd = new FormData();
    fd.append("file", file);
    const res = await api.post<ApiResponse<UploadResult>>("/admin/uploads", fd, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return res.data.data as UploadResult;
  },

  createCategory: (b: { name: string; description?: string }) => post<Category>("/admin/categories", b),
  updateCategory: (id: number, b: { name: string; description?: string }) => put<Category>(`/admin/categories/${id}`, b),
  deleteCategory: (id: number) => del(`/admin/categories/${id}`),
  createBrand: (b: { name: string }) => post<Brand>("/admin/brands", b),
  updateBrand: (id: number, b: { name: string }) => put<Brand>(`/admin/brands/${id}`, b),
  deleteBrand: (id: number) => del(`/admin/brands/${id}`),

  inventory: (q: object) => get<PageResponse<InventoryItem>>("/admin/inventory", clean(q)),
  lowStock: () => get<InventoryItem[]>("/admin/inventory/low-stock"),
  restock: (id: number, b: { quantity: number; note?: string }) => post<InventoryItem>(`/admin/inventory/${id}/restock`, b),
  adjust: (id: number, b: { delta: number; note?: string }) => post<InventoryItem>(`/admin/inventory/${id}/adjust`, b),
  inventoryLogs: (id: number, page = 0, size = 20) =>
    get<PageResponse<InventoryLog>>(`/admin/inventory/${id}/logs`, { page, size }),

  orders: (q: object) => get<PageResponse<Order>>("/admin/orders", clean(q)),
  order: (n: string) => get<Order>(`/admin/orders/${n}`),
  setOrderStatus: (n: string, status: OrderStatus) => patch<Order>(`/admin/orders/${n}/status`, { status }),
  ship: (n: string, trackingNumber: string) => patch<Order>(`/admin/orders/${n}/ship`, { trackingNumber }),
  setShipmentStatus: (id: number, status: ShipmentStatus) => patch<Shipment>(`/admin/shipments/${id}/status`, { status }),
  restore: (n: string) => post<Order>(`/admin/orders/${n}/restore-after-payment`),

  payments: (q: object) => get<PageResponse<Payment>>("/admin/payments", clean(q)),
  refund: (idOrOrder: string | number) => post<Payment>(`/admin/payments/${idOrOrder}/refund`),
  recheck: (n: string) => post<Payment>(`/admin/payments/${n}/recheck`),

  coupons: (page = 0, size = 20) => get<PageResponse<Coupon>>("/admin/coupons", { page, size }),
  createCoupon: (b: CouponInput) => post<Coupon>("/admin/coupons", b),
  updateCoupon: (id: number, b: CouponInput) => put<Coupon>(`/admin/coupons/${id}`, b),
  deleteCoupon: (id: number) => del(`/admin/coupons/${id}`),

  reviews: (page = 0, size = 20) => get<PageResponse<Review>>("/admin/reviews", { page, size }),
  setReviewVisible: (id: number, visible: boolean) => patch<Review>(`/admin/reviews/${id}/visibility`, { visible }),
  deleteReview: (id: number) => del(`/admin/reviews/${id}`),

  users: (q: object) => get<PageResponse<User>>("/admin/users", clean(q)),
  setUserRole: (id: number, role: Role) => patch<User>(`/admin/users/${id}/role`, { role }),
  setUserEnabled: (id: number, enabled: boolean) => patch<User>(`/admin/users/${id}/enabled`, { enabled }),
};
