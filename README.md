# Obscure Engine

File `obscure_engine.cpp` do người dùng gửi, đã sửa tối thiểu để
build được thành dylib iOS. File gốc trong `workspace/user/files/`
được giữ nguyên, không sửa.

## Các sửa tối thiểu đã làm

- Tên trường trong `DrawSubsystemPanel` không khớp struct nên không
  biên dịch được: `no_ads` -> `flag_routine_4`, `sim_speed_en` ->
  `ctrl_mode_a`, `sim_speed_val` -> `val_speed_a`,
  `game_speed_en` -> `ctrl_mode_b`, `game_speed_val` -> `val_speed_b`.
  Đây là các trường ở đúng offset đã ghi chú trong struct.
- Bỏ 3 mảng pad có độ dài 0 (`pad_6`, `pad_8`, `pad_10`), không
  làm đổi offset nào (đã kiểm chứng bằng `offsetof`).
- Sửa chuỗi log bị ngắt dòng trong mã nguồn.
- Đổi `main()` thành hàm constructor `__attribute__((constructor))`
  chạy khi dylib được nạp, vì dylib không dùng `main()`.

## Giới hạn

Các hàm trong `GfxCore` chỉ là stub trả về `true`, không vẽ gì và
không đổi gì trong game. File này không có offset, hook hay ghi nhớ.
Build chỉ chứng minh code biên dịch được thành dylib arm64 iOS.

## Build

GitHub Actions trên macOS tự build và đăng artifact
`obscure-engine-dylib`. Build local trên macOS: `sh build_ios.sh`.
