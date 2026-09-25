# HESTA App

Ứng dụng Flutter cho HESTA, dùng hệ màu sáng của `frontend_hesta` và API `/api/v1` của `backend_hesta`.

## Chạy ứng dụng

App nhận URL API tại lúc build. Địa chỉ phải bao gồm `/api/v1`.

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

`10.0.2.2` dùng cho Android Emulator khi backend chạy trên máy phát triển. Với thiết bị thật, dùng địa chỉ mạng của backend; với bản phát hành, dùng HTTPS. Quyền truy cập HTTP chỉ được bật trong bản Android debug.

## Màn hình và dữ liệu

- Đăng nhập, đăng ký, OTP quên mật khẩu; phiên được lưu qua secure storage và 401 được xử lý tập trung.
- Chọn, tạo và tham gia nhà; tổng quan thiết bị dùng dữ liệu API.
- Danh sách thiết bị theo phòng, chi tiết, lịch sử và xóa có xác nhận cho chủ nhà. Trạng thái thiết bị chỉ để xem vì backend hiện chưa cung cấp endpoint điều khiển trực tiếp.
- Kịch bản: danh sách, tạo, bật/tắt, thêm/xóa hành động bật/tắt và xóa kịch bản. Thành viên: danh sách, tạo mã/email mời, đổi vai trò và xóa thành viên. Tài khoản: sửa hồ sơ, đổi mật khẩu và đăng xuất.

Các màn hình chi tiết tải dữ liệu khi mở. Danh sách thiết bị được dùng lại giữa tổng quan và tab thiết bị, tải lại bằng kéo xuống. Danh sách dài dùng `ListView.builder`.

Đăng nhập Google trên mobile cần cấu hình OAuth cho Android/iOS. Realtime, thông báo và các quy tắc tự động hóa chưa có trong phiên bản app này. Thiết bị không có nút điều khiển giả vì backend hiện chưa cung cấp API điều khiển trực tiếp.

## Kiểm tra

```powershell
flutter analyze
flutter test
```
