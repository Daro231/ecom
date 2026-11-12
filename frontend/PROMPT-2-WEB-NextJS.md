# PROMPT 2 — WEB FRONTEND (Next.js) — FINAL VERSION

> Open a NEW agent session inside `bonin/frontend` (with `API_CONTRACT.md` copied in) and paste everything below the line.
> Backend must already be running on http://localhost:8080 (KHQR_MODE=mock, Postgres in Docker on port 5435).

---

You are a senior frontend engineer. Build the web application for **"ecom"**, an online store that **sells computers** (laptops, desktops, monitors, components, accessories). The Spring Boot backend is finished, tested and **frozen**. Its contract is in `./API_CONTRACT.md` (generated from real responses) and Swagger JSON is at `http://localhost:8080/v3/api-docs`. **Do not invent endpoints or fields — use the contract exactly.** If something is missing, list it at the end instead of faking it. A Flutter customer app already uses the same API; the web must behave the same way.

The app has two parts: **Customer Store** and **Admin Panel** (ADMIN and STAFF roles). The Admin Panel exists ONLY on the web, so it is the most important part.

## 0. Environment rules (very important)
- The backend is already running on `http://localhost:8080`. **Do NOT start, stop, restart or modify the backend. Do NOT stop or touch the postgres Docker container. Do NOT create database roles.** If the backend does not answer, stop and tell me.
- Before any test, check the backend with `curl -s http://localhost:8080/api/v1/categories`.
- Run the Next.js dev server on **port 3000** (backend CORS allows it).
- Seed accounts: `admin@ecom.com / Admin@123` (ADMIN), `staff@ecom.com / Staff@123` (STAFF), `customer@ecom.com / Customer@123` (CUSTOMER).

## 1. Backend facts you must respect
- Response envelope: `ApiResponse { success, message, data, errors, timestamp }`; lists use `PageResponse { content, page, size, totalElements, totalPages, last }`.
- **Null fields are omitted from JSON** — treat every optional field as possibly missing (not `null`).
- Enums (display with proper labels, never raw values like "Khqr"):
  - Order: `PENDING, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, CANCELLED`
  - Payment status: `PENDING, PAID, FAILED, REFUNDED, PAID_AFTER_CANCEL`
  - Payment method: `KHQR, CASH_ON_DELIVERY, CARD, BANK_TRANSFER` → "KHQR", "Cash on Delivery", "Card", "Bank Transfer"
  - Shipping: `STANDARD, EXPRESS, SAME_DAY` → "Standard", "Express", "Same Day"
  - Shipment: `PREPARING, IN_TRANSIT, OUT_FOR_DELIVERY, DELIVERED`
- **KHQR** has two modes, returned in the field `mode` (`MOCK` | `BAKONG`):
  - `POST /payments/{orderNumber}/khqr` → `{ orderNumber, qrString, qrPayload (old alias — ignore), md5, amount, currency, expiresAt, mode }`. Same QR while valid; new one after expiry.
  - `GET /payments/{orderNumber}/status` → status + `failureReason` when failed.
  - `POST /payments/callback` exists **only in MOCK mode** (404 in BAKONG).
  - **502** (Bakong/token problem) and **504** (Bakong timeout) are NOT payment failures — keep polling and show a small warning.
  - Admin: `POST /admin/payments/{orderNumber}/recheck` (BAKONG only; 400 in MOCK).
- **Late payment**: unpaid KHQR orders are auto-cancelled after 30 min (`cancelledReason: "KHQR payment timeout"`). Payment made later → payment status **`PAID_AFTER_CANCEL`** while the order stays `CANCELLED`.
  - Admin: `GET /admin/payments?status=PAID_AFTER_CANCEL`, `POST /admin/orders/{orderNumber}/restore-after-payment` (409 = out of stock, 400 = wrong state), `POST /admin/payments/{id-or-orderNumber}/refund`.
- Notifications have `priority` (`NORMAL` | `HIGH`).
- **Addresses** have optional `latitude` / `longitude` (both or neither, 6 decimals). Orders return `deliveryLatitude` / `deliveryLongitude` (snapshot at checkout).
  - ⚠️ `PUT /users/me/addresses/{id}` replaces ALL fields: an update without latitude/longitude **clears** the location. When editing, always send the current coordinates unless the user removed the pin.
- Gaps already known (handle on the client, do not ask the backend): no banners endpoint, no status filter on `GET /orders`, no "can I review" endpoint (derive from delivered orders + reviews list), no totals endpoint without a coupon.

## 2. Tech stack
- Next.js 14+ (App Router), TypeScript strict, Tailwind CSS, shadcn/ui
- TanStack Query (server data), Zustand (auth + cart badge), Axios (one instance + interceptors)
- React Hook Form + Zod, Recharts (dashboard), lucide-react, sonner (toasts), qrcode.react (KHQR)
- react-leaflet + leaflet (maps, OpenStreetMap tiles, no API key) — load with `next/dynamic` and `ssr: false`
- `.env.local`: `NEXT_PUBLIC_API_URL=http://localhost:8080/api/v1`, `NEXT_PUBLIC_FILE_URL=http://localhost:8080`, `NEXT_PUBLIC_PROMO_COUPON=WELCOME10`, `NEXT_PUBLIC_NOMINATIM_CONTACT=` (contact for Nominatim, I will fill it)

## 3. Folder structure
```
src/
├── app/
│   ├── (store)/   page (home), products, products/[slug], cart, checkout, checkout/pay/[orderNumber],
│   │              checkout/success/[orderNumber], orders, orders/[orderNumber], orders/[orderNumber]/invoice,
│   │              profile, profile/addresses, profile/password, notifications
│   ├── (auth)/    login, register
│   ├── admin/     dashboard, products, products/new, products/[id], categories, brands, inventory,
│   │              orders, orders/[orderNumber], payments, coupons, reviews, users
│   └── layout.tsx
├── components/    ui/ (shadcn), store/, admin/, shared/ (map, confirm-dialog, status-badge, empty/error states)
├── lib/           api.ts, query-client.ts, format.ts (USD, dates, enumLabel), constants.ts, geocoder.ts
├── services/      one per backend module (auth, product, cart, order, payment, address, review, notification, admin…)
├── hooks/         TanStack Query hooks
├── store/         authStore.ts (Zustand + persist)
├── types/         DTO types + ApiResponse<T>, PageResponse<T>
└── middleware.ts  protect /checkout, /orders, /profile, /notifications, /admin
```

## 4. API handling & auth
- Axios interceptor adds `Authorization: Bearer <token>`; on 401 (not on /auth/*) → clear auth and redirect to `/login?redirect=…`.
- Unwrap `ApiResponse`; show `message` in a toast on error; map `errors` into form fields.
- Store the token so `middleware.ts` can read it (cookie) and the client can use it.
- **Logout** (customer header and admin sidebar): confirmation dialog → clear token, cookie, persisted Zustand state, TanStack Query cache (`queryClient.clear()`), cart badge, notification count → redirect to `/login`. After logout, browser Back and F5 must not show protected pages. Logging in as another user must never show the previous user's data.
- CUSTOMER trying `/admin` → redirect to `/`. ADMIN/STAFF trying the store checkout → allowed to browse, but show "Admin accounts cannot place orders" on checkout.

## 5. Customer Store pages (lesson component 16)
1. **Home** — hero/promo banner with coupon code (copy button), category tiles, New arrivals, Top rated, brand strip.
2. **Products / Search** — keyword search; if the keyword exactly equals a category name (laptop, desktop, monitor, component, accessory) apply that category filter instead and show it as a removable chip. Filter sidebar (category, brand, price min–max, RAM 8/16/32/64, rating, in stock), sort (price ↑↓, newest, rating, popular), pagination, filters synced to the URL, skeletons, empty state.
3. **Product Details** — gallery (max ~520px wide on desktop), name, brand, price, stock ("Only 3 left", "Out of stock" disables Add), spec table (CPU, RAM, storage, GPU, screen, OS, warranty — hide empty rows), quantity, Add to cart, rating + reviews (paged), review form only when the user has a delivered order with this product and has not reviewed yet.
4. **Image fallback** — when an image is missing or fails: soft gradient + category icon + brand name (same as the Flutter app).
5. **Cart** — quantity +/-, remove, coupon apply/remove, subtotal / discount / shipping / total exactly from the backend; header badge. Content max width ~900px, centered.
6. **Checkout** — stepper: Address (saved or add new, with map) → Shipping (`/shipping/methods`) → Payment (KHQR, Cash on Delivery, Card, Bank Transfer) → Review & Place order.
7. **KHQR payment page** `/checkout/pay/[orderNumber]`:
   - `POST /payments/{orderNumber}/khqr`, render `qrString` with qrcode.react (≥ 260px, white background, quiet zone) inside a card with a **red KHQR header**, merchant name, amount, currency, order number.
   - Countdown to `expiresAt` (use server time from the response, not the PC clock); expired → "QR expired" + **Generate new QR**.
   - Poll status every 3 s; pause when the tab is hidden, check immediately on focus; PAID → success; FAILED → `failureReason` + retry; 502/504 → keep polling + small banner.
   - **Download QR** (PNG). **Simulate payment** button ONLY when `mode === "MOCK"`.
   - "Pay later – view order"; Order Detail shows **Pay now** for unpaid KHQR orders.
8. **Order Success** — "Payment received!" / "Order placed", order number, View order, Continue shopping.
9. **My Orders** — tabs by status (filter on the client), status badges. **Order Detail** — status + payment badges, vertical timeline, items, totals, receiver/address/shipping/payment, tracking number, small map with the delivery pin (click → Google Maps), invoice page (printable), Cancel with reason (only PENDING/CONFIRMED/PROCESSING), Write review on delivered items, `cancelledReason`, and the `PAID_AFTER_CANCEL` message: "We received your payment after the order was cancelled. Our team will restore your order or refund you."
10. **Profile** — edit info, change password, addresses CRUD + set default (all with confirmation dialogs).
11. **Notifications** — bell + unread count, dropdown + page, mark read / all read, HIGH priority first with a red marker.
12. **Login / Register** — Zod validation, show/hide password, redirect back after login.

## 6. Address map (profile + checkout) — same behaviour as the Flutter app
- Map 220–260px high, default center Phnom Penh (11.5564, 104.9282), OSM attribution visible.
- **Use my current location** (`navigator.geolocation`, `enableHighAccuracy: true`, timeout 10 s): move map + pin; draw an **accuracy circle** (`coords.accuracy` in metres); if accuracy > 100 m show "Your location is approximate (±X m / ±X km). Please drag the pin to your exact location." and zoom to fit the circle. Desktop PCs have no GPS, so this warning is expected.
- Click the map to place the pin, drag the pin to adjust (map must not pan while dragging); moving the pin manually removes the circle and warning; "Remove pin" button.
- Errors (denied, unavailable, timeout): clear message, keep Phnom Penh, **never place a fake pin**.
- **Reverse geocoding with Nominatim** (`https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=..&lon=..&accept-language=en`): debounce 1 s, max 1 request/second. In Cambodia Nominatim stores the **khan in `town`** and the city/province in `state`:
  - City = `city ?? state ?? province` (e.g. "Phnom Penh", "Siem Reap")
  - Address line = road/house, then hamlet/village (phum/sangkat), suburb/quarter, then town/county (khan/district) — no duplicates, not the city.
  - Fill Address and City only if the user has not typed in them; on failure keep the pin and ask the user to type.
- Admin order detail: map with the delivery pin + "Open in Google Maps".

## 7. Admin Panel (lesson component 13)
Sidebar layout, role-aware menu (STAFF: Orders, Inventory, Shipments only). Red banner when there are unread HIGH notifications (e.g. "Customer paid after cancel") linking to Payments.
- **Dashboard** — KPI cards (total sales, orders, customers, low-stock count), sales line chart with date range, orders by status pie, top 5 products.
- **Products** — data table (search, filter, pagination), create/edit form with all spec fields + image upload (`POST /admin/uploads`) + preview, activate/deactivate.
- **Categories / Brands** — CRUD in dialogs.
- **Inventory** — stock table with low-stock highlight, restock / adjust dialog, inventory log history.
- **Orders** — filter by status/date/keyword, detail page with map, change status (only valid next statuses), ship with tracking number, update delivery status (OUT_FOR_DELIVERY, DELIVERED).
- **Payments** — filter by method/status, `failureReason`, md5/hash in detail, Refund, **Recheck with Bakong** (BAKONG only). **PAID_AFTER_CANCEL**: red badge, "Paid after cancel" tab with count, **Restore order** (409 → "Out of stock — please refund") and **Refund**.
- **Coupons** — CRUD (type, value, min amount, max uses, dates, active).
- **Reviews** — list, hide/show, delete.
- **Users** — list/search, change role, enable/disable (an admin cannot disable or demote themselves).
- Confirmation dialog before every destructive or money action.

## 8. UI / UX
- Same brand as the Flutter app: dark navy header (#0B1F3A-ish) + orange accent (#FF7A1A-ish), red KHQR header, light and dark mode.
- Fully responsive (mobile, tablet, desktop); forms and detail pages max ~900px wide on desktop.
- USD prices (`$1,299.00`), loading skeletons, error states with Retry, empty states everywhere.
- Accessible: labels, keyboard navigation, focus states, alt text. `next/image` with the backend image domain in `next.config`.

## 9. Testing
- `npm run lint`, `npm run typecheck` (tsc --noEmit) and `npm run build` → zero errors.
- **Vitest + React Testing Library**: format utils + enumLabel, Nominatim address mapping (use real Cambodian JSON samples: Khan Sen Sok, Khan Daun Penh, Siem Reap), cart totals display, checkout stepper validation, login form, KHQR page states (expired, FAILED, 504, Simulate hidden in BAKONG), address form keeps coordinates on edit.
- **Every confirmation dialog** (logout, cancel order, delete address, delete product/category/brand/coupon/review, refund, restore, disable user) must be tested inside the real layout: confirm runs the action, cancel does nothing, the dialog closes.
- **Playwright E2E** against the real backend (headless Chromium):
  - At the start of each test, clear the customer's cart (`DELETE /cart`) so runs are repeatable; print created order numbers.
  - `purchase.spec.ts`: customer login → search "laptop" (Laptop chip) → product → add to cart → `WELCOME10` → checkout with KHQR → Simulate payment → order CONFIRMED + KHQR label.
  - `lifecycle.spec.ts` (the full lesson flow): admin login → that order → PROCESSING → ship with tracking → OUT_FOR_DELIVERY → DELIVERED → customer login → Write review (5 stars) → product rating updated → notifications show shipped/delivered.
  - `address-map.spec.ts`: Playwright `context.setGeolocation` + `grantPermissions(['geolocation'])` → Use my current location → pin placed → save → address card shows map; edit only the text → coordinates still saved.
  - `auth.spec.ts`: logout → reload → still on /login; back button does not show protected pages; customer cannot open /admin.
  - `khqr-states.spec.ts` with `page.route` mocks: expired → new QR, 504 → keeps polling, FAILED → reason, `mode: BAKONG` → no Simulate button.
  - Save screenshots of every main page to `screenshots/`.

## 10. Deliverables & rules
- Build in this order and make sure it compiles after each step: setup + API layer + auth/logout → catalog/search → product detail → cart → checkout + address map + KHQR → orders/profile/notifications → **admin panel** → tests → screenshots.
- No mock data in the final app — everything comes from the backend.
- No TODOs, no unfinished pages, no placeholder contact strings (use the env var).
- `README.md`: requirements (Node 20+), setup, env vars, how to start (backend must already run), `npm run dev`, all test commands, screenshots, and a table of every page → route → endpoints used.
- Final report: test counts, E2E results, what you could not verify, and any backend gaps you found.
