# ecom — web app (Next.js)

Online computer store (laptops, desktops, monitors, components, accessories) with a **Customer Store** and an **Admin Panel** (ADMIN + STAFF). It talks to the existing Spring Boot API; nothing is mocked in the app.

## Requirements
- Node.js 20+ and npm
- The backend running on `http://localhost:8080` (`KHQR_MODE=mock`, Postgres in Docker). **This project never starts, stops or changes the backend.**
  Check it: `curl -s http://localhost:8080/api/v1/categories`

## Setup
```bash
npm install
npx playwright install chromium     # only needed for E2E
cp .env.example .env.local          # then edit if needed
npm run dev                         # http://localhost:3000 (backend CORS allows this port)
```

| Env var | Purpose |
|---|---|
| `NEXT_PUBLIC_API_URL` | API base, `http://localhost:8080/api/v1` |
| `NEXT_PUBLIC_FILE_URL` | host that serves `/uploads/...` images |
| `NEXT_PUBLIC_PROMO_COUPON` | coupon shown (with Copy button) on the home banner, `WELCOME10` |
| `NEXT_PUBLIC_NOMINATIM_CONTACT` | contact e-mail sent to Nominatim (usage policy). **Fill this in** before real use; empty = not sent |

Seed accounts: `admin@ecom.com / Admin@123`, `staff@ecom.com / Staff@123`, `customer@ecom.com / Customer@123`.

## Commands
| Command | What it does |
|---|---|
| `npm run dev` | dev server on port 3000 |
| `npm run build` / `npm start` | production build / serve on 3000 |
| `npm run lint` | ESLint |
| `npm run typecheck` | `tsc --noEmit` |
| `npm test` | Vitest + React Testing Library (unit/component, no backend needed) |
| `npm run e2e` | Playwright against the real backend + dev server (headless Chromium) |
| `npm run e2e:screens` | only the screenshot spec → `screenshots/` |

E2E notes: runs serially (shared backend + customer cart). Each test clears the cart first with `DELETE /cart`, order numbers are printed, `purchase.spec.ts` runs first so `lifecycle.spec.ts` fulfils that exact order. Specs: `purchase`, `lifecycle`, `address-map` (geolocation + permission mocked by Playwright, Nominatim stubbed), `auth`, `khqr-states` (`page.route` mocks), `screenshots`.

## Architecture
`src/app` routes (App Router) · `src/services` one file per backend module · `src/hooks` TanStack Query hooks · `src/store` Zustand (auth persisted, badges, checkout selections) · `src/lib` api (Axios + interceptors), format, geocoder, khqr, totals … · `src/components` ui (shadcn-style), store, admin, shared · `src/middleware.ts` protects `/checkout /orders /profile /notifications /admin` (token cookie; role cookie keeps customers out of `/admin`).

Key behaviours: logout (confirm → clears token, cookies, persisted state, Query cache, badges, checkout state → `/login` via `location.replace`; protected pages are `no-store` and re-checked on bfcache restore) · KHQR page uses the **server clock** (`expiresAt` − envelope `timestamp`), polls every 3 s, pauses on hidden tabs, treats 502/504 as warnings, shows **Simulate payment only when `mode === "MOCK"`** · address `PUT` always resends current coordinates unless the pin was removed.

## Screenshots
`screenshots/` — 01-login/register/home, 02-products, 03-product-detail, 04-cart, 05-checkout, 07-khqr-payment, 08-order-success, 09-order-detail, 10-orders, 11-invoice, 12–14 profile/addresses/password, 15-address-map, 16-notifications, 20–28 admin pages, 30-home-dark, 31-products-mobile.

## Pages → routes → endpoints
| Page | Route | Endpoints |
|---|---|---|
| Home | `/` | `GET /products` (newest, rating), `/categories`, `/brands` |
| Products / search | `/products` | `GET /products`, `/categories`, `/brands` |
| Product detail | `/products/[slug]` | `GET /products/slug/{slug}`, `/products/{id}/reviews`, `POST /cart/items`, `GET /orders` (review eligibility), `POST /products/{id}/reviews` |
| Cart | `/cart` | `GET/DELETE /cart…`, `PUT/DELETE /cart/items/{id}`, `POST /cart/apply-coupon`, `GET /shipping/methods` |
| Checkout | `/checkout` | `GET /users/me/addresses`, `POST /users/me/addresses`, `GET /shipping/methods`, `POST /cart/apply-coupon`, `POST /orders/checkout` |
| KHQR payment | `/checkout/pay/[orderNumber]` | `POST /payments/{n}/khqr`, `GET /payments/{n}/status`, `POST /payments/callback` (MOCK only), `GET /orders/{n}` |
| Order success | `/checkout/success/[orderNumber]` | `GET /orders/{n}` |
| My orders | `/orders` | `GET /orders` |
| Order detail | `/orders/[orderNumber]` | `GET /orders/{n}`, `POST /orders/{n}/cancel`, `GET /products/{id}/reviews`, `POST /products/{id}/reviews` |
| Invoice | `/orders/[orderNumber]/invoice` | `GET /orders/{n}/invoice` |
| Profile | `/profile` | `GET/PUT /users/me` |
| Password | `/profile/password` | `PUT /users/me/password` |
| Addresses | `/profile/addresses` | `GET/POST/PUT/DELETE /users/me/addresses…`, `PATCH …/default` |
| Notifications | `/notifications` (+ bell) | `GET /notifications`, `/notifications/unread-count`, `PATCH …/{id}/read`, `PATCH …/read-all` |
| Login / Register | `/login`, `/register` | `POST /auth/login`, `POST /auth/register` |
| Dashboard | `/admin/dashboard` | `GET /admin/reports/dashboard`, `/admin/reports/sales` |
| Products | `/admin/products`, `/new`, `/[id]` | `GET/POST/PUT/DELETE /admin/products…`, `PATCH …/active`, `POST /admin/uploads` |
| Categories / Brands | `/admin/categories`, `/admin/brands` | `GET /categories`, `/brands`, `POST/PUT/DELETE /admin/categories…`, `/admin/brands…` |
| Inventory | `/admin/inventory` | `GET /admin/inventory`, `/low-stock`, `POST …/restock`, `…/adjust`, `GET …/logs` |
| Orders | `/admin/orders`, `/[orderNumber]` | `GET /admin/orders`, `/admin/orders/{n}`, `PATCH …/status`, `PATCH …/ship`, `PATCH /admin/shipments/{id}/status` |
| Shipments (staff menu) | `/admin/shipments` | `GET /admin/orders?status=…`, same order/shipment `PATCH`es |
| Payments | `/admin/payments` | `GET /admin/payments`, `POST …/refund`, `POST …/recheck`, `POST /admin/orders/{n}/restore-after-payment` |
| Coupons | `/admin/coupons` | `GET/POST/PUT/DELETE /admin/coupons…` |
| Reviews | `/admin/reviews` | `GET /admin/reviews`, `PATCH …/visibility`, `DELETE …` |
| Users | `/admin/users` | `GET /admin/users`, `PATCH …/role`, `PATCH …/enabled` |

## Backend gaps found (handled on the client, nothing faked)
- `DELETE /cart` exists in Swagger but is missing from `API_CONTRACT.md` (used only by the E2E tests).
- No banners endpoint → home banner is static, coupon from `NEXT_PUBLIC_PROMO_COUPON`.
- No status filter on `GET /orders` → tabs filter the loaded page (100 orders) on the client.
- No "can I review" / "my reviews" endpoint → derived from delivered orders + product reviews list (size 100).
- No totals endpoint without a coupon → with a coupon the backend preview is shown exactly; without one, shipping is derived from `/shipping/methods` (`fee`, `freeShippingThreshold`).
- Payment DTO has no `md5`/hash, only `transactionRef` → shown as "Transaction reference / hash". `md5` is only in the KHQR generate response.
- `GET /admin/payments` filters by `status` only → the method filter works on the current page.
- No endpoint tells the client the KHQR mode for admins → "Recheck with Bakong" is offered for pending/failed KHQR payments and hidden for the session after the first mock-mode `400`.
- Cart items have no product slug/category/brand → cart thumbnails use the generic fallback and names are not links.
- No list-shipments endpoint → the Shipments page lists orders by status.
