# <E### | F###> — <Tên kịch bản ngắn>

- **Loại:** `E` = 1 màn hình · `F` = luồng liên hoàn nhiều tab
- **Màn hình / URL (tương đối):** `/TiepNhan/Index` *(chỉ đường dẫn tương đối, không ghi host/port máy cá nhân)*
- **Áp dụng:** `v2` / `v3` / `v2+v3`
- **Tag:** `#...`
- **Ngày kiểm chứng:** YYYY-MM-DD *(lần gần nhất chạy PASS)*
- **Nguồn:** `<TASK_ID>` / `BUG_REPORT` của `<TASK_ID>` / người dùng
- **Thuật ngữ:** dùng đúng `GLOSSARY.md`

## Điều kiện trước
- Người dùng **đã tự đăng nhập** trên tab Orca bằng tài khoản test có quyền: `<vai trò, vd Thu ngân>`. **KHÔNG ghi mật khẩu vào file này.**
- App `dotnet watch run` đang trỏ **DB Dev/Test** (không bao giờ chạy trên Prod).
- Dữ liệu: tự tạo mới ở bước đầu *(ưu tiên)* hoặc dùng dữ liệu test cố định: `<mô tả, không ghi thông tin bệnh nhân thật>`.

## Các bước *(định vị bằng `id` / `name` / nhãn hiển thị — KHÔNG ghi ref `@e12`, ref đổi sau mỗi lần snapshot)*
| # | Tab | Thao tác | Phần tử (`id` / nhãn) | Dữ liệu |
|---|---|---|---|---|
| 1 | page_1 | Nhập | `#txtHoTen` | `BN TEST <thời gian>` |
| 2 | page_1 | Bấm | nút "Lưu" (`#btnLuu`) | |
| 3 | page_1 | Ghi nhận | Mã BN vừa sinh | → dùng cho bước sau |

## Kết quả mong đợi
- [ ] ...
- [ ] Không lỗi JS console / không lỗi validation ngoài dự kiến.

## Case sai / Fail-Fast
- [ ] *(vd bỏ trống trường bắt buộc → hiện thông báo "...", không lưu)*

## Lịch sử chạy *(Tester thêm dòng)*
| Ngày | Task | Version | Kết quả | Ghi chú (vd giao diện đổi, kịch bản cần cập nhật) |
|---|---|---|---|---|
