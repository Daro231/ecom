# ecom API Contract

Base URL: `http://localhost:8080` - all endpoints are prefixed with `/api/v1`.
Interactive docs: Swagger UI `/swagger-ui.html`, OpenAPI JSON `/v3/api-docs`.

This document is the contract for the Next.js web app and the Flutter mobile app.
Every example below was captured from the running application (list responses show only their first element), except the late-payment examples in section 12, which need Bakong mode and are written from the integration tests.

**API status: frozen.** The late-payment change (`PAID_AFTER_CANCEL`, notification `priority`, `restore-after-payment`, refund by order number) is the last backend change; from here only additive, backwards-compatible fixes are allowed.

## 1. Conventions

### Authentication
`POST /auth/login` (or `/auth/register`) returns a JWT `accessToken` valid for **24 hours**.
Send it on protected endpoints as `Authorization: Bearer <accessToken>`.

| Role | What it can do |
|---|---|
| `CUSTOMER` | browse, cart, checkout, own orders/addresses/reviews/notifications |
| `STAFF` | everything a customer can, plus `/admin/orders/**`, `/admin/inventory/**`, `/admin/shipments/**` |
| `ADMIN` | everything, including all other `/admin/**` endpoints |

A customer can never see or change another customer's cart, order, address, review or notification - those requests return **404**.

### Response envelope
Every response (success or error) has the same shape:

```json
{ "success": true, "message": "Product created", "data": { }, "timestamp": "2026-10-25T10:00:00" }
```

Errors have `success:false`, a `message`, and for validation errors an `errors` map `field -> message`:

```json
{ "success": false, "message": "Validation failed", "errors": { "email": "Email is invalid" }, "timestamp": "2026-10-25T10:00:00" }
```

### Paging
Paged endpoints accept `page` (0-based) and `size` (max 100) and return `data` as:

```json
{ "content": [ ], "page": 0, "size": 12, "totalElements": 29, "totalPages": 3, "last": false }
```

### HTTP status codes
| Code | Meaning |
|---|---|
| 200 / 201 | OK / created |
| 400 | validation error, malformed JSON, invalid state transition, invalid coupon, empty cart |
| 401 | missing/invalid/expired token, wrong login credentials, disabled account |
| 403 | authenticated but not allowed (wrong role, or reviewing a product you did not receive) |
| 404 | resource not found **or not owned by the caller** |
| 409 | conflict: duplicate email/SKU/name, insufficient stock, concurrent modification, delete blocked by references |
| 502 / 504 | payment provider (Bakong) unusable / timed out - only on KHQR status checks in `bakong` mode |
| 500 | unexpected server error |

### Money, dates, enums
- Money values are decimals with 2 digits (USD), e.g. `1199.00`. Free shipping applies when `subtotal >= 1000`.
- Timestamps are ISO-8601 local date-times, possibly with fractional seconds (`2026-10-25T10:00:00` or `2026-10-25T10:00:00.123456`); query dates are `yyyy-MM-dd`.
- `Role`: `ADMIN | STAFF | CUSTOMER`
- `OrderStatus`: `PENDING -> CONFIRMED -> PROCESSING -> SHIPPED -> DELIVERED`, plus `CANCELLED` (allowed from PENDING / CONFIRMED / PROCESSING). Invalid transitions return 400.
- `PaymentMethod`: `CASH_ON_DELIVERY | KHQR | CARD | BANK_TRANSFER`; `PaymentStatus`: `PENDING | PAID | FAILED | REFUNDED | PAID_AFTER_CANCEL` (customer paid a KHQR order after it was auto-cancelled; admin must restore or refund, see "Late payments")
- `ShippingMethod`: `STANDARD` ($5, 3-5 days), `EXPRESS` ($15, 1-2 days), `SAME_DAY` ($25, Phnom Penh)
- `ShipmentStatus`: `PREPARING | IN_TRANSIT | OUT_FOR_DELIVERY | DELIVERED`
- `DiscountType`: `PERCENT | FIXED`; `NotificationType`: `EMAIL | SMS | PUSH | ACCOUNT`; `NotificationPriority`: `NORMAL | HIGH` (`priority` field on every notification; `HIGH` = admin must act, e.g. a late KHQR payment); `InventoryReason`: `RESTOCK | ORDER | CANCEL | ADJUST`

### Search & filter parameters for `GET /products`
`keyword` (name, description, CPU, category, brand), `categoryId`, `brandId`, `minPrice`, `maxPrice`, `ram` (GB), `minRating`, `inStock` (true/false),
`sort` = `price_asc | price_desc | newest | rating | popular`, `page`, `size`.

### Business rules worth knowing
- Checkout is atomic: stock is re-checked, prices are snapshotted into the order, stock is deducted, the coupon usage is counted, a PENDING payment and PREPARING shipment are created and the cart is emptied.
- KHQR payments: see section "KHQR payments (mock and Bakong modes)" below.
- Cash on delivery: payment stays `PENDING` until the order is `DELIVERED`, then becomes `PAID` automatically.
- Cancelling restores stock; a `PAID` payment becomes `REFUNDED`. Unpaid KHQR orders are cancelled automatically after 30 minutes (see KHQR payments). A customer who still pays such an order within 24 hours (bakong mode) lands in `PAID_AFTER_CANCEL` and an admin restores or refunds it (see "Late payments").
- A review is only allowed after a `DELIVERED` order containing the product (else 403); one review per user per product (else 409).
- Concurrent checkouts for the last unit: one succeeds (201), the other gets 409.
- Uploaded images are served publicly from `/uploads/<file>`.

### KHQR payments (mock and Bakong modes)
The backend runs in one of two modes, chosen by the server setting `KHQR_MODE`; every KHQR response tells the client which one it is talking to in `data.mode` (`MOCK` or `BAKONG`).

| | `mock` (default, tests / offline) | `bakong` (real money) |
|---|---|---|
| `POST /payments/{orderNumber}/khqr` | returns a fake QR string | returns a real, scannable KHQR for the exact order total (BakongKHQR SDK), valid for 10 minutes |
| How the payment is confirmed | the simulated gateway calls `POST /payments/callback` | the backend asks Bakong (check by MD5). **There is no webhook**: the client polls `GET /payments/{orderNumber}/status` every ~5 s and a server job checks too |
| `POST /payments/callback` | works (public) | **404**, nobody can fake a payment |
| `POST /admin/payments/{orderNumber}/recheck` | 400 | re-checks with Bakong now |

Client flow for `bakong`:
1. Checkout with `paymentMethod: "KHQR"` -> order `PENDING`.
2. `POST /payments/{orderNumber}/khqr` -> show `data.qrString` as a QR image (render it client-side) plus the amount and a countdown to `data.expiresAt`. Calling it again returns the **same** QR while it is still valid.
3. Poll `GET /payments/{orderNumber}/status` (the server limits real Bakong calls to one per 3 s per payment). When `data.status` is `PAID` the order is already `CONFIRMED`.
4. If `data.status` is `FAILED`: `failureReason` is `"QR expired"` (call the khqr endpoint again to get a new QR, the order stays `PENDING`) or a mismatch text (wrong amount / currency / receiving account, the payment is never marked PAID; an admin is alerted).
5. **Auto-cancel:** a KHQR order that is still unpaid **30 minutes** after it was created (configurable, `KHQR_AUTO_CANCEL_MINUTES`, `0` = never) is cancelled by the server: `status: "CANCELLED"`, `cancelledReason: "KHQR payment timeout"`, `payment.status: "FAILED"`, stock is restored and the customer gets an "Order cancelled" notification. Clients should therefore treat a `CANCELLED` order as final and stop asking for QR codes (the khqr endpoint answers 400 for cancelled orders). Cash-on-delivery orders and paid orders are never auto-cancelled.
6. **Late payments (bakong mode only):** the server keeps asking Bakong about auto-cancelled KHQR orders for **24 hours** after the cancel (configurable, `KHQR_LATE_PAYMENT_WATCH_HOURS`, `0` = off; checked about once a minute). If Bakong reports the QR as paid with the same amount, currency and receiving account: the payment becomes `PAID_AFTER_CANCEL` (`failureReason: "Paid after auto-cancel"`, `paidAt`/`transactionRef` filled), the order **stays `CANCELLED`**, stock is **not** re-reserved, and every admin gets a `HIGH`-priority notification titled `Customer paid after cancel - refund or restore order`. Customer apps will therefore see `order.status = CANCELLED` together with `payment.status = PAID_AFTER_CANCEL`; show something like "We received your payment - the store will restore or refund your order" instead of "unpaid". A late payment with a wrong amount/currency/account is never accepted: the watch stops and admins get one `HIGH` "KHQR payment needs attention" notification. Admin actions: `POST /admin/orders/{orderNumber}/restore-after-payment` or `POST /admin/payments/{orderNumber}/refund` (section 12). In mock mode there is no late-payment watch.
7. `502` from the status endpoint = the payment provider is not usable right now (e.g. expired API token); `504` = Bakong timed out. Both are safe to retry; the order is unaffected.

`data.amount` and `data.currency` are what the QR encodes (USD by default; with `BAKONG_CURRENCY=KHR` the USD total is converted at `BAKONG_KHR_PER_USD`).
`data.qrPayload` is a deprecated alias of `data.qrString`.

### Seed accounts (dev profile)
`admin@ecom.com / Admin@123`, `staff@ecom.com / Staff@123`, `customer@ecom.com / Customer@123`. Coupons: `WELCOME10` (10%), `SAVE50` ($50 off, min $500), `EXPIRED` (always rejected).


## 01 Auth

### Register (new random customer)
`POST /api/v1/auth/register`  
**Role:** Public

Request body:
```json
{
  "fullName": "Postman User",
  "email": "dara@example.com",
  "password": "Passw0rd!",
  "phone": "012345678"
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Registered successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzM4NCJ9...",
    "tokenType": "Bearer",
    "expiresInSeconds": 86400,
    "user": {
      "id": 4,
      "fullName": "Postman User",
      "email": "postman1793781796480@test.com",
      "phone": "012345678",
      "role": "CUSTOMER",
      "enabled": true,
      "createdAt": "2026-11-04T15:43:16.607548428"
    }
  },
  "timestamp": "2026-11-04T15:43:16.668690626"
}
```

### Login - customer (saves token)
`POST /api/v1/auth/login`  
**Role:** Public

Request body:
```json
{
  "email": "customer@ecom.com",
  "password": "Customer@123"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzM4NCJ9...",
    "tokenType": "Bearer",
    "expiresInSeconds": 86400,
    "user": {
      "id": 3,
      "fullName": "Demo Customer",
      "email": "customer@ecom.com",
      "phone": "012345678",
      "role": "CUSTOMER",
      "enabled": true,
      "createdAt": "2026-11-04T15:43:13.993367"
    }
  },
  "timestamp": "2026-11-04T15:43:16.781032847"
}
```

### Login - admin (saves adminToken)
`POST /api/v1/auth/login`  
**Role:** Public

Request body:
```json
{
  "email": "admin@ecom.com",
  "password": "Admin@123"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzM4NCJ9...",
    "tokenType": "Bearer",
    "expiresInSeconds": 86400,
    "user": {
      "id": 1,
      "fullName": "Admin",
      "email": "admin@ecom.com",
      "phone": "012345678",
      "role": "ADMIN",
      "enabled": true,
      "createdAt": "2026-11-04T15:43:13.818827"
    }
  },
  "timestamp": "2026-11-04T15:43:16.876799719"
}
```

### Login - staff (saves staffToken)
`POST /api/v1/auth/login`  
**Role:** Public

Request body:
```json
{
  "email": "staff@ecom.com",
  "password": "Staff@123"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzM4NCJ9...",
    "tokenType": "Bearer",
    "expiresInSeconds": 86400,
    "user": {
      "id": 2,
      "fullName": "Staff",
      "email": "staff@ecom.com",
      "phone": "012345678",
      "role": "STAFF",
      "enabled": true,
      "createdAt": "2026-11-04T15:43:13.917786"
    }
  },
  "timestamp": "2026-11-04T15:43:16.967704742"
}
```

## 02 Profile & Addresses

### Get my profile
`GET /api/v1/users/me`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 3,
    "fullName": "Demo Customer",
    "email": "customer@ecom.com",
    "phone": "012345678",
    "role": "CUSTOMER",
    "enabled": true,
    "createdAt": "2026-11-04T15:43:13.993367"
  },
  "timestamp": "2026-11-04T15:43:17.044774954"
}
```

### Update my profile
`PUT /api/v1/users/me`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "fullName": "Demo Customer",
  "phone": "012345678"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Profile updated",
  "data": {
    "id": 3,
    "fullName": "Demo Customer",
    "email": "customer@ecom.com",
    "phone": "012345678",
    "role": "CUSTOMER",
    "enabled": true,
    "createdAt": "2026-11-04T15:43:13.993367"
  },
  "timestamp": "2026-11-04T15:43:17.071566133"
}
```

### Change password (new user from Register)
`PUT /api/v1/users/me/password`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "currentPassword": "Passw0rd!",
  "newPassword": "NewPassw0rd!"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Password changed",
  "timestamp": "2026-11-04T15:43:17.267325945"
}
```

### List my addresses (saves addressId)
`GET /api/v1/users/me/addresses`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": 1,
      "receiverName": "Demo Customer",
      "phone": "012345678",
      "line1": "No. 12, Street 271, Toul Kork",
      "city": "Phnom Penh",
      "isDefault": true
    }
  ],
  "timestamp": "2026-11-04T15:43:17.293832746"
}
```

### Add address (saves newAddressId)
`POST /api/v1/users/me/addresses`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "receiverName": "Sok Dara",
  "phone": "012111222",
  "line1": "No. 5, Street 63, Boeung Keng Kang",
  "city": "Phnom Penh",
  "isDefault": false
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Address added",
  "data": {
    "id": 2,
    "receiverName": "Sok Dara",
    "phone": "012111222",
    "line1": "No. 5, Street 63, Boeung Keng Kang",
    "city": "Phnom Penh",
    "isDefault": false
  },
  "timestamp": "2026-11-04T15:43:17.32417774"
}
```

### Update address
`PUT /api/v1/users/me/addresses/1`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "receiverName": "Sok Dara",
  "phone": "012111222",
  "line1": "No. 9, Street 63",
  "city": "Phnom Penh",
  "isDefault": false
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Address updated",
  "data": {
    "id": 2,
    "receiverName": "Sok Dara",
    "phone": "012111222",
    "line1": "No. 9, Street 63",
    "city": "Phnom Penh",
    "isDefault": false
  },
  "timestamp": "2026-11-04T15:43:17.349447617"
}
```

### Set address as default
`PATCH /api/v1/users/me/addresses/1/default`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Default address updated",
  "data": {
    "id": 2,
    "receiverName": "Sok Dara",
    "phone": "012111222",
    "line1": "No. 9, Street 63",
    "city": "Phnom Penh",
    "isDefault": true
  },
  "timestamp": "2026-11-04T15:43:17.371831498"
}
```

### Make original address default again
`PATCH /api/v1/users/me/addresses/1/default`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Default address updated",
  "data": {
    "id": 1,
    "receiverName": "Demo Customer",
    "phone": "012345678",
    "line1": "No. 12, Street 271, Toul Kork",
    "city": "Phnom Penh",
    "isDefault": true
  },
  "timestamp": "2026-11-04T15:43:17.394360636"
}
```

### Delete address
`DELETE /api/v1/users/me/addresses/1`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Address deleted",
  "timestamp": "2026-11-04T15:43:17.416239122"
}
```

## 03 Catalog (public)

### Search products (laptop, 500-1000, Dell, RAM 16)
`GET /api/v1/products?keyword=laptop&minPrice=500&maxPrice=1000&brandId=1&ram=16&sort=price_asc&page=0&size=12`  
**Role:** Public

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 2,
        "sku": "LAP-DELL-INS15",
        "name": "Dell Inspiron 15 3530",
        "slug": "dell-inspiron-15-3530",
        "description": "Reliable everyday laptop with a 15.6-inch Full HD screen for school and office work.",
        "price": 749.0,
        "category": {
          "id": 1,
          "name": "Laptop",
          "slug": "laptop",
          "description": "Portable computers for work, study and gaming"
        },
        "brand": {
          "id": 1,
          "name": "Dell",
          "slug": "dell"
        },
        "cpu": "Intel Core i5-1335U",
        "ram": 16,
        "storage": "512GB SSD",
        "gpu": "Intel Iris Xe",
        "screenSize": 15.6,
        "os": "Windows 11 Home",
        "warrantyMonths": 12,
        "stockQuantity": 25,
        "lowStockThreshold": 5,
        "active": true,
        "averageRating": 0.0,
        "reviewCount": 0,
        "soldCount": 60,
        "images": [
          "https://placehold.co/600x400?text=Dell+Inspiron+15+3530"
        ],
        "createdAt": "2026-11-04T15:43:04.15972"
      }
    ],
    "page": 0,
    "size": 12,
    "totalElements": 1,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-11-04T15:43:17.473611036"
}
```

### List products (newest, saves productId)
`GET /api/v1/products?sort=newest&inStock=true&size=12`  
**Role:** Public

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 29,
        "sku": "ACC-ASUS-GLADIUS3",
        "name": "ASUS ROG Gladius III Gaming Mouse",
        "slug": "asus-rog-gladius-iii-gaming-mouse",
        "description": "Lightweight wired gaming mouse with a 26,000 DPI sensor.",
        "price": 69.0,
        "category": {
          "id": 5,
          "name": "Accessory",
          "slug": "accessory",
          "description": "Mice, keyboards, docks and other accessories"
        },
        "brand": {
          "id": 4,
          "name": "ASUS",
          "slug": "asus"
        },
        "warrantyMonths": 24,
        "stockQuantity": 38,
        "lowStockThreshold": 5,
        "active": true,
        "averageRating": 0.0,
        "reviewCount": 0,
        "soldCount": 29,
        "images": [
          "https://placehold.co/600x400?text=ASUS+ROG+Gladius+III+Gaming+Mouse"
        ],
        "createdAt": "2026-11-04T15:43:04.15972"
      }
    ],
    "page": 0,
    "size": 12,
    "totalElements": 29,
    "totalPages": 3,
    "last": false
  },
  "timestamp": "2026-11-04T15:43:17.512113874"
}
```

### Get product by id
`GET /api/v1/products/1`  
**Role:** Public

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 29,
    "sku": "ACC-ASUS-GLADIUS3",
    "name": "ASUS ROG Gladius III Gaming Mouse",
    "slug": "asus-rog-gladius-iii-gaming-mouse",
    "description": "Lightweight wired gaming mouse with a 26,000 DPI sensor.",
    "price": 69.0,
    "category": {
      "id": 5,
      "name": "Accessory",
      "slug": "accessory",
      "description": "Mice, keyboards, docks and other accessories"
    },
    "brand": {
      "id": 4,
      "name": "ASUS",
      "slug": "asus"
    },
    "warrantyMonths": 24,
    "stockQuantity": 38,
    "lowStockThreshold": 5,
    "active": true,
    "averageRating": 0.0,
    "reviewCount": 0,
    "soldCount": 29,
    "images": [
      "https://placehold.co/600x400?text=ASUS+ROG+Gladius+III+Gaming+Mouse"
    ],
    "createdAt": "2026-11-04T15:43:04.15972"
  },
  "timestamp": "2026-11-04T15:43:17.532650513"
}
```

### Get product by slug
`GET /api/v1/products/slug/dell-xps-13-9340`  
**Role:** Public

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 29,
    "sku": "ACC-ASUS-GLADIUS3",
    "name": "ASUS ROG Gladius III Gaming Mouse",
    "slug": "asus-rog-gladius-iii-gaming-mouse",
    "description": "Lightweight wired gaming mouse with a 26,000 DPI sensor.",
    "price": 69.0,
    "category": {
      "id": 5,
      "name": "Accessory",
      "slug": "accessory",
      "description": "Mice, keyboards, docks and other accessories"
    },
    "brand": {
      "id": 4,
      "name": "ASUS",
      "slug": "asus"
    },
    "warrantyMonths": 24,
    "stockQuantity": 38,
    "lowStockThreshold": 5,
    "active": true,
    "averageRating": 0.0,
    "reviewCount": 0,
    "soldCount": 29,
    "images": [
      "https://placehold.co/600x400?text=ASUS+ROG+Gladius+III+Gaming+Mouse"
    ],
    "createdAt": "2026-11-04T15:43:04.15972"
  },
  "timestamp": "2026-11-04T15:43:17.551334203"
}
```

### List categories (saves categoryId)
`GET /api/v1/categories`  
**Role:** Public

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": 5,
      "name": "Accessory",
      "slug": "accessory",
      "description": "Mice, keyboards, docks and other accessories"
    }
  ],
  "timestamp": "2026-11-04T15:43:17.566879955"
}
```

### List brands (saves brandId)
`GET /api/v1/brands`  
**Role:** Public

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": 4,
      "name": "ASUS",
      "slug": "asus"
    }
  ],
  "timestamp": "2026-11-04T15:43:17.582614678"
}
```

### List shipping methods
`GET /api/v1/shipping/methods`  
**Role:** Public

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "code": "STANDARD",
      "label": "Standard",
      "fee": 5.0,
      "estimatedDelivery": "3-5 days",
      "freeShippingThreshold": 1000.0
    }
  ],
  "timestamp": "2026-11-04T15:43:17.595774243"
}
```

## 04 Cart

### Get cart
`GET /api/v1/cart`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 1,
    "items": [],
    "totalItems": 0,
    "subtotal": 0.0
  },
  "timestamp": "2026-11-04T15:43:17.633270588"
}
```

### Add item (saves itemId)
`POST /api/v1/cart/items`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "productId": 1,
  "quantity": 1
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Item added to cart",
  "data": {
    "id": 1,
    "items": [
      {
        "id": 1,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "imageUrl": "https://placehold.co/600x400?text=ASUS+ROG+Gladius+III+Gaming+Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0,
        "stockQuantity": 38
      }
    ],
    "totalItems": 1,
    "subtotal": 69.0
  },
  "timestamp": "2026-11-04T15:43:17.667855646"
}
```

### Update item quantity
`PUT /api/v1/cart/items/1`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "quantity": 2
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Cart updated",
  "data": {
    "id": 1,
    "items": [
      {
        "id": 1,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "imageUrl": "https://placehold.co/600x400?text=ASUS+ROG+Gladius+III+Gaming+Mouse",
        "unitPrice": 69.0,
        "quantity": 2,
        "lineTotal": 138.0,
        "stockQuantity": 38
      }
    ],
    "totalItems": 2,
    "subtotal": 138.0
  },
  "timestamp": "2026-11-04T15:43:17.693271413"
}
```

### Apply coupon WELCOME10 (preview)
`POST /api/v1/cart/apply-coupon`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "code": "WELCOME10",
  "shippingMethod": "STANDARD"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Coupon applied",
  "data": {
    "couponCode": "WELCOME10",
    "subtotal": 138.0,
    "discount": 13.8,
    "shippingFee": 5.0,
    "total": 129.2
  },
  "timestamp": "2026-11-04T15:43:17.720048517"
}
```

### Remove item
`DELETE /api/v1/cart/items/1`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Item removed",
  "data": {
    "id": 1,
    "items": [],
    "totalItems": 0,
    "subtotal": 0.0
  },
  "timestamp": "2026-11-04T15:43:17.742732164"
}
```

### Add item again
`POST /api/v1/cart/items`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "productId": 1,
  "quantity": 1
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Item added to cart",
  "data": {
    "id": 1,
    "items": [
      {
        "id": 2,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "imageUrl": "https://placehold.co/600x400?text=ASUS+ROG+Gladius+III+Gaming+Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0,
        "stockQuantity": 38
      }
    ],
    "totalItems": 1,
    "subtotal": 69.0
  },
  "timestamp": "2026-11-04T15:43:17.770753092"
}
```

## 05 Orders & Checkout

### Checkout - KHQR with WELCOME10 (saves orderNumber)
`POST /api/v1/orders/checkout`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "addressId": 1,
  "shippingMethod": "EXPRESS",
  "paymentMethod": "KHQR",
  "couponCode": "WELCOME10",
  "note": "Please call before delivery"
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Order placed",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "status": "PENDING",
    "subtotal": 69.0,
    "discountAmount": 6.9,
    "shippingFee": 15.0,
    "total": 77.1,
    "couponCode": "WELCOME10",
    "receiverName": "Demo Customer",
    "receiverPhone": "012345678",
    "shippingAddress": "No. 12, Street 271, Toul Kork, Phnom Penh",
    "shippingMethod": "EXPRESS",
    "paymentMethod": "KHQR",
    "note": "Please call before delivery",
    "customerEmail": "customer@ecom.com",
    "items": [
      {
        "id": 1,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0
      }
    ],
    "payment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "KHQR",
      "status": "PENDING",
      "amount": 77.1
    },
    "shipment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "EXPRESS",
      "fee": 15.0,
      "status": "PREPARING"
    },
    "createdAt": "2026-11-04T15:43:17.811457943"
  },
  "timestamp": "2026-11-04T15:43:17.836908509"
}
```

### List my orders
`GET /api/v1/orders?page=0&size=10`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 1,
        "orderNumber": "ECOM-20261104-0001",
        "status": "PENDING",
        "subtotal": 69.0,
        "discountAmount": 6.9,
        "shippingFee": 15.0,
        "total": 77.1,
        "couponCode": "WELCOME10",
        "receiverName": "Demo Customer",
        "receiverPhone": "012345678",
        "shippingAddress": "No. 12, Street 271, Toul Kork, Phnom Penh",
        "shippingMethod": "EXPRESS",
        "paymentMethod": "KHQR",
        "note": "Please call before delivery",
        "customerEmail": "customer@ecom.com",
        "items": [
          {
            "id": 1,
            "productId": 29,
            "productName": "ASUS ROG Gladius III Gaming Mouse",
            "unitPrice": 69.0,
            "quantity": 1,
            "lineTotal": 69.0
          }
        ],
        "payment": {
          "id": 1,
          "orderNumber": "ECOM-20261104-0001",
          "method": "KHQR",
          "status": "PENDING",
          "amount": 77.1
        },
        "shipment": {
          "id": 1,
          "orderNumber": "ECOM-20261104-0001",
          "method": "EXPRESS",
          "fee": 15.0,
          "status": "PREPARING"
        },
        "createdAt": "2026-11-04T15:43:17.811458"
      }
    ],
    "page": 0,
    "size": 10,
    "totalElements": 1,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-11-04T15:43:17.867874546"
}
```

### Get order
`GET /api/v1/orders/ECOM-20261104-0001`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "status": "PENDING",
    "subtotal": 69.0,
    "discountAmount": 6.9,
    "shippingFee": 15.0,
    "total": 77.1,
    "couponCode": "WELCOME10",
    "receiverName": "Demo Customer",
    "receiverPhone": "012345678",
    "shippingAddress": "No. 12, Street 271, Toul Kork, Phnom Penh",
    "shippingMethod": "EXPRESS",
    "paymentMethod": "KHQR",
    "note": "Please call before delivery",
    "customerEmail": "customer@ecom.com",
    "items": [
      {
        "id": 1,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0
      }
    ],
    "payment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "KHQR",
      "status": "PENDING",
      "amount": 77.1
    },
    "shipment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "EXPRESS",
      "fee": 15.0,
      "status": "PREPARING"
    },
    "createdAt": "2026-11-04T15:43:17.811458"
  },
  "timestamp": "2026-11-04T15:43:17.891533632"
}
```

### Get invoice (JSON)
`GET /api/v1/orders/ECOM-20261104-0001/invoice`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "invoiceNumber": "INV-ECOM-20261104-0001",
    "issuedAt": "2026-11-04T15:43:17.91155879",
    "orderNumber": "ECOM-20261104-0001",
    "orderStatus": "PENDING",
    "customerName": "Demo Customer",
    "customerEmail": "customer@ecom.com",
    "receiverName": "Demo Customer",
    "receiverPhone": "012345678",
    "shippingAddress": "No. 12, Street 271, Toul Kork, Phnom Penh",
    "items": [
      {
        "id": 1,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0
      }
    ],
    "subtotal": 69.0,
    "discountAmount": 6.9,
    "couponCode": "WELCOME10",
    "shippingFee": 15.0,
    "total": 77.1,
    "payment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "KHQR",
      "status": "PENDING",
      "amount": 77.1
    }
  },
  "timestamp": "2026-11-04T15:43:17.912035933"
}
```

### Get tracking
`GET /api/v1/orders/ECOM-20261104-0001/tracking`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "method": "EXPRESS",
    "fee": 15.0,
    "status": "PREPARING"
  },
  "timestamp": "2026-11-04T15:43:17.933274987"
}
```

### Add item for second order
`POST /api/v1/cart/items`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "productId": 1,
  "quantity": 1
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Item added to cart",
  "data": {
    "id": 1,
    "items": [
      {
        "id": 3,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "imageUrl": "https://placehold.co/600x400?text=ASUS+ROG+Gladius+III+Gaming+Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0,
        "stockQuantity": 37
      }
    ],
    "totalItems": 1,
    "subtotal": 69.0
  },
  "timestamp": "2026-11-04T15:43:17.959629589"
}
```

### Checkout - COD (saves codOrderNumber)
`POST /api/v1/orders/checkout`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "addressId": 1,
  "shippingMethod": "STANDARD",
  "paymentMethod": "CASH_ON_DELIVERY"
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Order placed",
  "data": {
    "id": 2,
    "orderNumber": "ECOM-20261104-0002",
    "status": "PENDING",
    "subtotal": 69.0,
    "discountAmount": 0.0,
    "shippingFee": 5.0,
    "total": 74.0,
    "receiverName": "Demo Customer",
    "receiverPhone": "012345678",
    "shippingAddress": "No. 12, Street 271, Toul Kork, Phnom Penh",
    "shippingMethod": "STANDARD",
    "paymentMethod": "CASH_ON_DELIVERY",
    "customerEmail": "customer@ecom.com",
    "items": [
      {
        "id": 2,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0
      }
    ],
    "payment": {
      "id": 2,
      "orderNumber": "ECOM-20261104-0002",
      "method": "CASH_ON_DELIVERY",
      "status": "PENDING",
      "amount": 74.0
    },
    "shipment": {
      "id": 2,
      "orderNumber": "ECOM-20261104-0002",
      "method": "STANDARD",
      "fee": 5.0,
      "status": "PREPARING"
    },
    "createdAt": "2026-11-04T15:43:17.981165636"
  },
  "timestamp": "2026-11-04T15:43:17.987787465"
}
```

### Cancel the COD order
`POST /api/v1/orders/ECOM-20261104-0002/cancel`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "reason": "Ordered by mistake"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Order cancelled",
  "data": {
    "id": 2,
    "orderNumber": "ECOM-20261104-0002",
    "status": "CANCELLED",
    "subtotal": 69.0,
    "discountAmount": 0.0,
    "shippingFee": 5.0,
    "total": 74.0,
    "receiverName": "Demo Customer",
    "receiverPhone": "012345678",
    "shippingAddress": "No. 12, Street 271, Toul Kork, Phnom Penh",
    "shippingMethod": "STANDARD",
    "paymentMethod": "CASH_ON_DELIVERY",
    "cancelledReason": "Ordered by mistake",
    "customerEmail": "customer@ecom.com",
    "items": [
      {
        "id": 2,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0
      }
    ],
    "payment": {
      "id": 2,
      "orderNumber": "ECOM-20261104-0002",
      "method": "CASH_ON_DELIVERY",
      "status": "FAILED",
      "amount": 74.0
    },
    "shipment": {
      "id": 2,
      "orderNumber": "ECOM-20261104-0002",
      "method": "STANDARD",
      "fee": 5.0,
      "status": "PREPARING"
    },
    "createdAt": "2026-11-04T15:43:17.981166"
  },
  "timestamp": "2026-11-04T15:43:18.019052309"
}
```

## 06 Payments

### Generate KHQR (mock or real Bakong, see data.mode)
`POST /api/v1/payments/ECOM-20261104-0001/khqr`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "KHQR generated",
  "data": {
    "orderNumber": "ECOM-20261104-0001",
    "amount": 77.1,
    "currency": "USD",
    "qrString": "MOCK-KHQR|merchant=ECOM|order=ECOM-20261104-0001|amount=77.10|currency=USD|nonce=0bc2356f-7237-464f-a56f-0a7fb74fab44",
    "qrPayload": "MOCK-KHQR|merchant=ECOM|order=ECOM-20261104-0001|amount=77.10|currency=USD|nonce=0bc2356f-7237-464f-a56f-0a7fb74fab44",
    "md5": "ea9e713b89e641e7d11c984060b255bf",
    "expiresAt": "2026-11-04T15:53:18.039323947",
    "mode": "MOCK"
  },
  "timestamp": "2026-11-04T15:43:18.04107867"
}
```

### Payment status (PENDING)
`GET /api/v1/payments/ECOM-20261104-0001/status`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "method": "KHQR",
    "status": "PENDING",
    "amount": 77.1,
    "transactionRef": "KHQR-EA9E713B89E6"
  },
  "timestamp": "2026-11-04T15:43:18.060434305"
}
```

### Gateway callback - PAID (mock mode only; 404 in bakong mode)
`POST /api/v1/payments/callback`  
**Role:** Public

Request body:
```json
{
  "transactionRef": "MOCK-1793779048",
  "orderNumber": "ECOM-20261104-0001",
  "status": "PAID"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Callback processed",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "method": "KHQR",
    "status": "PAID",
    "amount": 77.1,
    "transactionRef": "MOCK-1793781798",
    "paidAt": "2026-11-04T15:43:18.081623912"
  },
  "timestamp": "2026-11-04T15:43:18.085555663"
}
```

### Payment status (PAID)
`GET /api/v1/payments/ECOM-20261104-0001/status`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "method": "KHQR",
    "status": "PAID",
    "amount": 77.1,
    "transactionRef": "MOCK-1793781798",
    "paidAt": "2026-11-04T15:43:18.081624"
  },
  "timestamp": "2026-11-04T15:43:18.103885306"
}
```

### Order is now CONFIRMED
`GET /api/v1/orders/ECOM-20261104-0001`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "status": "CONFIRMED",
    "subtotal": 69.0,
    "discountAmount": 6.9,
    "shippingFee": 15.0,
    "total": 77.1,
    "couponCode": "WELCOME10",
    "receiverName": "Demo Customer",
    "receiverPhone": "012345678",
    "shippingAddress": "No. 12, Street 271, Toul Kork, Phnom Penh",
    "shippingMethod": "EXPRESS",
    "paymentMethod": "KHQR",
    "note": "Please call before delivery",
    "customerEmail": "customer@ecom.com",
    "items": [
      {
        "id": 1,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0
      }
    ],
    "payment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "KHQR",
      "status": "PAID",
      "amount": 77.1,
      "transactionRef": "MOCK-1793781798",
      "paidAt": "2026-11-04T15:43:18.081624"
    },
    "shipment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "EXPRESS",
      "fee": 15.0,
      "status": "PREPARING"
    },
    "createdAt": "2026-11-04T15:43:17.811458"
  },
  "timestamp": "2026-11-04T15:43:18.125299758"
}
```

### Admin: re-check payment with Bakong (400 in mock mode, 200 in bakong mode)
`POST /api/v1/admin/payments/ECOM-20261104-0001/recheck`  
**Role:** ADMIN

Response `400`:
```json
{
  "success": false,
  "message": "Re-checking is only available when payment.khqr.mode=bakong",
  "timestamp": "2026-11-04T15:43:18.143427774"
}
```

## 07 Fulfilment (admin / staff)

### Admin: order -> PROCESSING
`PATCH /api/v1/admin/orders/ECOM-20261104-0001/status`  
**Role:** ADMIN or STAFF

Request body:
```json
{
  "status": "PROCESSING"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Order status updated",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "status": "PROCESSING",
    "subtotal": 69.0,
    "discountAmount": 6.9,
    "shippingFee": 15.0,
    "total": 77.1,
    "couponCode": "WELCOME10",
    "receiverName": "Demo Customer",
    "receiverPhone": "012345678",
    "shippingAddress": "No. 12, Street 271, Toul Kork, Phnom Penh",
    "shippingMethod": "EXPRESS",
    "paymentMethod": "KHQR",
    "note": "Please call before delivery",
    "customerEmail": "customer@ecom.com",
    "items": [
      {
        "id": 1,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0
      }
    ],
    "payment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "KHQR",
      "status": "PAID",
      "amount": 77.1,
      "transactionRef": "MOCK-1793781798",
      "paidAt": "2026-11-04T15:43:18.081624"
    },
    "shipment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "EXPRESS",
      "fee": 15.0,
      "status": "PREPARING"
    },
    "createdAt": "2026-11-04T15:43:17.811458"
  },
  "timestamp": "2026-11-04T15:43:18.170203173"
}
```

### Admin: ship with tracking number
`PATCH /api/v1/admin/orders/ECOM-20261104-0001/ship`  
**Role:** ADMIN or STAFF

Request body:
```json
{
  "trackingNumber": "KH-TRK-1793779048"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Order shipped",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "status": "SHIPPED",
    "subtotal": 69.0,
    "discountAmount": 6.9,
    "shippingFee": 15.0,
    "total": 77.1,
    "couponCode": "WELCOME10",
    "receiverName": "Demo Customer",
    "receiverPhone": "012345678",
    "shippingAddress": "No. 12, Street 271, Toul Kork, Phnom Penh",
    "shippingMethod": "EXPRESS",
    "paymentMethod": "KHQR",
    "note": "Please call before delivery",
    "customerEmail": "customer@ecom.com",
    "items": [
      {
        "id": 1,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0
      }
    ],
    "payment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "KHQR",
      "status": "PAID",
      "amount": 77.1,
      "transactionRef": "MOCK-1793781798",
      "paidAt": "2026-11-04T15:43:18.081624"
    },
    "shipment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "EXPRESS",
      "fee": 15.0,
      "trackingNumber": "KH-TRK-1793781798",
      "status": "IN_TRANSIT",
      "shippedAt": "2026-11-04T15:43:18.19197837"
    },
    "createdAt": "2026-11-04T15:43:17.811458"
  },
  "timestamp": "2026-11-04T15:43:18.196821715"
}
```

### Admin: shipment -> OUT_FOR_DELIVERY
`PATCH /api/v1/admin/shipments/1/status`  
**Role:** ADMIN or STAFF

Request body:
```json
{
  "status": "OUT_FOR_DELIVERY"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Shipment updated",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "method": "EXPRESS",
    "fee": 15.0,
    "trackingNumber": "KH-TRK-1793781798",
    "status": "OUT_FOR_DELIVERY",
    "shippedAt": "2026-11-04T15:43:18.191978"
  },
  "timestamp": "2026-11-04T15:43:18.219338216"
}
```

### Admin: shipment -> DELIVERED (order DELIVERED)
`PATCH /api/v1/admin/shipments/1/status`  
**Role:** ADMIN or STAFF

Request body:
```json
{
  "status": "DELIVERED"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Shipment updated",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "method": "EXPRESS",
    "fee": 15.0,
    "trackingNumber": "KH-TRK-1793781798",
    "status": "DELIVERED",
    "shippedAt": "2026-11-04T15:43:18.191978",
    "deliveredAt": "2026-11-04T15:43:18.238180179"
  },
  "timestamp": "2026-11-04T15:43:18.243119138"
}
```

### Customer: tracking after delivery
`GET /api/v1/orders/ECOM-20261104-0001/tracking`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "method": "EXPRESS",
    "fee": 15.0,
    "trackingNumber": "KH-TRK-1793781798",
    "status": "DELIVERED",
    "shippedAt": "2026-11-04T15:43:18.191978",
    "deliveredAt": "2026-11-04T15:43:18.23818"
  },
  "timestamp": "2026-11-04T15:43:18.262485857"
}
```

## 08 Reviews

### Create review (delivered purchase, saves reviewId)
`POST /api/v1/products/1/reviews`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "rating": 5,
  "comment": "Excellent laptop, fast delivery!"
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Review submitted",
  "data": {
    "id": 1,
    "productId": 29,
    "productName": "ASUS ROG Gladius III Gaming Mouse",
    "userId": 3,
    "userName": "Demo Customer",
    "rating": 5,
    "comment": "Excellent laptop, fast delivery!",
    "verifiedPurchase": true,
    "visible": true,
    "createdAt": "2026-11-04T15:43:18.287306999"
  },
  "timestamp": "2026-11-04T15:43:18.29412182"
}
```

### List product reviews (public)
`GET /api/v1/products/1/reviews?page=0&size=10`  
**Role:** Public

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 1,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "userId": 3,
        "userName": "Demo Customer",
        "rating": 5,
        "comment": "Excellent laptop, fast delivery!",
        "verifiedPurchase": true,
        "visible": true,
        "createdAt": "2026-11-04T15:43:18.287307"
      }
    ],
    "page": 0,
    "size": 10,
    "totalElements": 1,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-11-04T15:43:18.313342486"
}
```

### Update my review
`PUT /api/v1/reviews/1`  
**Role:** Authenticated (CUSTOMER)

Request body:
```json
{
  "rating": 4,
  "comment": "Great, minor scratch on the lid"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Review updated",
  "data": {
    "id": 1,
    "productId": 29,
    "productName": "ASUS ROG Gladius III Gaming Mouse",
    "userId": 3,
    "userName": "Demo Customer",
    "rating": 4,
    "comment": "Great, minor scratch on the lid",
    "verifiedPurchase": true,
    "visible": true,
    "createdAt": "2026-11-04T15:43:18.287307"
  },
  "timestamp": "2026-11-04T15:43:18.342879914"
}
```

### Product shows updated rating
`GET /api/v1/products/1`  
**Role:** Public

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 29,
    "sku": "ACC-ASUS-GLADIUS3",
    "name": "ASUS ROG Gladius III Gaming Mouse",
    "slug": "asus-rog-gladius-iii-gaming-mouse",
    "description": "Lightweight wired gaming mouse with a 26,000 DPI sensor.",
    "price": 69.0,
    "category": {
      "id": 5,
      "name": "Accessory",
      "slug": "accessory",
      "description": "Mice, keyboards, docks and other accessories"
    },
    "brand": {
      "id": 4,
      "name": "ASUS",
      "slug": "asus"
    },
    "warrantyMonths": 24,
    "stockQuantity": 37,
    "lowStockThreshold": 5,
    "active": true,
    "averageRating": 4.0,
    "reviewCount": 1,
    "soldCount": 30,
    "images": [
      "https://placehold.co/600x400?text=ASUS+ROG+Gladius+III+Gaming+Mouse"
    ],
    "createdAt": "2026-11-04T15:43:04.15972"
  },
  "timestamp": "2026-11-04T15:43:18.361868202"
}
```

## 09 Notifications

### List notifications (saves notificationId)
`GET /api/v1/notifications?page=0&size=20`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 7,
        "type": "PUSH",
        "title": "Order delivered",
        "message": "Your order ECOM-20261104-0001 has been delivered. Leave a review for your purchase!",
        "read": false,
        "createdAt": "2026-11-04T15:43:18.239598",
        "priority": "NORMAL"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 6,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-11-04T15:43:18.383427229"
}
```

### Unread count
`GET /api/v1/notifications/unread-count`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": 6,
  "timestamp": "2026-11-04T15:43:18.403504809"
}
```

### Mark one as read
`PATCH /api/v1/notifications/1/read`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 7,
    "type": "PUSH",
    "title": "Order delivered",
    "message": "Your order ECOM-20261104-0001 has been delivered. Leave a review for your purchase!",
    "read": true,
    "createdAt": "2026-11-04T15:43:18.239598",
    "priority": "NORMAL"
  },
  "timestamp": "2026-11-04T15:43:18.424081235"
}
```

### Mark all as read
`PATCH /api/v1/notifications/read-all`  
**Role:** Authenticated (CUSTOMER)

Response `200`:
```json
{
  "success": true,
  "message": "All notifications marked as read",
  "data": 5,
  "timestamp": "2026-11-04T15:43:18.44150971"
}
```

## 10 Admin - Users

### List/search users
`GET /api/v1/admin/users?keyword=postman&page=0&size=20`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 4,
        "fullName": "Postman User",
        "email": "postman1793781796480@test.com",
        "phone": "012345678",
        "role": "CUSTOMER",
        "enabled": true,
        "createdAt": "2026-11-04T15:43:16.607548"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-11-04T15:43:18.462248668"
}
```

### Change role of registered user
`PATCH /api/v1/admin/users/1/role`  
**Role:** ADMIN

Request body:
```json
{
  "role": "STAFF"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Role updated",
  "data": {
    "id": 4,
    "fullName": "Postman User",
    "email": "postman1793781796480@test.com",
    "phone": "012345678",
    "role": "STAFF",
    "enabled": true,
    "createdAt": "2026-11-04T15:43:16.607548"
  },
  "timestamp": "2026-11-04T15:43:18.482226438"
}
```

### Change role back to CUSTOMER
`PATCH /api/v1/admin/users/1/role`  
**Role:** ADMIN

Request body:
```json
{
  "role": "CUSTOMER"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Role updated",
  "data": {
    "id": 4,
    "fullName": "Postman User",
    "email": "postman1793781796480@test.com",
    "phone": "012345678",
    "role": "CUSTOMER",
    "enabled": true,
    "createdAt": "2026-11-04T15:43:16.607548"
  },
  "timestamp": "2026-11-04T15:43:18.499425216"
}
```

### Disable account
`PATCH /api/v1/admin/users/1/enabled`  
**Role:** ADMIN

Request body:
```json
{
  "enabled": false
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Account updated",
  "data": {
    "id": 4,
    "fullName": "Postman User",
    "email": "postman1793781796480@test.com",
    "phone": "012345678",
    "role": "CUSTOMER",
    "enabled": false,
    "createdAt": "2026-11-04T15:43:16.607548"
  },
  "timestamp": "2026-11-04T15:43:18.519154989"
}
```

### Enable account
`PATCH /api/v1/admin/users/1/enabled`  
**Role:** ADMIN

Request body:
```json
{
  "enabled": true
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Account updated",
  "data": {
    "id": 4,
    "fullName": "Postman User",
    "email": "postman1793781796480@test.com",
    "phone": "012345678",
    "role": "CUSTOMER",
    "enabled": true,
    "createdAt": "2026-11-04T15:43:16.607548"
  },
  "timestamp": "2026-11-04T15:43:18.536458222"
}
```

## 11 Admin - Catalog

### List products (incl. inactive)
`GET /api/v1/admin/products?page=0&size=20`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 29,
        "sku": "ACC-ASUS-GLADIUS3",
        "name": "ASUS ROG Gladius III Gaming Mouse",
        "slug": "asus-rog-gladius-iii-gaming-mouse",
        "description": "Lightweight wired gaming mouse with a 26,000 DPI sensor.",
        "price": 69.0,
        "category": {
          "id": 5,
          "name": "Accessory",
          "slug": "accessory",
          "description": "Mice, keyboards, docks and other accessories"
        },
        "brand": {
          "id": 4,
          "name": "ASUS",
          "slug": "asus"
        },
        "warrantyMonths": 24,
        "stockQuantity": 37,
        "lowStockThreshold": 5,
        "active": true,
        "averageRating": 4.0,
        "reviewCount": 1,
        "soldCount": 30,
        "images": [
          "https://placehold.co/600x400?text=ASUS+ROG+Gladius+III+Gaming+Mouse"
        ],
        "createdAt": "2026-11-04T15:43:04.15972"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 29,
    "totalPages": 2,
    "last": false
  },
  "timestamp": "2026-11-04T15:43:18.558665683"
}
```

### Create product (saves newProductId)
`POST /api/v1/admin/products`  
**Role:** ADMIN

Request body:
```json
{
  "sku": "LAP-NEW-001",
  "name": "Postman Test Laptop",
  "description": "Created from the Postman collection",
  "price": 999.99,
  "categoryId": 1,
  "brandId": 1,
  "cpu": "Intel Core i7",
  "ram": 16,
  "storage": "512GB SSD",
  "gpu": "Intel Iris Xe",
  "screenSize": 14.0,
  "os": "Windows 11",
  "warrantyMonths": 12,
  "stockQuantity": 10,
  "lowStockThreshold": 3,
  "active": true,
  "imageUrls": [
    "https://placehold.co/600x400?text=Postman"
  ]
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Product created",
  "data": {
    "id": 30,
    "sku": "PM-1793781798571",
    "name": "Postman Test Laptop",
    "slug": "postman-test-laptop",
    "description": "Created from the Postman collection",
    "price": 999.99,
    "category": {
      "id": 5,
      "name": "Accessory",
      "slug": "accessory",
      "description": "Mice, keyboards, docks and other accessories"
    },
    "brand": {
      "id": 4,
      "name": "ASUS",
      "slug": "asus"
    },
    "cpu": "Intel Core i7",
    "ram": 16,
    "storage": "512GB SSD",
    "gpu": "Intel Iris Xe",
    "screenSize": 14.0,
    "os": "Windows 11",
    "warrantyMonths": 12,
    "stockQuantity": 10,
    "lowStockThreshold": 3,
    "active": true,
    "averageRating": 0.0,
    "reviewCount": 0,
    "soldCount": 0,
    "images": [
      "https://placehold.co/600x400?text=Postman"
    ],
    "createdAt": "2026-11-04T15:43:18.598609199"
  },
  "timestamp": "2026-11-04T15:43:18.604142125"
}
```

### Get product (admin)
`GET /api/v1/admin/products/1`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 30,
    "sku": "PM-1793781798571",
    "name": "Postman Test Laptop",
    "slug": "postman-test-laptop",
    "description": "Created from the Postman collection",
    "price": 999.99,
    "category": {
      "id": 5,
      "name": "Accessory",
      "slug": "accessory",
      "description": "Mice, keyboards, docks and other accessories"
    },
    "brand": {
      "id": 4,
      "name": "ASUS",
      "slug": "asus"
    },
    "cpu": "Intel Core i7",
    "ram": 16,
    "storage": "512GB SSD",
    "gpu": "Intel Iris Xe",
    "screenSize": 14.0,
    "os": "Windows 11",
    "warrantyMonths": 12,
    "stockQuantity": 10,
    "lowStockThreshold": 3,
    "active": true,
    "averageRating": 0.0,
    "reviewCount": 0,
    "soldCount": 0,
    "images": [
      "https://placehold.co/600x400?text=Postman"
    ],
    "createdAt": "2026-11-04T15:43:18.598609"
  },
  "timestamp": "2026-11-04T15:43:18.622072002"
}
```

### Update product
`PUT /api/v1/admin/products/1`  
**Role:** ADMIN

Request body:
```json
{
  "sku": "LAP-NEW-001",
  "name": "Postman Test Laptop (updated)",
  "description": "Created from the Postman collection",
  "price": 899.99,
  "categoryId": 1,
  "brandId": 1,
  "cpu": "Intel Core i7",
  "ram": 16,
  "storage": "512GB SSD",
  "gpu": "Intel Iris Xe",
  "screenSize": 14.0,
  "os": "Windows 11",
  "warrantyMonths": 12,
  "stockQuantity": 12,
  "lowStockThreshold": 3,
  "active": true,
  "imageUrls": [
    "https://placehold.co/600x400?text=Postman"
  ]
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Product updated",
  "data": {
    "id": 30,
    "sku": "PM-1793781798571",
    "name": "Postman Test Laptop (updated)",
    "slug": "postman-test-laptop-updated",
    "description": "Created from the Postman collection",
    "price": 899.99,
    "category": {
      "id": 5,
      "name": "Accessory",
      "slug": "accessory",
      "description": "Mice, keyboards, docks and other accessories"
    },
    "brand": {
      "id": 4,
      "name": "ASUS",
      "slug": "asus"
    },
    "cpu": "Intel Core i7",
    "ram": 16,
    "storage": "512GB SSD",
    "gpu": "Intel Iris Xe",
    "screenSize": 14.0,
    "os": "Windows 11",
    "warrantyMonths": 12,
    "stockQuantity": 12,
    "lowStockThreshold": 3,
    "active": true,
    "averageRating": 0.0,
    "reviewCount": 0,
    "soldCount": 0,
    "images": [
      "https://placehold.co/600x400?text=Postman"
    ],
    "createdAt": "2026-11-04T15:43:18.598609"
  },
  "timestamp": "2026-11-04T15:43:18.649439703"
}
```

### Deactivate product
`PATCH /api/v1/admin/products/1/active?value=false`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Product updated",
  "data": {
    "id": 30,
    "sku": "PM-1793781798571",
    "name": "Postman Test Laptop (updated)",
    "slug": "postman-test-laptop-updated",
    "description": "Created from the Postman collection",
    "price": 899.99,
    "category": {
      "id": 5,
      "name": "Accessory",
      "slug": "accessory",
      "description": "Mice, keyboards, docks and other accessories"
    },
    "brand": {
      "id": 4,
      "name": "ASUS",
      "slug": "asus"
    },
    "cpu": "Intel Core i7",
    "ram": 16,
    "storage": "512GB SSD",
    "gpu": "Intel Iris Xe",
    "screenSize": 14.0,
    "os": "Windows 11",
    "warrantyMonths": 12,
    "stockQuantity": 12,
    "lowStockThreshold": 3,
    "active": false,
    "averageRating": 0.0,
    "reviewCount": 0,
    "soldCount": 0,
    "images": [
      "https://placehold.co/600x400?text=Postman"
    ],
    "createdAt": "2026-11-04T15:43:18.598609"
  },
  "timestamp": "2026-11-04T15:43:18.672397491"
}
```

### Activate product
`PATCH /api/v1/admin/products/1/active?value=true`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Product updated",
  "data": {
    "id": 30,
    "sku": "PM-1793781798571",
    "name": "Postman Test Laptop (updated)",
    "slug": "postman-test-laptop-updated",
    "description": "Created from the Postman collection",
    "price": 899.99,
    "category": {
      "id": 5,
      "name": "Accessory",
      "slug": "accessory",
      "description": "Mice, keyboards, docks and other accessories"
    },
    "brand": {
      "id": 4,
      "name": "ASUS",
      "slug": "asus"
    },
    "cpu": "Intel Core i7",
    "ram": 16,
    "storage": "512GB SSD",
    "gpu": "Intel Iris Xe",
    "screenSize": 14.0,
    "os": "Windows 11",
    "warrantyMonths": 12,
    "stockQuantity": 12,
    "lowStockThreshold": 3,
    "active": true,
    "averageRating": 0.0,
    "reviewCount": 0,
    "soldCount": 0,
    "images": [
      "https://placehold.co/600x400?text=Postman"
    ],
    "createdAt": "2026-11-04T15:43:18.598609"
  },
  "timestamp": "2026-11-04T15:43:18.69303229"
}
```

### Delete product
`DELETE /api/v1/admin/products/1`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Product deleted",
  "timestamp": "2026-11-04T15:43:18.719931671"
}
```

### Create category (saves newCategoryId)
`POST /api/v1/admin/categories`  
**Role:** ADMIN

Request body:
```json
{
  "name": "Cat 1793779048",
  "description": "Temp"
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Category created",
  "data": {
    "id": 6,
    "name": "Cat 1793781799",
    "slug": "cat-1793781799",
    "description": "Temp"
  },
  "timestamp": "2026-11-04T15:43:18.741621124"
}
```

### Update category
`PUT /api/v1/admin/categories/1`  
**Role:** ADMIN

Request body:
```json
{
  "name": "Cat renamed 1793779048",
  "description": "Temp 2"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Category updated",
  "data": {
    "id": 6,
    "name": "Cat renamed 1793781799",
    "slug": "cat-renamed-1793781799",
    "description": "Temp 2"
  },
  "timestamp": "2026-11-04T15:43:18.760009944"
}
```

### Delete category
`DELETE /api/v1/admin/categories/1`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Category deleted",
  "timestamp": "2026-11-04T15:43:18.780746234"
}
```

### Create brand (saves newBrandId)
`POST /api/v1/admin/brands`  
**Role:** ADMIN

Request body:
```json
{
  "name": "Brand 1793779048"
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Brand created",
  "data": {
    "id": 10,
    "name": "Brand 1793781799",
    "slug": "brand-1793781799"
  },
  "timestamp": "2026-11-04T15:43:18.802220047"
}
```

### Update brand
`PUT /api/v1/admin/brands/1`  
**Role:** ADMIN

Request body:
```json
{
  "name": "Brand renamed 1793779048"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Brand updated",
  "data": {
    "id": 10,
    "name": "Brand renamed 1793781799",
    "slug": "brand-renamed-1793781799"
  },
  "timestamp": "2026-11-04T15:43:18.820676748"
}
```

### Delete brand
`DELETE /api/v1/admin/brands/1`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Brand deleted",
  "timestamp": "2026-11-04T15:43:18.838318621"
}
```

## 12 Admin - Orders & Payments

### List orders (filters)
`GET /api/v1/admin/orders?status=DELIVERED&keyword=ECOM&page=0&size=20`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 1,
        "orderNumber": "ECOM-20261104-0001",
        "status": "DELIVERED",
        "subtotal": 69.0,
        "discountAmount": 6.9,
        "shippingFee": 15.0,
        "total": 77.1,
        "couponCode": "WELCOME10",
        "receiverName": "Demo Customer",
        "receiverPhone": "012345678",
        "shippingAddress": "No. 12, Street 271, Toul Kork, Phnom Penh",
        "shippingMethod": "EXPRESS",
        "paymentMethod": "KHQR",
        "note": "Please call before delivery",
        "customerEmail": "customer@ecom.com",
        "items": [
          {
            "id": 1,
            "productId": 29,
            "productName": "ASUS ROG Gladius III Gaming Mouse",
            "unitPrice": 69.0,
            "quantity": 1,
            "lineTotal": 69.0
          }
        ],
        "payment": {
          "id": 1,
          "orderNumber": "ECOM-20261104-0001",
          "method": "KHQR",
          "status": "PAID",
          "amount": 77.1,
          "transactionRef": "MOCK-1793781798",
          "paidAt": "2026-11-04T15:43:18.081624"
        },
        "shipment": {
          "id": 1,
          "orderNumber": "ECOM-20261104-0001",
          "method": "EXPRESS",
          "fee": 15.0,
          "trackingNumber": "KH-TRK-1793781798",
          "status": "DELIVERED",
          "shippedAt": "2026-11-04T15:43:18.191978",
          "deliveredAt": "2026-11-04T15:43:18.23818"
        },
        "createdAt": "2026-11-04T15:43:17.811458"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-11-04T15:43:18.86199694"
}
```

### Get order detail
`GET /api/v1/admin/orders/ECOM-20261104-0001`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "status": "DELIVERED",
    "subtotal": 69.0,
    "discountAmount": 6.9,
    "shippingFee": 15.0,
    "total": 77.1,
    "couponCode": "WELCOME10",
    "receiverName": "Demo Customer",
    "receiverPhone": "012345678",
    "shippingAddress": "No. 12, Street 271, Toul Kork, Phnom Penh",
    "shippingMethod": "EXPRESS",
    "paymentMethod": "KHQR",
    "note": "Please call before delivery",
    "customerEmail": "customer@ecom.com",
    "items": [
      {
        "id": 1,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "unitPrice": 69.0,
        "quantity": 1,
        "lineTotal": 69.0
      }
    ],
    "payment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "KHQR",
      "status": "PAID",
      "amount": 77.1,
      "transactionRef": "MOCK-1793781798",
      "paidAt": "2026-11-04T15:43:18.081624"
    },
    "shipment": {
      "id": 1,
      "orderNumber": "ECOM-20261104-0001",
      "method": "EXPRESS",
      "fee": 15.0,
      "trackingNumber": "KH-TRK-1793781798",
      "status": "DELIVERED",
      "shippedAt": "2026-11-04T15:43:18.191978",
      "deliveredAt": "2026-11-04T15:43:18.23818"
    },
    "createdAt": "2026-11-04T15:43:17.811458"
  },
  "timestamp": "2026-11-04T15:43:18.88083386"
}
```

### List payments
`GET /api/v1/admin/payments?status=PAID&page=0&size=20`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 1,
        "orderNumber": "ECOM-20261104-0001",
        "method": "KHQR",
        "status": "PAID",
        "amount": 77.1,
        "transactionRef": "MOCK-1793781798",
        "paidAt": "2026-11-04T15:43:18.081624"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-11-04T15:43:18.900938009"
}
```

### Refund payment
`POST /api/v1/admin/payments/{idOrOrderNumber}/refund` - the path takes the payment id (`/admin/payments/1/refund`) **or** the order number (`/admin/payments/ECOM-20261104-0001/refund`).  
**Role:** ADMIN. Works for payments in `PAID` or `PAID_AFTER_CANCEL`; any other status -> `400`, unknown payment/order -> `404`.

Response `200`:
```json
{
  "success": true,
  "message": "Payment refunded",
  "data": {
    "id": 1,
    "orderNumber": "ECOM-20261104-0001",
    "method": "KHQR",
    "status": "REFUNDED",
    "amount": 77.1,
    "transactionRef": "MOCK-1793781798",
    "paidAt": "2026-11-04T15:43:18.081624"
  },
  "timestamp": "2026-11-04T15:43:18.920989454"
}
```

### List late payments needing action (status=PAID_AFTER_CANCEL)
`GET /api/v1/admin/payments?status=PAID_AFTER_CANCEL&page=0&size=20` - the existing `status` filter accepts the new value.  
**Role:** ADMIN. (Example written from the integration tests: late payments exist only in bakong mode.)

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 12,
        "orderNumber": "ECOM-20261104-0029",
        "method": "KHQR",
        "status": "PAID_AFTER_CANCEL",
        "amount": 105.0,
        "transactionRef": "late-3f9a1c",
        "paidAt": "2026-11-04T20:44:01",
        "failureReason": "Paid after auto-cancel"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-11-04T20:45:00.123456789"
}
```

The matching admin notification (`GET /notifications`):
```json
{ "id": 31, "type": "EMAIL", "title": "Customer paid after cancel - refund or restore order",
  "message": "Order ECOM-20261104-0029 was auto-cancelled, but the customer paid $105.00 afterwards (Bakong hash 9c1e...). Restore the order (POST /admin/orders/ECOM-20261104-0029/restore-after-payment) or refund it (POST /admin/payments/ECOM-20261104-0029/refund).",
  "read": false, "createdAt": "2026-11-04T20:44:02.5", "priority": "HIGH" }
```

### Restore order after late payment
`POST /api/v1/admin/orders/ECOM-20261104-0029/restore-after-payment` (no body)  
**Role:** ADMIN, STAFF. Re-checks stock and re-reserves every item (inventory log `ORDER`, note "restored after late payment"), sets the order `CONFIRMED` (cancel reason cleared) and the payment `PAID`, and notifies the customer ("Order restored"). All-or-nothing.

| Status | When |
|---|---|
| `200` | restored; `data` is the order (`status: "CONFIRMED"`, `payment.status: "PAID"`) |
| `400` | order is not `CANCELLED` or its payment is not `PAID_AFTER_CANCEL` (e.g. already restored, refunded, or an ordinary cancel) |
| `404` | unknown order number |
| `409` | not enough stock for at least one item - nothing was changed, the order stays `CANCELLED`/`PAID_AFTER_CANCEL`; the admin should refund |

Response `200` (shape = order detail, see "Get order detail"):
```json
{ "success": true, "message": "Order restored",
  "data": { "orderNumber": "ECOM-20261104-0029", "status": "CONFIRMED",
            "payment": { "id": 12, "method": "KHQR", "status": "PAID", "amount": 105.0, "paidAt": "2026-11-04T20:44:01" } } }
```
Response `409`:
```json
{ "success": false, "message": "Insufficient stock for Late Laptop: available 0, requested 1", "timestamp": "2026-11-04T20:46:10" }
```
Then refund manually: `POST /api/v1/admin/payments/ECOM-20261104-0029/refund` -> `200`, `data.status: "REFUNDED"`.


## 13 Admin - Coupons

### List coupons
`GET /api/v1/admin/coupons?page=0&size=20`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 3,
        "code": "EXPIRED",
        "discountType": "PERCENT",
        "value": 20.0,
        "usedCount": 0,
        "startAt": "2020-01-01T00:00:00",
        "endAt": "2020-12-31T23:59:59",
        "active": true
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 3,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-11-04T15:43:18.939029504"
}
```

### Create coupon (saves couponId)
`POST /api/v1/admin/coupons`  
**Role:** ADMIN

Request body:
```json
{
  "code": "PM1793779048",
  "discountType": "PERCENT",
  "value": 15,
  "minOrderAmount": 100,
  "maxUses": 50,
  "startAt": "2026-01-01T00:00:00",
  "endAt": "2030-12-31T23:59:59",
  "active": true
}
```

Response `201`:
```json
{
  "success": true,
  "message": "Coupon created",
  "data": {
    "id": 4,
    "code": "PM1793781799",
    "discountType": "PERCENT",
    "value": 15.0,
    "minOrderAmount": 100.0,
    "maxUses": 50,
    "usedCount": 0,
    "startAt": "2026-01-01T00:00:00",
    "endAt": "2030-12-31T23:59:59",
    "active": true
  },
  "timestamp": "2026-11-04T15:43:18.966244958"
}
```

### Update coupon
`PUT /api/v1/admin/coupons/1`  
**Role:** ADMIN

Request body:
```json
{
  "code": "PMUPD1793779048",
  "discountType": "FIXED",
  "value": 25,
  "minOrderAmount": 200,
  "maxUses": 10,
  "active": true
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Coupon updated",
  "data": {
    "id": 4,
    "code": "PMUPD1793781799",
    "discountType": "FIXED",
    "value": 25.0,
    "minOrderAmount": 200.0,
    "maxUses": 10,
    "usedCount": 0,
    "active": true
  },
  "timestamp": "2026-11-04T15:43:18.987059054"
}
```

### Delete coupon
`DELETE /api/v1/admin/coupons/1`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Coupon deleted",
  "timestamp": "2026-11-04T15:43:19.004519133"
}
```

## 14 Admin - Inventory

### Inventory list
`GET /api/v1/admin/inventory?page=0&size=20`  
**Role:** ADMIN or STAFF

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "productId": 19,
        "sku": "MON-ASUS-PA278QV",
        "name": "ASUS ProArt PA278QV 27 Monitor",
        "stockQuantity": 16,
        "lowStockThreshold": 5,
        "category": "Monitor",
        "lowStock": false
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 29,
    "totalPages": 2,
    "last": false
  },
  "timestamp": "2026-11-04T15:43:19.026089249"
}
```

### Low-stock list
`GET /api/v1/admin/inventory/low-stock`  
**Role:** ADMIN or STAFF

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "productId": 24,
      "sku": "CMP-ASUS-B650A",
      "name": "ASUS ROG Strix B650-A Gaming WiFi",
      "stockQuantity": 2,
      "lowStockThreshold": 5,
      "category": "Component",
      "lowStock": true
    }
  ],
  "timestamp": "2026-11-04T15:43:19.044778667"
}
```

### Restock product
`POST /api/v1/admin/inventory/1/restock`  
**Role:** ADMIN or STAFF

Request body:
```json
{
  "quantity": 10,
  "note": "Supplier delivery PO-1001"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Stock added",
  "data": {
    "productId": 29,
    "sku": "ACC-ASUS-GLADIUS3",
    "name": "ASUS ROG Gladius III Gaming Mouse",
    "stockQuantity": 47,
    "lowStockThreshold": 5,
    "category": "Accessory",
    "lowStock": false
  },
  "timestamp": "2026-11-04T15:43:19.066673206"
}
```

### Adjust stock (delta)
`POST /api/v1/admin/inventory/1/adjust`  
**Role:** ADMIN or STAFF

Request body:
```json
{
  "delta": -1,
  "note": "Damaged unit"
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Stock adjusted",
  "data": {
    "productId": 29,
    "sku": "ACC-ASUS-GLADIUS3",
    "name": "ASUS ROG Gladius III Gaming Mouse",
    "stockQuantity": 46,
    "lowStockThreshold": 5,
    "category": "Accessory",
    "lowStock": false
  },
  "timestamp": "2026-11-04T15:43:19.086701684"
}
```

### Inventory logs
`GET /api/v1/admin/inventory/1/logs?page=0&size=20`  
**Role:** ADMIN or STAFF

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 7,
        "productId": 29,
        "changeQuantity": -1,
        "reason": "ADJUST",
        "stockAfter": 46,
        "createdBy": 2,
        "note": "Damaged unit",
        "createdAt": "2026-11-04T15:43:19.084725"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 5,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-11-04T15:43:19.105664933"
}
```

## 15 Admin - Reviews

### List all reviews
`GET /api/v1/admin/reviews?page=0&size=20`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "content": [
      {
        "id": 1,
        "productId": 29,
        "productName": "ASUS ROG Gladius III Gaming Mouse",
        "userId": 3,
        "userName": "Demo Customer",
        "rating": 4,
        "comment": "Great, minor scratch on the lid",
        "verifiedPurchase": true,
        "visible": true,
        "createdAt": "2026-11-04T15:43:18.287307"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-11-04T15:43:19.125986472"
}
```

### Hide review
`PATCH /api/v1/admin/reviews/1/visibility`  
**Role:** ADMIN

Request body:
```json
{
  "visible": false
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Review updated",
  "data": {
    "id": 1,
    "productId": 29,
    "productName": "ASUS ROG Gladius III Gaming Mouse",
    "userId": 3,
    "userName": "Demo Customer",
    "rating": 4,
    "comment": "Great, minor scratch on the lid",
    "verifiedPurchase": true,
    "visible": false,
    "createdAt": "2026-11-04T15:43:18.287307"
  },
  "timestamp": "2026-11-04T15:43:19.146861732"
}
```

### Show review
`PATCH /api/v1/admin/reviews/1/visibility`  
**Role:** ADMIN

Request body:
```json
{
  "visible": true
}
```

Response `200`:
```json
{
  "success": true,
  "message": "Review updated",
  "data": {
    "id": 1,
    "productId": 29,
    "productName": "ASUS ROG Gladius III Gaming Mouse",
    "userId": 3,
    "userName": "Demo Customer",
    "rating": 4,
    "comment": "Great, minor scratch on the lid",
    "verifiedPurchase": true,
    "visible": true,
    "createdAt": "2026-11-04T15:43:18.287307"
  },
  "timestamp": "2026-11-04T15:43:19.166220501"
}
```

### Delete review
`DELETE /api/v1/admin/reviews/1`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Review deleted",
  "timestamp": "2026-11-04T15:43:19.184755689"
}
```

## 16 Admin - Reports & Uploads

### Dashboard
`GET /api/v1/admin/reports/dashboard`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "totalSales": 77.1,
    "totalOrders": 2,
    "ordersByStatus": {
      "PENDING": 0,
      "CONFIRMED": 0,
      "PROCESSING": 0,
      "SHIPPED": 0,
      "DELIVERED": 1,
      "CANCELLED": 1
    },
    "totalCustomers": 2,
    "topProducts": [
      {
        "productId": 29,
        "name": "ASUS ROG Gladius III Gaming Mouse",
        "quantitySold": 1
      }
    ],
    "lowStockCount": 3
  },
  "timestamp": "2026-11-04T15:43:19.206484004"
}
```

### Sales report
`GET /api/v1/admin/reports/sales?from=2026-01-01&to=2026-12-31`  
**Role:** ADMIN

Response `200`:
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "date": "2026-01-01",
      "orders": 0,
      "revenue": 0.0
    }
  ],
  "timestamp": "2026-11-04T15:43:19.229259248"
}
```

### Upload image (sample.png from the postman folder)
`POST /api/v1/admin/uploads`  
**Role:** ADMIN

Request body: `multipart/form-data` with a `file` part (JPEG, PNG, WEBP or GIF, max 5 MB).

Response `201`:
```json
{
  "success": true,
  "message": "File uploaded",
  "data": {
    "filename": "147f15d4-aee5-4365-9ce9-4dfb3316c221.png",
    "url": "/uploads/147f15d4-aee5-4365-9ce9-4dfb3316c221.png",
    "size": 69
  },
  "timestamp": "2026-11-04T15:43:19.262664037"
}
```
