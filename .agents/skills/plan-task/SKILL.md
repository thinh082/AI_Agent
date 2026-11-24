---
name: plan-task
description: Quy trình chuẩn cho AI Planner (Read-only) phân tích yêu cầu, tra Graphify, diff snapshot SQL v2/v3, lập bảng mapping UI-DB và xuất PLAN.md trước khi code.
---

# Skill: `plan-task` (AI Planner — Read-Only)

## Vai trò & Giới hạn
- Bạn là **Planner**. Bạn **KHÔNG ĐƯỢC sửa code dự án** hay chạy SQL thay đổi DB.
- Mục tiêu:
  1. Tạo file kế hoạch dạng **HTML trực quan** tại `D:\Project\AI_Agent\plans\<YYYY-MM-DD>_<TASK_ID>.html` (dựa trên mẫu `D:\Project\AI_Agent\plans\_template\plan.html`, nhúng `_template/plan.css` và `_template/plan.js` để người dùng mở thẳng trên trình duyệt đọc & duyệt Gate 1).
  2. Nếu task có **thêm mới hoặc thay đổi giao diện (HTML/Bootstrap/form/bảng/modal)**: tạo thêm bản **phác thảo giao diện chạy thử** tại `D:\Project\AI_Agent\UI_PLAN\<YYYY-MM-DD>_<TASK_ID>.html` (dựa trên `D:\Project\AI_Agent\UI_PLAN\_template\ui_mockup.html`), gắn đúng `id`/`name` khớp bảng Mapping UI↔DB và liên kết nút `Mở UI_PLAN mẫu` từ file Plan HTML.

## Quy trình bắt buộc (theo đúng thứ tự)

### Bước 1 — Kiểm tra đầu vào & phạm vi Version
1. Xác nhận task áp dụng cho **cả `master2` + `master3`** (mặc định) hay chỉ **1 version riêng**.
2. Kiểm tra nhánh git hiện tại và nhắc người dùng đảm bảo đã `git pull` mới nhất.
3. Nếu task có sửa Stored Procedure / View / Function:
   - Kiểm tra thư mục `tasks/<task>/snapshots/` đã có đủ bản script đang chạy thật xuất từ SSMS:
     - `before_v2.sql` (từ `master2`, nếu đụng v2)
     - `before_v3.sql` (từ `master3`, nếu đụng v3)
   - **Nếu thiếu bất kỳ bản nào của version có liên quan → DỪNG NGAY**, yêu cầu người dùng xuất script hiện tại từ SSMS cho DB còn thiếu rồi mới lên plan. **Không được tự lên plan khi thiếu 1 trong 2 bản.**

### Bước 2 — Thu thập Context (Graphify + Đọc file thật)
1. Nếu có bản đồ trong `graphify-out/master2/` hoặc `graphify-out/master3/`, truy vấn **đúng thư mục tương ứng với version đang làm** (hoặc đọc cả 2 khi task áp dụng cả v2 + v3) để tìm nhanh các màn hình, controller, service, repository, và lời gọi sto liên quan (blast radius).
2. **Luôn mở và đọc trực tiếp các file code thật** liên quan để xác nhận (không tin 100% vào graph).
3. **KHÔNG tự ý đọc** `appsettings*.json`, `Web.config`, `.env` hay bất kỳ file chứa connection string SQL nào trừ khi người dùng cho phép rõ ràng. Nếu được phép truy vấn DB, **chỉ chạy lệnh đọc (`SELECT`, `OBJECT_DEFINITION`)**.

### Bước 3 — Diff `before_v2.sql` vs `before_v3.sql` (nếu đụng SQL)
1. So sánh chi tiết từng đoạn giữa `before_v2.sql` và `before_v3.sql`.
2. Liệt kê rõ vào `PLAN.md`:
   - Hai bản đang **giống hệt nhau** hay **khác nhau**?
   - Nếu khác nhau: **chỉ rõ từng đoạn khác biệt** (dòng nào, logic gì đang chỉ có ở v3 hoặc v2) để Coder giữ nguyên, tuyệt đối không ghi đè mất.

### Bước 4 — Bảng Mapping UI ↔ API ↔ DB (Chống đoán mò)
1. Nếu task có lưu/đọc/gửi dữ liệu (form HTML, DTO, bảng DB, cổng thông tin ngoài):
   - Lập bảng mapping 1–1 rõ ràng: `HTML id/name` ↔ `API/DTO field` ↔ `DB Column` ↔ `Kiểu dữ liệu`.
   - Kiểm tra mọi enum/trạng thái gửi ra hệ thống ngoài: ghi rõ **mỗi giá trị đầu vào map sang giá trị nào**, và **nhánh `else`/`default` phải báo lỗi gì** (Fail-Fast).
2. Nếu thấy bất kỳ cột/field nào **không khớp hoặc mơ hồ** → ghi vào mục **Câu hỏi mở** và **DỪNG chờ người dùng xác nhận**.

### Bước 5 — Xuất Plan HTML (+ `UI_PLAN` nếu có giao diện) & Chờ Gate 1
1. Tạo `D:\Project\AI_Agent\plans\<YYYY-MM-DD>_<TASK_ID>.html` dựa theo `D:\Project\AI_Agent\plans\_template\plan.html` (chỉ nhúng `_template/plan.css` & `_template/plan.js`, không viết lặp CSS).
2. Nếu task có thay đổi UI/Bootstrap: tạo `D:\Project\AI_Agent\UI_PLAN\<YYYY-MM-DD>_<TASK_ID>.html` dựa theo `D:\Project\AI_Agent\UI_PLAN\_template\ui_mockup.html` với đúng các `id`/`name` đã chốt trong bảng mapping để người dùng mở trình duyệt xem trước bố cục.
3. Gửi link mở nhanh cả 2 file cho người dùng kèm tóm tắt ngắn gọn:
   - Phạm vi v2/v3 và điểm khác nhau giữa 2 bản SQL (nếu có).
   - Danh sách file code & script SQL dự kiến tạo/sửa.
   - Các câu hỏi mở cần xác nhận.
4. **DỪNG LẠI chờ người dùng duyệt Gate 1 (duyệt cả Plan lẫn `UI_PLAN` nếu có).** Không chuyển sang code khi chưa được duyệt.
