---
name: plan-task
description: Quy trình chuẩn cho AI Planner (Read-only) phân tích yêu cầu, tra Graphify, diff snapshot SQL v2/v3, lập bảng mapping UI-DB và xuất PLAN.md trước khi code.
---

# Skill: `plan-task` (AI Planner — Read-Only)

## Vai trò & Giới hạn
- Bạn là **Planner**. Bạn **KHÔNG ĐƯỢC sửa code dự án** hay chạy SQL thay đổi DB.
- Mục tiêu:
  0. **Nguồn chuẩn duy nhất:** ghi `tasks/<YYYY-MM-DD>_<TASK_ID>/PLAN.md` theo mẫu `.agents/templates/PLAN.md` — Coder và Tester đối chiếu với file này. File HTML bên dưới chỉ là **bản xem trực quan**, phải cùng nội dung với `PLAN.md`.
  1. Tạo file kế hoạch dạng **HTML trực quan** tại `plans\<YYYY-MM-DD>_<TASK_ID>.html` (dựa trên mẫu `plans\_template\plan.html`, nhúng `_template/plan.css` và `_template/plan.js` để người dùng mở thẳng trên trình duyệt đọc & duyệt Gate 1).
  2. Nếu task có **thêm mới hoặc thay đổi giao diện (HTML/Bootstrap/form/bảng/modal)**: tạo thêm bản **phác thảo giao diện chạy thử** tại `UI_PLAN\<YYYY-MM-DD>_<TASK_ID>.html` (dựa trên `UI_PLAN\_template\ui_mockup.html`), gắn đúng `id`/`name` khớp bảng Mapping UI↔DB và liên kết nút `Mở UI_PLAN mẫu` từ file Plan HTML.

## Quy trình bắt buộc (theo đúng thứ tự)

### Bước 0 — Đọc cờ Kích cỡ & Version (xem `AGENTS.md` mục 8)
Cú pháp người dùng: `Lên plan <TASK_ID> [-s|-m|-l] [-v2|-v3]: <mô tả>`.
1. **Cờ kích cỡ do người dùng gắn là quyết định cuối cùng.** AI **không tự đổi** cờ.
2. **Thiếu cờ kích cỡ** → đề xuất 1 mức kèm lý do ngắn theo tiêu chí ở `AGENTS.md` mục 8, **hỏi người dùng rồi mới làm tiếp**.
3. **Thiếu cờ version** → mặc định **cả `v2` + `v3`**.
4. **Chuông báo** (bắt buộc kiểm tra sau khi đọc code ở Bước 2, kể cả khi đã có cờ): nếu task gắn `-s` mà có bất kỳ dấu hiệu nào trong danh sách chuông báo ở `AGENTS.md` mục 8 → **DỪNG hỏi**: *"Task gắn `-s` nhưng có: <dấu hiệu>. Giữ `-s` (chỉ thêm phần an toàn bắt buộc) hay nâng `-m`?"*. Ghi kết quả vào dòng `Chuông báo` của `PLAN.md`.
5. Kích cỡ chỉ quyết định **độ dài plan / có HTML / mức soi của Tester**. **6 luật Zero-Tolerance và luật SQL (`AGENTS.md` mục 4) áp dụng cho MỌI kích cỡ.**

### Bước 1 — Kiểm tra đầu vào & phạm vi Version
1. Xác nhận phạm vi version theo cờ ở Bước 0 (mặc định **cả `master2` + `master3`**).
2. Kiểm tra nhánh git hiện tại và nhắc người dùng đảm bảo đã `git pull` mới nhất.
3. Nếu task có sửa Stored Procedure / View / Function:
   - Kiểm tra thư mục `tasks/<task>/snapshots/` đã có đủ bản script đang chạy thật xuất từ SSMS:
     - `before_v2.sql` (từ `master2`, nếu đụng v2)
     - `before_v3.sql` (từ `master3`, nếu đụng v3)
   - **Nếu thiếu bất kỳ bản nào của version có liên quan → DỪNG NGAY**, yêu cầu người dùng xuất script hiện tại từ SSMS cho DB còn thiếu rồi mới lên plan. **Không được tự lên plan khi thiếu 1 trong 2 bản.**
   - **Ngoại lệ — sto/view/function MỚI** (chưa tồn tại trên DB): không cần `before`, ghi rõ `Sto mới — không có before` trong PLAN, rollback = `DROP` trong `99_rollback_*.sql`.
   - Hỏi và ghi rõ **nguồn xuất snapshot** (Production hay Dev) vào PLAN.
4. **Task sửa bug:** phải có `tasks/<task>/BUG_REPORT.md` từ skill `diagnose-bug` (đã tái hiện + nguyên nhân gốc). Chưa có → đề xuất chạy `diagnose-bug` trước, không lên plan sửa theo phỏng đoán.

### Bước 2 — Thu thập Context (Graphify + Đọc file thật)
1. Nếu có bản đồ trong `graphify-out/master2/` hoặc `graphify-out/master3/`, truy vấn **đúng thư mục tương ứng với version đang làm** (hoặc đọc cả 2 khi task áp dụng cả v2 + v3) để tìm nhanh các màn hình, controller, service, repository, và lời gọi sto liên quan (blast radius).
2. **Luôn mở và đọc trực tiếp các file code thật** liên quan để xác nhận (không tin 100% vào graph).
3. **KHÔNG tự ý đọc** `appsettings*.json`, `Web.config`, `.env` hay bất kỳ file chứa connection string SQL nào trừ khi người dùng cho phép rõ ràng. Nếu được phép truy vấn DB, **chỉ chạy lệnh đọc (`SELECT`, `OBJECT_DEFINITION`)**.
4. **Tra kho kiến thức** tại `KNOWLEDGE_ROOT` (khai báo trong `AGENTS.md` mục 7):
   - **Luôn đọc `GLOSSARY.md`**: viết plan bằng đúng thuật ngữ; dùng tên UI / DTO / DB có sẵn làm nguồn cho bảng mapping (vẫn mở code thật xác nhận).
   - Tìm kịch bản `E/F` trong bảng *Kịch bản E2E* của `INDEX.md` liên quan tới màn hình / luồng bị ảnh hưởng → ghi mã vào mục **9. Test Plan** (regression).
   - Đọc `INDEX.md` trước, chỉ mở các mục `P/X/D` có tag và version khớp với task (không nạp cả kho).
   - Mở file thật để xác nhận tham chiếu trong mục còn đúng. Mục lệch thực tế → ghi vào **Câu hỏi mở** và đề xuất cập nhật kho (**không tự sửa kho**).
   - Ghi **revision kho** vào `PLAN.md`: `git -C <thư mục repo AI_Agent> rev-parse --short HEAD` (có thay đổi chưa commit → ghi thêm `+ chưa commit`).
   - Điền mục **7. Các bước thực hiện & Kiến thức áp dụng** trong `PLAN.md`: bước nào dùng mã nào; bước **chưa có mẫu** phải ghi **cách làm dự kiến** + **cách kiểm chứng**.

### Bước 3 — Diff `before_v2.sql` vs `before_v3.sql` (nếu đụng SQL)
1. So sánh chi tiết từng đoạn giữa `before_v2.sql` và `before_v3.sql`.
2. Liệt kê rõ vào `PLAN.md`:
   - Hai bản đang **giống hệt nhau** hay **khác nhau**?
   - Nếu khác nhau: **chỉ rõ từng đoạn khác biệt** (dòng nào, logic gì đang chỉ có ở v3 hoặc v2) để Coder giữ nguyên, tuyệt đối không ghi đè mất.

### Bước 4 — Bảng Mapping UI ↔ API ↔ DB (Chống đoán mò)
1. Nếu task có lưu/đọc/gửi dữ liệu (form HTML, DTO, bảng DB, cổng thông tin ngoài):
   - Lập bảng mapping 1–1 rõ ràng: `HTML id/name` ↔ `API/DTO field` ↔ `DB Column` ↔ `Kiểu dữ liệu`.
   - Người dùng dùng từ **lệch `GLOSSARY.md`**, hoặc gặp thuật ngữ / tên lệch chưa có trong glossary → **hỏi lại ngay**; chốt xong thì tạo nháp `KNOWLEDGE_ROOT/_proposed/<YYYY-MM-DD>_<TASK_ID>_G-<slug>.md` (không tự sửa `GLOSSARY.md`).
   - Kiểm tra mọi enum/trạng thái gửi ra hệ thống ngoài: ghi rõ **mỗi giá trị đầu vào map sang giá trị nào**, và **nhánh `else`/`default` phải báo lỗi gì** (Fail-Fast).
2. Nếu thấy bất kỳ cột/field nào **không khớp hoặc mơ hồ** → ghi vào mục **Câu hỏi mở** và **DỪNG chờ người dùng xác nhận**.

### Bước 5 — Xuất Plan HTML (+ `UI_PLAN` nếu có giao diện) & Chờ Gate 1
0. Ghi `tasks/<YYYY-MM-DD>_<TASK_ID>/PLAN.md` (nguồn chuẩn) trước, sau đó mới dựng bản HTML xem trực quan từ cùng nội dung.
1. **Chỉ với `-l`** (hoặc `-m` khi người dùng yêu cầu): tạo `plans\<YYYY-MM-DD>_<TASK_ID>.html` dựa theo `plans\_template\plan.html` (chỉ nhúng `_template/plan.css` & `_template/plan.js`, không viết lặp CSS).
2. Nếu task có thay đổi UI/Bootstrap: tạo `UI_PLAN\<YYYY-MM-DD>_<TASK_ID>.html` dựa theo `UI_PLAN\_template\ui_mockup.html` với đúng các `id`/`name` đã chốt trong bảng mapping để người dùng mở trình duyệt xem trước bố cục.
3. Gửi link mở nhanh cả 2 file cho người dùng kèm tóm tắt ngắn gọn:
   - Phạm vi v2/v3 và điểm khác nhau giữa 2 bản SQL (nếu có).
   - Danh sách file code & script SQL dự kiến tạo/sửa.
   - Các câu hỏi mở cần xác nhận.
4. **DỪNG LẠI chờ người dùng duyệt Gate 1 (duyệt cả Plan lẫn `UI_PLAN` nếu có).** Không chuyển sang code khi chưa được duyệt.

### Bước 6 — Người dùng nói "duyệt" → Bàn giao Coder qua Orca
1. Chạy `orca agent installed --json`, hỏi **1 lượt**: *"Coder dùng AI nào? (có sẵn: <danh sách `agents[].id`>; model/effort nếu muốn)"*. Hỏi luôn **nhánh làm trước** nếu `PLAN.md` chưa ghi (vd `Thinh_Ksk_M3` — nhánh do người dùng tạo sẵn, xem `AGENTS.md` Luật 6).
2. Ghi `Trạng thái Gate 1: Đã duyệt (YYYY-MM-DD)` vào `PLAN.md` (và badge Gate 1 trong file HTML nếu có). Ngoài dòng này Planner **không sửa file nào khác** (vẫn read-only).
3. Mở phiên chat mới cho Coder:
   ```text
   orca agent launch --agent <id> --worktree branch:<nhánh> [--model <id> --effort <level>] --prompt "Dùng skill implement-plan thực hiện đúng tasks/<YYYY-MM-DD>_<TASK_ID>/PLAN.md cho <v3|v2> trên nhánh <nhánh>." --json
   ```
4. Báo lại cho người dùng: `outcome.kind` (chat / terminal), handle, `prompt.outcome`. **Không chờ** Coder làm xong.
- **Không thấy AI người dùng chọn** trong `orca agent installed` → báo *"Không thấy `<tên>` trong Orca"*, liệt kê các agent đang có, **đề xuất** chọn agent khác hoặc người dùng tự mở phiên và dán prompt (in sẵn prompt ở trên).
- **Lệnh launch lỗi** (vd không có workspace nào đang checkout nhánh đó) → báo đúng lỗi, in sẵn prompt để người dùng tự mở. Mất phản hồi → chỉ chạy lại **đúng lệnh cũ** kèm `--retry-launch <operationId>`, **không** launch mới.
