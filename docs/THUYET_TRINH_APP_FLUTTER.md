# Syna — Ứng dụng Smart Home (Flutter)

> Slide thuyết trình cho ứng dụng di động **Syna** — nền tảng điều khiển nhà thông minh
> xây dựng bằng Flutter (Android & iOS), kết nối tới hệ backend microservices của dự án.

---

## 1. Giới thiệu tổng quan

- **Tên ứng dụng:** Syna Smart Home
- **Nền tảng:** Flutter (Android, iOS) — cùng codebase, chạy được cả desktop/web cho demo
- **Vai trò:** App di động cho người dùng cuối điều khiển thiết bị nhà thông minh
- **Kết nối:** Giao tiếp với backend microservices (auth, device, notification, AI...) qua REST + WebSocket
- **Điểm nhấn:** Giao diện **Glassmorphism** hiện đại, mô hình **nhà 3D**, **trợ lý AI** hội thoại, đa ngôn ngữ (Việt/Anh)

**Thông tin kỹ thuật**
| Hạng mục | Giá trị |
|---|---|
| Package Android | `com.syna.smarthome` |
| Bundle ID iOS | `com.syna.smarthome` |
| Version | `1.0.0+1` |
| Flutter SDK | Dart `^3.9.2` |
| Flavor | development / staging / production |

---

## 2. Các tính năng chính

| Tính năng | Mô tả |
|---|---|
| 🔐 **Xác thực** | Đăng nhập / Đăng ký, lưu token an toàn (secure storage), tự động refresh |
| 🎬 **Onboarding + Splash** | Màn hình khởi động và giới thiệu lần đầu |
| 🏠 **Home** | Trang chủ với **mô hình nhà 3D**, tổng quan thiết bị, truy cập nhanh |
| 🚪 **Rooms** | Quản lý theo phòng, xem thiết bị trong từng phòng |
| 💡 **Devices** | Danh sách + màn chi tiết thiết bị, bật/tắt & điều chỉnh realtime |
| 🤖 **AI Assistant** | Trợ lý hội thoại (chat), kết nối AI service điều khiển bằng ngôn ngữ tự nhiên |
| ⚙️ **Automation** | Kịch bản tự động hoá |
| 📹 **Camera** | Xem camera an ninh |
| ⚡ **Energy** | Theo dõi tiêu thụ điện năng |
| 🔔 **Notifications** | Thông báo realtime qua WebSocket (push) |
| 👤 **Profile & Settings** | Hồ sơ người dùng, cài đặt, đa ngôn ngữ |

---

## 3. Kiến trúc ứng dụng

### Feature-First Architecture
Mỗi tính năng là một module độc lập, chia 3 tầng rõ ràng:

```
lib/
├── app/            # Bootstrap, config, router, theme, localization
│   ├── router/     # GoRouter — điều hướng + bảo vệ route
│   ├── theme/      # Material 3 + Glassmorphism design tokens
│   └── config/     # Cấu hình môi trường (dev/staging/prod)
├── core/           # Dùng chung toàn app
│   ├── network/    # Dio client, auth interceptor, error mapper
│   ├── services/   # WebSocket, notification, connectivity, backend resolver
│   ├── storage/    # Token storage, preferences
│   └── widgets/    # UI dùng chung + bộ widget Glass
└── features/       # Feature-first
    └── <feature>/
        ├── data/         # Repository, DTO, API
        ├── domain/       # Model, interface
        └── presentation/ # Screen, controller (state)
```

### Nguyên tắc phân tầng
- **data** — gọi API, ánh xạ DTO ↔ domain model, có bản *mock* để demo/test
- **domain** — model thuần & interface repository (không phụ thuộc Flutter)
- **presentation** — màn hình + controller quản lý state

> Ưu điểm: đổi backend thật chỉ cần thay implementation của repository,
> **không phải sửa UI** (Mock → API repository qua cùng một interface).

---

## 4. Công nghệ & thư viện chính

| Nhóm | Thư viện | Vai trò |
|---|---|---|
| **State Management** | `flutter_riverpod` | Quản lý trạng thái, dependency injection |
| **Routing** | `go_router` | Điều hướng khai báo, deep link, bảo vệ route |
| **Networking** | `dio` | HTTP client, interceptor, timeout |
| **Realtime** | WebSocket (STOMP) | Cập nhật thiết bị & thông báo realtime |
| **Bảo mật** | `flutter_secure_storage` | Lưu token mã hoá |
| **Local storage** | `shared_preferences` | Lưu tuỳ chọn người dùng |
| **Model gen** | `freezed`, `json_serializable` | Sinh code model & JSON |
| **UI** | Material 3, `flutter_svg`, `cached_network_image` | Giao diện & ảnh |
| **3D** | `model_viewer_plus` | Hiển thị mô hình nhà 3D |
| **Thông báo** | `flutter_local_notifications` | Push notification cục bộ |
| **Đa ngôn ngữ** | `flutter_localizations`, `intl` | Việt / Anh |

---

## 5. Điểm nhấn kỹ thuật

### 5.1 Thiết kế Glassmorphism
- Bộ widget **Glass** riêng: `GlassCard`, `GlassAppBar`, `GlassBottomNav`, `GlassSlider`,
  `GlassToggle`, `GlassSegmentedControl`, `AmbientBackground`, `SlideToConfirm`...
- Hiệu ứng kính mờ (blur + trong suốt) + nền chuyển động (ambient) tạo cảm giác cao cấp.

### 5.2 Điều hướng thông minh (GoRouter)
- **StatefulShellRoute** với thanh nav 5 nhánh, giữ state từng tab.
- **Redirect guard**: tự chuyển hướng theo trạng thái đăng nhập & onboarding
  (splash → onboarding → login → home).

### 5.3 Kết nối Edge / Cloud / Offline
`BackendResolver` tự phát hiện chế độ kết nối:
- **Edge** — kết nối trực tiếp edge box trong nhà (nhanh, cục bộ)
- **Cloud** — qua gateway đám mây khi ở xa
- **Offline** — mất kết nối, hiển thị trạng thái phù hợp

Nhờ đó app luôn chọn đường truyền tối ưu và hiển thị đúng trạng thái cho người dùng.

### 5.4 Realtime qua WebSocket
- Trạng thái thiết bị và thông báo được đẩy **realtime** qua kênh WebSocket/STOMP riêng
  cho từng service (device-service, notification-service).

### 5.5 Đa môi trường (Flavors)
- 3 flavor: **development / staging / production**, mỗi flavor có URL API riêng,
  cấu hình qua `--dart-define-from-file`.

---

## 6. Luồng hoạt động (Demo)

```
Splash ──► Onboarding (lần đầu) ──► Login/Register
                                          │
                                          ▼
        ┌──────────────── Home (nhà 3D) ─────────────────┐
        │        │           │           │        │      │
      Rooms   AI Assist   Automation   Energy   Camera  Profile
        │                                                 │
     Device                                          Settings /
     Detail                                         Notifications
```

1. Mở app → **Splash** kiểm tra phiên đăng nhập
2. Lần đầu → **Onboarding** giới thiệu
3. **Đăng nhập** → token lưu vào secure storage
4. Vào **Home**: xem mô hình nhà 3D, điều khiển nhanh thiết bị
5. Duyệt **phòng → thiết bị**, bật/tắt & điều chỉnh
6. Hỏi **AI Assistant** để điều khiển bằng ngôn ngữ tự nhiên
7. Nhận **thông báo realtime** khi có sự kiện

---

## 7. Chạy & Build

**Chạy dev**
```bash
flutter pub get
flutter gen-l10n
flutter run --flavor development \
  --target lib/main_development.dart \
  --dart-define-from-file=config/development.json
```

**Kiểm tra chất lượng code**
```bash
dart format .
flutter analyze
flutter test
```

**Build release (Play Store)**
```bash
flutter build appbundle --release --flavor production \
  --target lib/main_production.dart \
  --dart-define-from-file=config/production.json
```

---

## 8. Kết luận

- ✅ **Kiến trúc sạch, mở rộng dễ** — feature-first, phân tầng data/domain/presentation
- ✅ **Sẵn sàng release** — cấu hình đa flavor, ký ứng dụng, checklist store đầy đủ
- ✅ **Trải nghiệm hiện đại** — Glassmorphism, nhà 3D, trợ lý AI, realtime
- ✅ **Kết nối linh hoạt** — tự chọn Edge/Cloud/Offline, tích hợp microservices thật
- ✅ **Đa ngôn ngữ** — hỗ trợ Tiếng Việt & Tiếng Anh

> **Syna** là ứng dụng smart home hoàn chỉnh từ giao diện đến kết nối backend,
> minh chứng cho một quy trình phát triển Flutter chuyên nghiệp, có thể đưa lên store.

---

*Tài liệu thuyết trình — Dự án SEP490*
