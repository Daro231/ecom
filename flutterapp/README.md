# Ecom – customer mobile app (Flutter)

Customer app (Android + iOS) for the **ecom** computer store. It talks to the Spring Boot backend described in [`API_CONTRACT.md`](API_CONTRACT.md). The admin panel is web-only; staff/admin accounts are rejected at login.

## Requirements

| Tool | Version used |
|---|---|
| Flutter | 3.35.0 (stable), Dart 3.9 – any Flutter ≥ 3.24 should work |
| JDK (Android builds) | **17 or 21** (JDK 25 breaks the Gradle/Kotlin toolchain – point Flutter at 21: `flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk-amd64`) |
| Android SDK / Xcode | for device builds |

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.freezed.dart / *.g.dart (already committed to the working tree, re-run after editing models)
```

## Pointing the app at the backend

The base URL lives in `lib/core/config/env.dart` and is resolved like this:

| Where you run | Base URL |
|---|---|
| Android emulator (default) | `http://10.0.2.2:8080/api/v1` |
| iOS simulator / desktop (default) | `http://localhost:8080/api/v1` |
| **Real phone** | the **LAN IP of the PC** running the backend |

For a real device, phone and PC must be on the same Wi-Fi, the backend must listen on `0.0.0.0:8080` and the PC firewall must allow port 8080:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080/api/v1
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.20:8080/api/v1
```

Other compile-time settings: `--dart-define=PROMO_COUPON=WELCOME10` (coupon shown on the home banner).
Plain HTTP is allowed on purpose (Android `usesCleartextTraffic`, iOS ATS exception) so LAN backends work; switch the backend to HTTPS and remove both before a store release.

## Run / test / build

```bash
flutter run                                  # debug
flutter analyze                              # 0 issues
dart format lib test integration_test
flutter test                                 # unit + widget tests
flutter test integration_test/purchase_flow_test.dart -d <device-id>   # needs the backend running in KHQR mock mode
flutter build apk --release                  # build/app/outputs/flutter-apk/app-release.apk
```

The integration test logs in as `customer@ecom.com / Customer@123`, searches “laptop”, adds a product, applies `WELCOME10`, checks out with KHQR, taps “Simulate payment” and expects the order to be CONFIRMED.

## KHQR payment screen

* `POST /payments/{order}/khqr` → QR rendered with `qr_flutter` (white card, merchant, amount, currency). The countdown is computed against the **server** timestamp of the response, so the phone’s clock/time zone cannot make a QR look expired.
* Polls `GET /payments/{order}/status` every 3 s; polling pauses in the background and resumes (with an immediate check) on foreground.
* `PAID` → success page. `FAILED` + `QR expired` → “Generate new QR”; any other `failureReason` is shown. `PAID_AFTER_CANCEL` / `REFUNDED` show an explanation.
* **502 / 504 and connectivity errors are not failures**: a small banner is shown and polling continues.
* “Simulate payment” is shown **only** when `mode == "MOCK"`.
* “Save QR” (gallery) and “Share QR” (share sheet) let the customer pay from the same phone with their bank app. The screen stays awake while the QR is visible (`wakelock_plus`).
* Android 9 and older may ask for storage permission when saving to the gallery (declared with `maxSdkVersion=28`); Android 10+ needs none.

## Architecture

Feature-first, clean-architecture-light: `lib/core` (config, network, router, theme, utils, shared widgets) and `lib/features/<feature>/{data/{models,repositories},presentation/{providers,screens,widgets}}`.

* Riverpod 3 (`Notifier` / `AsyncNotifier` / `FutureProvider`), Dio + one interceptor (bearer token, 401 → clear token → Login, typed `ApiException`), freezed + json_serializable models, go_router with an auth redirect and a bottom-navigation shell.
* **Deviation:** `riverpod_annotation` / `riverpod_generator` are *not* used. Their latest releases cannot resolve against the `meta` version pinned by Flutter 3.35; providers are written by hand (same runtime behaviour). Freezed is pinned to 2.5.x and build_runner to 2.4.x for the same reason.

## Screens and the endpoints they use

| Screen | Endpoints |
|---|---|
| Splash | `GET /users/me` (when a token is stored) |
| Login | `POST /auth/login` |
| Register | `POST /auth/register` |
| Home | `GET /categories`, `GET /brands`, `GET /products?sort=newest\|rating\|popular&inStock=true`, `GET /notifications/unread-count` (bell badge) |
| Product list / search / filter | `GET /products` (keyword, categoryId, brandId, minPrice, maxPrice, ram, minRating, inStock, sort, page, size), `GET /categories`, `GET /brands` |
| Product detail | `GET /products/{id}`, `GET /products/{id}/reviews`, `POST /products/{id}/reviews`, `PUT /reviews/{id}`, `POST /cart/items`, `GET /orders` (to know if a delivered purchase exists) |
| Cart | `GET /cart`, `PUT /cart/items/{id}`, `DELETE /cart/items/{id}`, `POST /cart/apply-coupon` |
| Checkout | `GET /users/me/addresses`, `POST /users/me/addresses`, `GET /shipping/methods`, `POST /cart/apply-coupon` (totals with coupon), `POST /orders/checkout` |
| KHQR payment | `POST /payments/{order}/khqr`, `GET /payments/{order}/status`, `POST /payments/callback` (MOCK only) |
| Order success | – |
| My orders | `GET /orders?page&size` |
| Order detail | `GET /orders/{n}`, `GET /orders/{n}/tracking`, `POST /orders/{n}/cancel`, `POST /products/{id}/reviews` (Review button) |
| Invoice | `GET /orders/{n}/invoice` |
| Profile | – (reads the cached user), theme setting in SharedPreferences |
| Edit profile | `PUT /users/me` |
| Change password | `PUT /users/me/password` |
| Addresses | `GET/POST /users/me/addresses`, `PUT/DELETE /users/me/addresses/{id}`, `PATCH /users/me/addresses/{id}/default` |
| Notifications | `GET /notifications`, `PATCH /notifications/{id}/read`, `PATCH /notifications/read-all`, `GET /notifications/unread-count` |

## Backend gaps / notes (backend was not modified)

1. **No banners endpoint.** The home carousel shows one coupon slide (code from `PROMO_COUPON`, default `WELCOME10`) followed by the three most popular products.
2. **No status filter on `GET /orders`.** The order tabs filter on the device; the list keeps loading pages until a tab has content. `PROCESSING` is shown under “Confirmed”.
3. **No “my review” / “can I review” endpoint.** The app derives it from delivered orders (`GET /orders`) and from the product’s review list (`userId`).
4. **No totals endpoint without a coupon.** Without a coupon the review step estimates the shipping fee from `GET /shipping/methods` (`fee`, `freeShippingThreshold`); the placed order response is authoritative.
5. `PAID_AFTER_CANCEL` is delivered as `payment.status` while `order.status` stays `CANCELLED` (per the contract); Order Detail shows the “We received your payment after the order was cancelled…” message in that case.
6. Push notifications are local only: the app polls `unread-count` on resume and every 60 s in the foreground and raises a local notification for new items (HIGH priority first). There is no FCM/APNs registration endpoint.
7. Card and Bank-transfer payment methods have no payment API; the order is created `PENDING` and the success page is shown.
8. Khmer/English switch (optional in the brief) is not implemented.
