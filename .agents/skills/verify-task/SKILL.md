---
name: verify-task
description: Quy trình chuẩn cho AI Tester/Reviewer (context mới, ưu tiên khác họ model): soi Deleted-Lines Audit, quét 4 luật Zero-Tolerance, cross-check git diff vs script SQL để không sót khi lên Prod, và đồng bộ DEPLOY_CHECKLIST lên Online Docs qua MCP.
---

# Skill: `verify-task` (AI Tester & Reviewer — Độc lập)

## Nguyên tắc
- Chạy ở **cuộc hội thoại mới** (context sạch), ưu tiên dùng **model khác với Coder** (tùy cấu hình người dùng tại thời điểm đó).
- Bạn là **người gác cổng**. Bạn **KHÔNG sửa code**; nếu phát hiện lỗi, ghi rõ vào `TEST_REPORT.md` và trả về cho Coder sửa.

## Checklist kiểm duyệt bắt buộc (PASS đủ 5 cổng mới được duyệt)

### Cổng 1 — Deleted-Lines Audit (Chống mất hàm đồng nghiệp)
1. Chạy `git diff` (hoặc `git show <commit_id>`).
2. Liệt kê **100% các hàm, block logic, điều kiện bị xóa (`-`)**.
3. Đối chiếu từng mục với `tasks/<task>/PLAN.md`:
   - Có bất kỳ hàm/logic nào bị xóa mà **KHÔNG có trong `PLAN.md`** → **FAIL NGAY**.

### Cổng 2 — Quét 6 Luật Zero-Tolerance
Đọc kỹ mọi dòng thêm mới (`+`) trong `git diff` và đánh **FAIL NGAY** nếu thấy:
1. Chuỗi fallback đoán tên trường (`??`, `||`, `or` thử nhiều tên biến/cột khác nhau).
2. Nhánh `else` / `default` / `catch` nuốt lỗi hoặc gán mặc định một giá trị nghiệp vụ hợp lệ (kiểu `else = "B"`) mà không được duyệt trong `PLAN.md`.
3. Tên cột DB hoặc `id`/`name` HTML sai lệch so với Bảng Mapping trong `PLAN.md`.
4. Sửa file hoặc refactor ngoài phạm vi `PLAN.md`.
5. Sửa trực tiếp trên nhánh `master2` / `master3` (chưa tách nhánh riêng) hoặc có chỉnh sửa/lộ connection string trong `appsettings*.json` / `Web.config` / `.env`.
6. *(Lưu ý cho chính Tester)* **KHÔNG đọc** `appsettings*.json` trừ khi người dùng cho phép; nếu được phép chạy SQL thì **CHỈ chạy lệnh đọc (`SELECT`)**; **KHÔNG BAO GIỜ chạy `git push`.**

### Cổng 3 — Cross-Check `git diff` vs Script SQL (Chống sót khi lên Prod)
Đọc toàn bộ thay đổi ở Model / Entity / DTO / Query / lời gọi Stored Procedure trong `git diff` và đối chiếu 1–1 với `tasks/<task>/DEPLOY_CHECKLIST.md`:
1. Code có đọc/ghi **cột mới** hoặc **bảng mới** nào không? → Phải có file `01_table_*.sql` (idempotent).
2. Code có dùng **index / constraint** mới không? → Phải có `02_index_*.sql`.
3. Code có gọi **sto / function / view mới** hoặc **đổi tham số / kiểu trả về** không? → Phải có `03_*.sql` / `04_deploy_*.sql` riêng cho từng version áp dụng.
4. So sánh `04_deploy_v2.sql` với `before_v2.sql` và `04_deploy_v3.sql` với `before_v3.sql`: đảm bảo **chỉ sửa đúng đoạn theo `PLAN.md`**, không làm mất bất kỳ đoạn logic cũ/riêng nào của đồng nghiệp ở v2 hoặc v3.
5. Code có dùng **key cấu hình / dữ liệu seed** mới không? → Phải có `05_seed_*.sql`.
6. **Thiếu bất kỳ 1 script nào hoặc sai thứ tự chạy (1→5) → FAIL NGAY.**

### Cổng 4 — Chạy Test nghiệm thu theo Test Plan (Orca Browser qua `orca` CLI — hỗ trợ đa tab)
> Chỉ chạy E2E trên app `dotnet watch run` đang trỏ DB Dev/Test (tuyệt đối không tạo dữ liệu test rác lên DB Production).

1. **Test 1 màn hình (đơn tab):**
   - Mở hoặc lấy tab hiện tại: `orca tab list --json` / `orca tab create --url <url>` → lưu `browserPageId`.
   - Đọc cấu trúc màn hình: `orca snapshot --page <id>` (lấy ref `@e1`, `@e2`, ...).
   - Thao tác: `orca fill --page <id> --element <ref> --value "..."`, `orca click --page <id> --element <ref>`, xử lý popup bằng `orca dialog accept` / `dismiss`.
2. **Test luồng liên hoàn nhiều tab song song (Multi-Tab Flow — vd HIS: Tạo bệnh nhân → Thu tiền → Khám bệnh):**
   - Mở sẵn tất cả các tab của luồng và lưu `browserPageId` riêng cho từng vai trò qua `orca tab list --json`:
     - **Tab 1 (`page_1` — vd Tiếp nhận / Tạo bệnh nhân):** `orca tab create --url <URL_Tab1>`
     - **Tab 2 (`page_2` — vd Thu tiền):** `orca tab create --url <URL_Tab2>`
     - **Tab 3 (`page_3` — vd Khám bệnh):** `orca tab create --url <URL_Tab3>`
   - **Luôn gắn `--page <id>`** trên mọi lệnh (`snapshot`, `fill`, `click`, `reload`, `eval`, `screenshot`) để không bấm nhầm tab:
     1. Trên `page_1`: tạo bản ghi mới → lấy **Mã BN / Mã Hồ Sơ** vừa sinh.
     2. Chuyển sang `page_2`: truyền đúng Mã BN/HS từ Tab 1 → thực hiện nghiệp vụ (vd Thu tiền) → xác nhận trạng thái thành công.
     3. Chuyển sang `page_3`: reload/tìm đúng Mã BN/HS → kiểm tra dữ liệu & trạng thái đã đồng bộ từ Tab 1 + Tab 2, thực hiện bước cuối (vd Khám bệnh / Lưu / In).
     4. **Kiểm tra chéo & Fail-Fast:** test thêm case ngược (vd Tab 3 thao tác khi Tab 2 *chưa* thu tiền, hoặc nhập dữ liệu sai) để chắc chắn hệ thống chặn & báo lỗi đúng.
3. **Kiểm tra lỗi ngầm & Bằng chứng:**
   - Kiểm tra lỗi JS console / DOM / validation Bootstrap bằng `orca snapshot --page <id>` và `orca eval --page <id> --expression "..."`.
   - Chụp ảnh màn hình bằng chứng nếu cần (`orca screenshot --page <id>`).
   - Kiểm tra regression cho các logic cũ của v2/v3, sau đó đóng tab test nếu không cần giữ (`orca tab close --page <id>`).

### Cổng 5 — Xuất báo cáo & Đẩy lên Notion (`Release DB Scripts`) qua MCP
1. Ghi `tasks/<task>/TEST_REPORT.md` theo mẫu `.agents/templates/TEST_REPORT.md` với kết luận rõ: **PASS** hoặc **FAIL**.
2. Nếu **PASS**:
   - Cập nhật `tasks/<task>/DEPLOY_CHECKLIST.md` hoàn chỉnh.
   - Gọi MCP server **`notion`** ghi vào database **`Release DB Scripts`** (`database_id`: `422813c5-8834-8084-a0b8-fec08809f981`) — tạo/cập nhật 1 dòng mới với đúng **7 thuộc tính**:
     - `Task` (`title`): `<TASK_ID>: <Tiêu đề ngắn>`
     - `Version` (`multi_select`): `v3` và/hoặc `v2`
     - `Trạng thái` (`select`): `Chưa chạy Prod`
     - `Loại SQL` (`multi_select`): chọn đúng các loại phát sinh (`Table/Col`, `Index`, `Func/View`, `Sto`, `Seed`)
     - `Commit` (`rich_text`): `<commit_id>` của nhánh đang kiểm tra
     - `Ngày` (`date`): ngày hiện tại (`YYYY-MM-DD`)
     - `Chi tiết SQL` (`rich_text`): ghi tóm tắt chuẩn để nhìn thẳng ngoài bảng (không cần mở trang):
       - Mục **`Sửa STO:`** → **chỉ liệt kê tên các Stored Procedure / View / Function** (mỗi tên 1 dòng, vì nội dung sto dài).
       - Mục **`Thêm cột:`** (nếu có) → **dán thẳng đầy đủ lệnh `IF COL_LENGTH(...) BEGIN ALTER TABLE ... ADD ... END;`** (idempotent) để copy chạy luôn.
       - Mục **`Index / Seed:`** (nếu có) → dán thẳng lệnh ngắn gọn tương ứng.
   - Bên trong nội dung trang Notion đó, chèn đầy đủ:
     - Checklist thứ tự chạy **1 → 5** tách riêng `master3` và `master2` (dạng to-do checkbox).
     - Các **SQL Code Block** (hoặc đường dẫn file `01_...` → `05_...`) để người dùng copy 1 click dán vào SSMS.
   - Gắn link trang Notion vừa tạo vào cuối `TEST_REPORT.md`.
   - *(Nếu MCP `notion` đang tắt/lỗi mạng: báo rõ lý do và nhắc người dùng copy thủ công `DEPLOY_CHECKLIST.md` lên Notion).*
3. Dừng lại chờ người dùng duyệt **Gate 2**.
