# RETRO_LOG — Nhật ký chấm điểm task

> Mỗi task **1 dòng**, do skill `retro-task` ghi thêm (append). Không sửa/xóa dòng cũ.
> Dùng lệnh *"retro-task tổng kết"* để xem bảng xếp hạng theo **vai trò × model × loại task**.

## Thang điểm
| Điểm | Ý nghĩa |
|---|---|
| 5 | Đúng ngay, không phải sửa |
| 4 | Đúng, chỉ sửa nhỏ (style, đặt tên, thiếu 1 case nhỏ) |
| 3 | Chạy được nhưng phải sửa đáng kể hoặc lệch style team |
| 2 | Sai nhiều, phải làm lại phần lớn |
| 1 | Hỏng / bỏ, làm lại từ đầu |

## Giá trị cố định cho các cột
- **Kích cỡ:** `-s` · `-m` · `-l` (theo `PLAN.md`)
- **Chuông báo:** `Không` · `Giữ -s` (có chuông báo nhưng người dùng giữ `-s`) · `Nâng -m`
- **Loại task:** `STO` · `UI` · `API` · `Báo cáo` · `Cổng/Đối tác` · `Khác`
- **Version:** `v2` · `v3` · `v2+v3`
- **Khâu lỗi:** `Plan` · `Code` · `Test` · `Port` · `Không`
- **Nguyên nhân:** `Thiếu mẫu` · `Plan sai/thiếu` · `Không theo mẫu/luật` · `Hiểu sai nghiệp vụ` · `Task khó/mơ hồ` · `Chưa rõ` · `Không có`
- **Planner / Coder / Tester:** `CLI/model` (vd `codex/gpt-6.2-astra`) — để trống nếu không nhớ (dòng trống model sẽ không được tính khi so model).
- **Tester PASS:** `Có` nếu Tester kết luận PASS ở lần verify cuối. *(Tester PASS mà điểm ≤ 2 = Tester để lọt lỗi.)*
- **Mẫu đã dùng:** các mã `P/X/D` gắn trong `PLAN.md`; `—` nếu không có.
- **Nháp:** tên file nháp đã tạo trong `_proposed/`; `—` nếu không có.

## Nhật ký
| Ngày | Task | Kích cỡ | Chuông báo | Loại task | Version | Điểm | Khâu lỗi | Nguyên nhân | Mẫu đã dùng | Planner | Coder | Tester | Tester PASS | Ghi chú | Nháp |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
