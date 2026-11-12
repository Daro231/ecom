export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data?: T;
  errors?: Record<string, string>;
  timestamp: string;
}
export interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  last: boolean;
}

export type Role = "ADMIN" | "STAFF" | "CUSTOMER";
export type OrderStatus = "PENDING" | "CONFIRMED" | "PROCESSING" | "SHIPPED" | "DELIVERED" | "CANCELLED";
export type PaymentStatus = "PENDING" | "PAID" | "FAILED" | "REFUNDED" | "PAID_AFTER_CANCEL";
export type PaymentMethod = "KHQR" | "CASH_ON_DELIVERY" | "CARD" | "BANK_TRANSFER";
export type ShippingMethodCode = "STANDARD" | "EXPRESS" | "SAME_DAY";
export type ShipmentStatus = "PREPARING" | "IN_TRANSIT" | "OUT_FOR_DELIVERY" | "DELIVERED";
export type DiscountType = "PERCENT" | "FIXED";
export type NotificationPriority = "NORMAL" | "HIGH";
export type InventoryReason = "RESTOCK" | "ORDER" | "CANCEL" | "ADJUST";

export interface User {
  id: number;
  fullName: string;
  email: string;
  phone?: string;
  role: Role;
  enabled: boolean;
  createdAt: string;
}
export interface AuthResult {
  accessToken: string;
  tokenType: string;
  expiresInSeconds: number;
  user: User;
}

export interface Address {
  id: number;
  receiverName: string;
  phone: string;
  line1: string;
  city: string;
  isDefault: boolean;
  latitude?: number;
  longitude?: number;
}
export interface AddressInput {
  receiverName: string;
  phone: string;
  line1: string;
  city: string;
  isDefault: boolean;
  latitude?: number;
  longitude?: number;
}

export interface Category { id: number; name: string; slug: string; description?: string }
export interface Brand { id: number; name: string; slug: string }
export interface Product {
  id: number;
  sku: string;
  name: string;
  slug: string;
  description?: string;
  price: number;
  category: Category;
  brand: Brand;
  cpu?: string;
  ram?: number;
  storage?: string;
  gpu?: string;
  screenSize?: number;
  os?: string;
  warrantyMonths?: number;
  stockQuantity: number;
  lowStockThreshold: number;
  active: boolean;
  averageRating: number;
  reviewCount: number;
  soldCount: number;
  images?: string[];
  createdAt: string;
}
export interface ProductInput {
  sku: string;
  name: string;
  description?: string;
  price: number;
  categoryId: number;
  brandId: number;
  cpu?: string;
  ram?: number;
  storage?: string;
  gpu?: string;
  screenSize?: number;
  os?: string;
  warrantyMonths?: number;
  stockQuantity: number;
  lowStockThreshold: number;
  active: boolean;
  imageUrls: string[];
}
export interface ProductQuery {
  keyword?: string;
  categoryId?: number;
  brandId?: number;
  minPrice?: number;
  maxPrice?: number;
  ram?: number;
  minRating?: number;
  inStock?: boolean;
  sort?: string;
  page?: number;
  size?: number;
}

export interface ShippingMethod {
  code: ShippingMethodCode;
  label: string;
  fee: number;
  estimatedDelivery: string;
  freeShippingThreshold?: number;
}

export interface CartItem {
  id: number;
  productId: number;
  productName: string;
  imageUrl?: string;
  unitPrice: number;
  quantity: number;
  lineTotal: number;
  stockQuantity: number;
}
export interface Cart { id: number; items: CartItem[]; totalItems: number; subtotal: number }
export interface CouponPreview {
  couponCode: string;
  subtotal: number;
  discount: number;
  shippingFee: number;
  total: number;
}

export interface OrderItem {
  id: number;
  productId: number;
  productName: string;
  unitPrice: number;
  quantity: number;
  lineTotal: number;
}
export interface Payment {
  id: number;
  orderNumber: string;
  method: PaymentMethod;
  status: PaymentStatus;
  amount: number;
  transactionRef?: string;
  paidAt?: string;
  failureReason?: string;
}
export interface Shipment {
  id: number;
  orderNumber: string;
  method: ShippingMethodCode;
  fee: number;
  trackingNumber?: string;
  status: ShipmentStatus;
  shippedAt?: string;
  deliveredAt?: string;
}
export interface Order {
  id: number;
  orderNumber: string;
  status: OrderStatus;
  subtotal: number;
  discountAmount: number;
  shippingFee: number;
  total: number;
  couponCode?: string;
  receiverName: string;
  receiverPhone: string;
  shippingAddress: string;
  deliveryLatitude?: number;
  deliveryLongitude?: number;
  shippingMethod: ShippingMethodCode;
  paymentMethod: PaymentMethod;
  note?: string;
  cancelledReason?: string;
  customerEmail?: string;
  items: OrderItem[];
  payment?: Payment;
  shipment?: Shipment;
  createdAt: string;
}
export interface CheckoutInput {
  addressId: number;
  shippingMethod: ShippingMethodCode;
  paymentMethod: PaymentMethod;
  couponCode?: string;
  note?: string;
}
export interface Invoice {
  invoiceNumber: string;
  issuedAt: string;
  orderNumber: string;
  orderStatus: OrderStatus;
  customerName: string;
  customerEmail: string;
  receiverName: string;
  receiverPhone: string;
  shippingAddress: string;
  items: OrderItem[];
  subtotal: number;
  discountAmount: number;
  couponCode?: string;
  shippingFee: number;
  total: number;
  payment?: Payment;
}

export interface KhqrData {
  orderNumber: string;
  amount: number;
  currency: string;
  qrString: string;
  md5?: string;
  expiresAt: string;
  mode: "MOCK" | "BAKONG";
  /** Server clock at response time (envelope timestamp); used instead of the PC clock. */
  serverTime?: string;
}

export interface Review {
  id: number;
  productId: number;
  productName: string;
  userId: number;
  userName: string;
  rating: number;
  comment?: string;
  verifiedPurchase: boolean;
  visible: boolean;
  createdAt: string;
}

export interface AppNotification {
  id: number;
  type: "EMAIL" | "SMS" | "PUSH" | "ACCOUNT";
  title: string;
  message: string;
  read: boolean;
  createdAt: string;
  priority: NotificationPriority;
}

export interface Coupon {
  id: number;
  code: string;
  discountType: DiscountType;
  value: number;
  minOrderAmount?: number;
  maxUses?: number;
  usedCount: number;
  startAt?: string;
  endAt?: string;
  active: boolean;
}
export interface CouponInput {
  code: string;
  discountType: DiscountType;
  value: number;
  minOrderAmount?: number;
  maxUses?: number;
  startAt?: string;
  endAt?: string;
  active: boolean;
}

export interface InventoryItem {
  productId: number;
  sku: string;
  name: string;
  stockQuantity: number;
  lowStockThreshold: number;
  category: string;
  lowStock: boolean;
}
export interface InventoryLog {
  id: number;
  productId: number;
  changeQuantity: number;
  reason: InventoryReason;
  stockAfter: number;
  createdBy?: number;
  note?: string;
  createdAt: string;
}

export interface Dashboard {
  totalSales: number;
  totalOrders: number;
  ordersByStatus: Record<string, number>;
  totalCustomers: number;
  topProducts: { productId: number; name: string; quantitySold: number }[];
  lowStockCount: number;
}
export interface SalesPoint { date: string; orders: number; revenue: number }
export interface UploadResult { filename: string; url: string; size: number }
