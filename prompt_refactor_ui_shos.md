# PROMPT — Refactor toàn bộ UI Flutter (SHOS) theo 3 ảnh tham chiếu

> Đính kèm 3 ảnh: `docs/design_refs/ref_1_dashboard.docs`, `ref_2_room.png`, `ref_3_device_detail.docs`

---

## 0. BỐI CẢNH

Đây là dự án Flutter **SmartHome OS**. Nhiệm vụ của bạn: **refactor lại toàn bộ tầng giao diện trong thư mục `lib/`** để bám sát 100% 3 ảnh thiết kế tham chiếu tôi đính kèm (bạn được phép làm **đẹp hơn**, tinh tế hơn, nhưng **không được đi chệch** khỏi ngôn ngữ thị giác của ảnh).

**Nền tảng bắt buộc:** dùng lại source code UI hiện có trong thư mục **`stich_syna_home_systems`** làm base (component, theme, cấu trúc widget, naming, asset). Đọc kỹ toàn bộ thư mục này TRƯỚC KHI viết code. Không tạo lại từ đầu những gì đã có — hãy **kế thừa và nâng cấp**. Bạn được toàn quyền refactor mạnh tay (tách widget, tạo design system, đổi cấu trúc thư mục) **miễn là kết quả đẹp hơn, sạch hơn và không phá vỡ routing / state / business logic hiện tại**.

---

## 1. BƯỚC 1 — KHẢO SÁT TRƯỚC KHI CODE (bắt buộc)

1. Liệt kê cây thư mục `lib/` và `stich_syna_home_systems/`.
2. Xác định: theme/token màu hiện có, danh sách screen, các widget dùng chung, state management đang dùng (Provider/Riverpod/Bloc/setState), router, model device/room.
3. Xuất ra một bảng **mapping**: `Screen hiện tại → Thay đổi cần làm → Ảnh tham chiếu nào`.
4. Chỉ sau khi tôi thấy bảng mapping đó trong output của bạn, mới bắt đầu viết code.

---

## 2. DESIGN SYSTEM — GLASSMORPHISM (áp dụng cho TẤT CẢ screen)

Tạo mới `lib/core/theme/` gồm: `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `glass_theme.dart`. **Cấm hardcode màu / radius / blur trực tiếp trong screen.**

### Token màu (dark-first)
| Token | Giá trị | Dùng cho |
|---|---|---|
| `bgBase` | `#0B0D10` → `#15181D` (gradient dọc) | Nền app |
| `glassFill` | `Colors.white.withOpacity(0.06)` | Nền thẻ kính |
| `glassFillActive` | `Colors.white.withOpacity(0.10)` | Thẻ khi bật/selected |
| `glassBorder` | `Colors.white.withOpacity(0.12)` | Viền 1px thẻ kính |
| `glassHighlight` | `Colors.white.withOpacity(0.22)` | Highlight mép trên thẻ |
| `accentAmber` | `#F5A623` → `#FF7A1A` (gradient) | Toggle ON, slider, CTA chính |
| `accentTeal` | `#2DD4BF` | Trạng thái phụ / sensor OK |
| `textPrimary` | `#FFFFFF` | Tiêu đề |
| `textSecondary` | `Colors.white.withOpacity(0.55)` | Subtitle, caption |
| `statusOk / warn / danger` | `#34D399` / `#FBBF24` / `#F87171` | Badge trạng thái |

### Công thức kính (chuẩn hoá 1 nơi duy nhất)
Tạo widget `GlassContainer` trong `lib/core/widgets/glass/`:
- `ClipRRect` + `BackdropFilter(ImageFilter.blur(sigmaX: 24, sigmaY: 24))`
- Fill `glassFill`, border `1px glassBorder`, radius **24–28**
- Gradient overlay chéo rất nhẹ (white 0.10 → white 0.00) tạo cảm giác phản quang
- `BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 30, offset: (0, 12))`
- Prop: `blur`, `opacity`, `radius`, `padding`, `borderGradient`, `isActive`

### Bộ widget dùng chung phải tạo (tái sử dụng ở mọi screen)
`GlassCard` · `GlassPillButton` · `GlassFilterChip` · `GlassToggle` (thumb trượt, gradient amber khi ON, có haptic) · `GlassSlider` (dạng track dày bo tròn, handle kính nổi — xem ảnh 3) · `GlassBottomNav` (floating, blur, indicator amber) · `GlassAppBar` (back tròn + more tròn) · `StatusBadge` · `SlideToUnlock` (ảnh 3, cho khoá cửa).

### Typography & motion
- Font: `Inter` hoặc `SF Pro`-like; H1 32/700, H2 22/600, body 15/400, caption 12/500 letterSpacing 0.2.
- Motion: mọi transition `Curves.easeOutCubic` 250–350ms. Card có `scale 0.97` khi nhấn. Toggle animate 220ms. Dùng `flutter_animate` nếu đã có trong pubspec, nếu chưa thì tự viết bằng `AnimatedContainer`/`TweenAnimationBuilder` — **không thêm dependency nặng nếu không cần**.
- Hiệu năng: bọc `RepaintBoundary` quanh mỗi thẻ kính, **không lồng BackdropFilter trong BackdropFilter**, `precacheImage` cho ảnh nền phòng/thiết bị.

---

## 3. SCREEN 1 — DASHBOARD (ảnh 1)

Dựng **Hero Card** trên cùng, chiếm ~40% chiều cao màn:
- Thẻ kính lớn, radius 32, blur mạnh.
- Bên trái: icon shield tròn (nền tương phản), tiêu đề lớn **"Nhà an toàn"**, subtitle **"Tất cả hệ thống hoạt động bình thường"**. Tiêu đề đổi theo trạng thái thực (an toàn / cảnh báo / mất kết nối) kèm đổi màu icon.
- Bên phải, tràn nhẹ ra ngoài mép thẻ: **mô hình 3D ngôi nhà isometric** — đúng như ảnh 1.

### Yêu cầu mô hình 3D (bắt buộc)
- Dùng **`model_viewer_plus`** hiển thị file `assets/models/house.glb`, `autoRotate: true`, `cameraControls: true`, `backgroundColor: transparent`, `disableZoom: true`, camera orbit isometric (~`45deg 55deg 4m`).
- Nếu chưa có `house.glb`: tạo `assets/models/README.md` ghi rõ spec model cần (nhà 2 tầng trắng hiện đại, cây xanh, mặt cắt lộ nội thất, tỉ lệ isometric) và tạm dùng **fallback** `HouseModel3DFallback` — render isometric bằng ảnh PNG + hiệu ứng parallax nghiêng theo `AccelerometerEvent` hoặc theo vị trí ngón tay, có shadow mềm bên dưới. Code phải tự động dùng `.glb` ngay khi file tồn tại.
- Bọc trong `RepaintBoundary`, lazy-load, có shimmer placeholder lúc chờ.

### Dải 3 thẻ trạng thái (dưới hero, đúng ảnh 1)
3 `GlassPillCard` nằm ngang, mỗi thẻ: icon vuông bo tròn bên trái + label đậm + giá trị nhạt bên dưới.
`Cửa — 1/4 đang mở` · `Đèn — 3/8 đang bật` · `Hệ thống — Đã kích hoạt`. Tap → điều hướng sang màn tương ứng. Số liệu lấy từ state thật, không hardcode.

### Phần còn lại của Dashboard
Giữ nguyên các section hiện có (scene, phòng, gợi ý AI Agentic) nhưng **bọc lại toàn bộ bằng `GlassCard`** cho đồng bộ. Nền màn = ảnh nhà mờ + `bgBase` gradient overlay.

---

## 4. SCREEN 2 — ROOM DEVICES (ảnh 2)

Bám sát 100% ảnh 2:
- **Background:** ảnh thật của phòng (`assets/images/rooms/<room_id>.jpg`), phủ gradient tối từ trên xuống (black 0.55 → black 0.85) để chữ luôn đọc được. Ảnh scroll với `parallax` nhẹ.
- **AppBar trong suốt:** nút back tròn kính bên trái, nút `...` tròn kính bên phải.
- **Header:** tên phòng H1 (VD "Phòng khách") + subtitle `8 thiết bị • 5 đang bật` (đếm động từ state).
- **Filter chips** cuộn ngang: `Tất cả · Chiếu sáng · Thiết bị điện · Cảm biến · Khác`. Chip active: nền **amber**, chữ đen, bo tròn hoàn toàn. Chip inactive: kính trong. Animate khi đổi.
- **Grid thiết bị** `GridView` 2 cột (mobile) / 4 cột (tablet), `childAspectRatio ~0.78`:
  - Mỗi card kính: **ảnh sản phẩm PNG nền trong suốt** chiếm 55% trên, tên thiết bị (600), category nhạt bên dưới, control ở đáy.
  - Control theo `deviceType`: đèn/ổ cắm → `GlassToggle`; điều hoà → toggle + `23°C`; rèm → `‹ 60% ›` stepper; cảm biến/lọc khí → toggle + `● Good` (chấm teal).
  - Card ở trạng thái ON: viền sáng hơn + glow amber rất nhẹ + ảnh sản phẩm sáng hơn (đèn phát sáng — xem ảnh 2). Card OFF: desaturate ảnh nhẹ.
  - Tap card → Device Detail (hero animation ảnh sản phẩm). Tap toggle → **không** điều hướng.
- **Bottom nav kính nổi** 5 tab: Trang chủ · Phòng · Tự động · An ninh · Cá nhân. Tab active: icon amber + nền kính sáng.

---

## 5. SCREEN 3 — DEVICE DETAIL (ảnh 3)

**Ảnh sản phẩm làm background** — đây là điểm cốt lõi:
- `Stack`: layer 0 = ảnh sản phẩm full-bleed, phóng lớn, canh lệch (off-center) đúng như ảnh 3; layer 1 = gradient scrim dọc + `BackdropFilter` blur nhẹ chỉ ở vùng có nội dung; layer 2 = các control kính.
- Ảnh nhận `Hero` tag từ Room grid.
- Có glow màu theo trạng thái toả ra từ sản phẩm (đèn bật → glow ấm; khoá → glow amber quanh vòng vân tay).

### Biến thể ĐÈN (ảnh 3, trái)
- AppBar kính: back · tên thiết bị · `⋮`.
- **Segmented control kính**: `Ấm · Trung tính · Lạnh` — segment active là thẻ kính sáng trượt mượt (`AnimatedAlign`).
- **Thanh sáng ngang** dưới ảnh: nút nguồn tròn bên trái, `GlassSlider` giữa hiển thị `50%` (kéo được, haptic mỗi 10%), icon độ sáng bên phải.
- **Lịch trình**: list các dòng `Sun / Mon / Tue…` với `On time 08:00 AM`, `Off time 10:00 PM` và toggle amber từng dòng. Dòng = thẻ kính mỏng, tap để mở time picker.

### Biến thể KHOÁ CỬA (ảnh 3, phải)
- Tiêu đề kèm icon ổ khoá. Hàng **status pills** kính: `360°` · `🔒 Đã khoá` · `🔋 71%`.
- **Lịch sử**: dòng gần nhất `⏰ 11:21 PM — Tôi — dùng Vân tay 1`, có `Xem tất cả`.
- **3 thẻ hành động nhanh** kính: `Mã tạm thời` · `Quản lý thành viên` · `Ngữ cảnh thông minh`.
- **`SlideToUnlock`** cuối màn: pill gradient amber→cam, hai icon khoá hai đầu, chevron `»» ` chạy animation, kéo để mở khoá + haptic + đổi trạng thái. **Bắt buộc phải kéo, không được tap-to-unlock.**

Các loại thiết bị khác (điều hoà, rèm, TV, quạt…) dùng chung `DeviceDetailScaffold` + widget control riêng theo `deviceType` — **không copy-paste screen**.

---

## 6. RÀNG BUỘC KỸ THUẬT

- Toàn bộ text UI bằng **tiếng Việt** (đưa vào file localization nếu dự án đã có, không hardcode chuỗi rải rác).
- **Không phá** logic MQTT / state / model / router hiện tại. Nếu buộc phải đổi signature, ghi rõ trong phần tổng kết.
- Responsive: mobile (1 cột lớn / grid 2 cột) và tablet (grid 4 cột) — dùng `LayoutBuilder`, không dùng số cứng.
- `flutter analyze` phải sạch (0 error, 0 warning). Format bằng `dart format`.
- Mọi ảnh mới đặt trong `assets/`, khai báo đủ trong `pubspec.yaml`. Nếu asset chưa có → tạo placeholder + ghi vào `assets/ASSETS_NEEDED.md`.
- Không thêm package ngoài trừ: `model_viewer_plus` (bắt buộc cho 3D) và tối đa 1 package animation nếu thật sự cần.

---

## 7. THỨ TỰ THỰC HIỆN

1. Khảo sát + bảng mapping (mục 1).
2. Design system + bộ widget kính dùng chung.
3. Dashboard + mô hình 3D.
4. Room Devices.
5. Device Detail (đèn → khoá → các loại còn lại).
6. Bottom nav + điều hướng + hero animation.
7. `flutter analyze`, `dart format`, tự review lại từng screen **so với ảnh tham chiếu**.

---

## 8. TIÊU CHÍ NGHIỆM THU (tự kiểm trước khi báo xong)

- [ ] Đặt screenshot cạnh ảnh tham chiếu: bố cục, khoảng cách, bo góc, màu accent khớp.
- [ ] 100% screen dùng glassmorphism từ cùng một `GlassContainer`.
- [ ] Dashboard có mô hình 3D nhà xoay được (hoặc fallback parallax hoạt động).
- [ ] Room có ảnh nền phòng + filter chips + grid card có ảnh sản phẩm + toggle amber.
- [ ] Device Detail có ảnh sản phẩm làm background + slider + lịch trình + slide-to-unlock cho khoá.
- [ ] Không hardcode màu/blur ngoài theme. Không lồng BackdropFilter. Scroll 60fps.
- [ ] `flutter analyze` sạch, app build & chạy được.

Cuối cùng, tổng kết: file nào tạo mới, file nào sửa, asset nào còn thiếu, và điểm nào bạn đã **làm đẹp hơn** so với ảnh gốc (kèm lý do).
