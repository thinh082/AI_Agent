---
name: verify-task
description: Quy trình chuẩn cho AI Tester/Reviewer (context mới, ưu tiên khác họ model): soi Deleted-Lines Audit, quét 6 luật Zero-Tolerance, cross-check git diff vs script SQL để không sót khi lên Prod, và đồng bộ DEPLOY_CHECKLIST lên Online Docs qua MCP.
---

# Skill: `verify-task` (AI Tester & Reviewer — Độc lập)

## Nguyên tắc
- **Bắt buộc** chạy ở **cuộc hội thoại mới** (context sạch). **Nên** dùng **model khác với Coder** (nhất là task đụng tiền, BHYT, cổng thông tin); cùng model vẫn chấp nhận được với task nhỏ hoặc khi chỉ có 1 model. Ghi model/CLI đang dùng vào `TEST_REPORT.md` (phục vụ `retro-task`).
- Bạn là **người gác cổng**. Bạn **KHÔNG sửa code dự án và KHÔNG sửa script SQL** (`01`→`05`, `99_rollback`); nếu phát hiện lỗi, ghi rõ vào `TEST_REPORT.md` và trả về cho Coder sửa.
- Bạn **CHỈ được ghi tài liệu** trong `tasks/<task>/`: tạo `TEST_REPORT.md` và hoàn thiện `DEPLOY_CHECKLIST.md` (trạng thái, commit, link Notion) — không đổi danh sách/nội dung script trong đó.

## Mức kiểm duyệt theo Kích cỡ (đọc dòng `Kích cỡ` trong `PLAN.md`)
| Cổng | `-s` | `-m` | `-l` |
|---|---|---|---|
| 1 — Deleted-Lines Audit | Đầy đủ | Đầy đủ | Đầy đủ |
| 2 — 6 Luật Zero-Tolerance | Đầy đủ | Đầy đủ | Đầy đủ |
| 3 — Cross-Check SQL | Chỉ khi có script SQL | Đầy đủ | Đầy đủ |
| 4 — Test Orca | Test nhanh 1 luồng chính + 1 case sai | Theo Test Plan | Theo Test Plan + regression đa tab |
| 5 — Báo cáo & Notion | `TEST_REPORT.md` rút gọn; Notion chỉ khi có SQL | Đầy đủ | Đầy đủ |

- **`-l` hoặc `Super plan: Có` bắt buộc khác model với Coder**: nếu biết đang cùng model → **DỪNG báo người dùng** đổi model/CLI trước khi kiểm duyệt.

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
5. Sửa trên nhánh `master2` / `master3`, hoặc nhánh không tách đúng gốc theo `AGENTS.md` Luật 6, hoặc có chỉnh sửa/lộ connection string trong `appsettings*.json` / `Web.config` / `.env`.
6. *(Lưu ý cho chính Tester)* **KHÔNG đọc** `appsettings*.json` trừ khi người dùng cho phép; nếu được phép chạy SQL thì **CHỈ chạy lệnh đọc (`SELECT`)**; **KHÔNG BAO GIỜ chạy `git push`.**
7. **Kiến thức áp dụng** (mục 7 `PLAN.md`): code lệch mẫu `P` đã gắn mà **không có lý do trong `CODER_NOTES.md`**, hoặc mắc đúng lỗi `X` đã gắn, hoặc trái quy tắc `D` → **FAIL**. Bước ngoài khuôn không được ghi trong `CODER_NOTES.md` → ghi lỗi để Coder bổ sung.
8. **Bước `[super]`**: code thực tế phải **khớp 100%** bản vá trong `PLAN.md`; lệch mà không được người dùng duyệt → **FAIL**. Đồng thời vẫn soi chính bản vá (bản vá sai thì code sai theo) — phát hiện lỗi trong bản vá → ghi rõ để Planner sửa plan.

### Cổng 3 — Cross-Check `git diff` vs Script SQL (Chống sót khi lên Prod)
Đọc toàn bộ thay đổi ở Model / Entity / DTO / Query / lời gọi Stored Procedure trong `git diff` và đối chiếu 1–1 với `tasks/<task>/DEPLOY_CHECKLIST.md`:
1. Code có đọc/ghi **cột mới** hoặc **bảng mới** nào không? → Phải có file `01_table_*.sql` (idempotent).
2. Code có dùng **index / constraint** mới không? → Phải có `02_index_*.sql`.
3. Code có gọi **sto / function / view mới** hoặc **đổi tham số / kiểu trả về** không? → Phải có `03_*.sql` / `04_deploy_*.sql` riêng cho từng version áp dụng.
4. So sánh `04_deploy_v2.sql` với `before_v2.sql` và `04_deploy_v3.sql` với `before_v3.sql`: đảm bảo **chỉ sửa đúng đoạn theo `PLAN.md`**, không làm mất bất kỳ đoạn logic cũ/riêng nào của đồng nghiệp ở v2 hoặc v3.
5. Code có dùng **key cấu hình / dữ liệu seed** mới không? → Phải có `05_seed_*.sql`.
5b. Có cột / index / seed / sto **mới** → Phải có `99_rollback_*.sql` tương ứng; cột mới phải `NULL` hoặc có `DEFAULT` (tương thích ngược khi DB chạy trước code).
6. **Thiếu bất kỳ 1 script nào hoặc sai thứ tự chạy (1→5) → FAIL NGAY.**

### Cổng 4 — Chạy Test nghiệm thu theo Test Plan (Orca Browser qua `orca` CLI — hỗ trợ đa tab)
> Chỉ chạy E2E trên app `dotnet watch run` đang trỏ DB Dev/Test (tuyệt đối không tạo dữ liệu test rác lên DB Production).

0. **Chờ người dùng chạy script SQL trên DB Dev/Test (BẮT BUỘC nếu task có script SQL):**
   - AI **KHÔNG tự chạy** script. Liệt kê cho người dùng danh sách script cần chạy theo đúng thứ tự **1 → 5** cho version đang test (vd: `01_table_v3.sql` → `02_index_v3.sql` → `03_func_view_v3.sql` → `04_deploy_v3.sql` → `05_seed_v3.sql`, bỏ qua file "Không có").
   - **DỪNG LẠI** chờ người dùng báo: *"đã chạy xong script trên DB Dev"*.
   - Nếu người dùng báo script **lỗi** khi chạy → ghi lỗi vào `TEST_REPORT.md`, kết luận **FAIL**, trả về Coder sửa script. Không test tiếp.
   - Chỉ khi người dùng xác nhận chạy **thành công** mới bắt đầu test UI bên dưới. Task không có script SQL thì bỏ qua bước này.

0b. **Kịch bản E2E dùng lại & case tái hiện bug:**
   - Người dùng **tự đăng nhập** tab Orca bằng tài khoản test; AI không lưu mật khẩu.
   - Chạy các kịch bản `E/F` ghi ở mục 9 `PLAN.md` (đọc tại `KNOWLEDGE_ROOT/e2e/`) + case mới của task. Có `BUG_REPORT.md` → **bắt buộc** chạy lại các bước tái hiện, tín hiệu đỏ phải **không còn**.
   - Định vị phần tử theo `id` / nhãn ghi trong kịch bản, lấy ref mới bằng `orca snapshot` mỗi lần (không dùng ref cũ).
   - Sau khi chạy: **chỉ thêm dòng** `Lịch sử chạy` vào từng kịch bản (ngày, task, version, kết quả). Giao diện đổi làm kịch bản sai → ghi chú dòng đó + tạo nháp cập nhật trong `KNOWLEDGE_ROOT/_proposed/` (không tự sửa nội dung kịch bản chính thức).

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
     - `Commit` (`rich_text`): `<commit_id>` nếu đã commit; nếu chưa commit (thường gặp vì người dùng commit sau Gate 2) → ghi `Chưa commit` và nhắc người dùng cập nhật sau khi commit
     - `Ngày` (`date`): ngày hiện tại (`YYYY-MM-DD`)
     - `Chi tiết SQL` (`rich_text`): ghi tóm tắt chuẩn để nhìn thẳng ngoài bảng (không cần mở trang):
       - Mục **`Sửa STO:`** → **chỉ liệt kê tên các Stored Procedure / View / Function** (mỗi tên 1 dòng, vì nội dung sto dài).
       - Mục **`Thêm cột:`** (nếu có) → **dán thẳng đầy đủ lệnh `IF COL_LENGTH(...) BEGIN ALTER TABLE ... ADD ... END;`** (idempotent) để copy chạy luôn.
       - Mục **`Index / Seed:`** (nếu có) → dán thẳng lệnh ngắn gọn tương ứng.
   - Bên trong nội dung trang Notion đó, chèn đầy đủ:
     - Checklist thứ tự chạy **1 → 5** tách riêng `master3` và `master2` (dạng to-do checkbox).
     - Các **SQL Code Block** (hoặc đường dẫn file `01_...` → `05_...`) để người dùng copy 1 click dán vào SSMS.
     - **Bản sao lưu rollback:** nội dung đầy đủ `snapshots/before_v2.sql`, `snapshots/before_v3.sql` và `99_rollback_*.sql` dạng code block (vì `tasks/` bị ẩn khỏi git, chỉ nằm trên máy cá nhân).
     - Nhắc bước **Pre-Deploy Check**: xuất lại sto trên Prod, so với `before_*.sql`, khác thì dừng.
   - Gắn link trang Notion vừa tạo vào cuối `TEST_REPORT.md`.
   - **Sau khi người dùng commit** (người dùng báo *"đã commit"* trong phiên Tester): đọc `git log -1 --format=%H` trên nhánh đang kiểm tra và **cập nhật cột `Commit`** trên Notion (thay `Chưa commit`). Người dùng chỉ còn tự đổi `Trạng thái` khi đã chạy Prod.
   - *(Nếu MCP `notion` đang tắt/lỗi mạng: báo rõ lý do và nhắc người dùng copy thủ công `DEPLOY_CHECKLIST.md` lên Notion).*
3. Dừng lại chờ người dùng duyệt **Gate 2**.
4. Sau Gate 2 của nhánh cuối (task có port → sau khi nhánh port cũng PASS): nhắc người dùng chạy skill `retro-task` để chấm điểm 1–5 (có thể bỏ qua).
