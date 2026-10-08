# Assets còn thiếu

Các asset dưới đây được design system tham chiếu nhưng chưa có file thật.
UI hiện fallback về icon tile / màu accent — khi có ảnh, chỉ cần thêm file
và cập nhật map trong `lib/features/devices/presentation/device_visuals.dart`.

## Ảnh sản phẩm (PNG nền trong, ~512×512) — dùng cho grid card trong phòng
- [ ] Loa thông minh (`DeviceType.speaker`)
- [ ] Camera an ninh (`DeviceType.camera`)
- [ ] Cảm biến chuyển động (`DeviceType.sensor`)
- [ ] Khoá cửa PNG nền trong (hiện chỉ có `assets/images/devices/Smart Lock.jpg` nền đặc)
- [ ] Quạt trần PNG nền trong (hiện chỉ có `assets/images/devices/fan.jpg` nền đặc)
- [ ] Rèm cửa (nếu bổ sung DeviceType curtain)

## Ảnh chi tiết thiết bị (full-bleed, ~1080×1920) — background màn device detail
- [ ] Loa thông minh
- [ ] Camera an ninh
- [ ] Cảm biến

## Ảnh nền phòng (full-bleed, tối, ~1080×1920) — background màn room device
Hiện tất cả phòng dùng chung ảnh living room
(`assets/images/room_devices/livingroom_devices/premium_.../screen.png`).
- [ ] Bedroom
- [ ] Kitchen
- [ ] Garage
- [ ] Bathroom
- [ ] Garden

## Camera / Automation
- [ ] Ảnh feed camera + thumbnail sự kiện đang dùng URL demo từ Google Stitch
      (cached_network_image) — nên thay bằng asset nội bộ hoặc feed thật.
- [ ] Ảnh minh hoạ scene (Movie Night / Good Night / Focus Mode) cũng đang là URL demo.
