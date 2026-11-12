// Sample payloads copied from API_CONTRACT.md.
import 'package:clock/clock.dart';
import 'package:ecom_mobile/features/auth/data/models/app_user.dart';
import 'package:ecom_mobile/features/cart/data/models/cart_models.dart';
import 'package:ecom_mobile/features/checkout/data/models/khqr_models.dart';
import 'package:ecom_mobile/features/order/data/models/order_models.dart';
import 'package:ecom_mobile/features/product/data/models/catalog_models.dart';
import 'package:ecom_mobile/features/profile/data/models/address.dart';

const userJson = {
  'id': 3,
  'fullName': 'Demo Customer',
  'email': 'customer@ecom.com',
  'phone': '012345678',
  'role': 'CUSTOMER',
  'enabled': true,
  'createdAt': '2026-11-04T15:43:13.993367',
};

const authJson = {
  'accessToken': 'eyJhbGciOiJIUzM4NCJ9...',
  'tokenType': 'Bearer',
  'expiresInSeconds': 86400,
  'user': userJson,
};

const productJson = {
  'id': 2,
  'sku': 'LAP-DELL-INS15',
  'name': 'Dell Inspiron 15 3530',
  'slug': 'dell-inspiron-15-3530',
  'description': 'Reliable everyday laptop.',
  'price': 749.0,
  'category': {
    'id': 1,
    'name': 'Laptop',
    'slug': 'laptop',
    'description': 'Portable computers',
  },
  'brand': {'id': 1, 'name': 'Dell', 'slug': 'dell'},
  'cpu': 'Intel Core i5-1335U',
  'ram': 16,
  'storage': '512GB SSD',
  'gpu': 'Intel Iris Xe',
  'screenSize': 15.6,
  'os': 'Windows 11 Home',
  'warrantyMonths': 12,
  'stockQuantity': 25,
  'lowStockThreshold': 5,
  'active': true,
  'averageRating': 0.0,
  'reviewCount': 0,
  'soldCount': 60,
  'images': ['https://placehold.co/600x400?text=Dell'],
  'createdAt': '2026-11-04T15:43:04.15972',
};

const accessoryJson = {
  'id': 29,
  'sku': 'ACC-ASUS-GLADIUS3',
  'name': 'ASUS ROG Gladius III Gaming Mouse',
  'price': 69, // int on purpose: must still parse as double
  'category': {'id': 5, 'name': 'Accessory', 'slug': 'accessory'},
  'brand': {'id': 4, 'name': 'ASUS', 'slug': 'asus'},
  'warrantyMonths': 24,
  'stockQuantity': 38,
  'lowStockThreshold': 5,
  'images': <String>[],
};

const cartJson = {
  'id': 1,
  'items': [
    {
      'id': 1,
      'productId': 29,
      'productName': 'ASUS ROG Gladius III Gaming Mouse',
      'imageUrl': null,
      'unitPrice': 69.0,
      'quantity': 2,
      'lineTotal': 138.0,
      'stockQuantity': 38,
    },
  ],
  'totalItems': 2,
  'subtotal': 138.0,
};

const couponJson = {
  'couponCode': 'WELCOME10',
  'subtotal': 138.0,
  'discount': 13.8,
  'shippingFee': 5.0,
  'total': 129.2,
};

const orderJson = {
  'id': 1,
  'orderNumber': 'ECOM-20261104-0001',
  'status': 'PENDING',
  'subtotal': 69.0,
  'discountAmount': 6.9,
  'shippingFee': 15.0,
  'total': 77.1,
  'couponCode': 'WELCOME10',
  'receiverName': 'Demo Customer',
  'receiverPhone': '012345678',
  'shippingAddress': 'No. 12, Street 271, Toul Kork, Phnom Penh',
  'shippingMethod': 'EXPRESS',
  'paymentMethod': 'KHQR',
  'note': 'Please call before delivery',
  'customerEmail': 'customer@ecom.com',
  'items': [
    {
      'id': 1,
      'productId': 29,
      'productName': 'ASUS ROG Gladius III Gaming Mouse',
      'unitPrice': 69.0,
      'quantity': 1,
      'lineTotal': 69.0,
    },
  ],
  'payment': {
    'id': 1,
    'orderNumber': 'ECOM-20261104-0001',
    'method': 'KHQR',
    'status': 'PENDING',
    'amount': 77.1,
  },
  'shipment': {
    'id': 1,
    'orderNumber': 'ECOM-20261104-0001',
    'method': 'EXPRESS',
    'fee': 15.0,
    'status': 'PREPARING',
  },
  'createdAt': '2026-11-04T15:43:17.811458',
};

const khqrJson = {
  'orderNumber': 'ECOM-20261104-0001',
  'amount': 77.1,
  'currency': 'USD',
  'qrString':
      'MOCK-KHQR|merchant=ECOM|order=ECOM-20261104-0001|amount=77.10|currency=USD|nonce=0bc2',
  'qrPayload':
      'MOCK-KHQR|merchant=ECOM|order=ECOM-20261104-0001|amount=77.10|currency=USD|nonce=0bc2',
  'md5': 'ea9e713b89e641e7d11c984060b255bf',
  'expiresAt': '2026-11-04T15:53:18.039323947',
  'mode': 'MOCK',
};

const notificationJson = {
  'id': 7,
  'type': 'PUSH',
  'title': 'Order delivered',
  'message': 'Your order has been delivered.',
  'read': false,
  'createdAt': '2026-11-04T15:43:18.239598',
  'priority': 'NORMAL',
};

Map<String, dynamic> envelope(
  Object? data, {
  String message = 'Success',
  String ts = '2026-11-04T15:43:18.04107867',
}) => {'success': true, 'message': message, 'data': data, 'timestamp': ts};

Map<String, dynamic> pageOf(List<Object?> content, {bool last = true}) => {
  'content': content,
  'page': 0,
  'size': 12,
  'totalElements': content.length,
  'totalPages': 1,
  'last': last,
};

// ---- typed builders for widget tests ----
Product testProduct({
  int id = 1,
  String name = 'Test Laptop',
  double price = 999,
  int stock = 10,
  int low = 5,
  double rating = 4.5,
  int reviews = 3,
}) => Product(
  id: id,
  name: name,
  price: price,
  stockQuantity: stock,
  lowStockThreshold: low,
  averageRating: rating,
  reviewCount: reviews,
  brand: const Brand(id: 1, name: 'Dell'),
);

const testUser = AppUser(
  id: 3,
  fullName: 'Demo Customer',
  email: 'customer@ecom.com',
  phone: '012345678',
);

const testAddress = Address(
  id: 1,
  receiverName: 'Demo Customer',
  phone: '012345678',
  line1: 'No. 12, Street 271',
  city: 'Phnom Penh',
  isDefault: true,
);

const testCart = Cart(
  id: 1,
  totalItems: 2,
  subtotal: 138,
  items: [
    CartItem(
      id: 1,
      productId: 29,
      productName: 'ASUS ROG Gladius III Gaming Mouse',
      unitPrice: 69,
      quantity: 2,
      lineTotal: 138,
      stockQuantity: 38,
    ),
  ],
);

Order testOrder({
  String status = 'PENDING',
  String payStatus = 'PENDING',
  String method = 'KHQR',
}) => Order.fromJson({
  ...orderJson,
  'status': status,
  'paymentMethod': method,
  'payment': {
    ...(orderJson['payment'] as Map<String, dynamic>),
    'status': payStatus,
    'method': method,
  },
});

KhqrSession testSession({
  String mode = 'MOCK',
  Duration validFor = const Duration(minutes: 10),
}) => KhqrSession(
  data: KhqrData(
    orderNumber: 'ECOM-20261104-0001',
    amount: 77.1,
    qrString: 'MOCK-KHQR|order=ECOM-20261104-0001',
    expiresAt: DateTime(2026, 11, 4, 15, 53),
    mode: mode,
  ),
  expiresAtLocal: clock.now().add(validFor),
);
