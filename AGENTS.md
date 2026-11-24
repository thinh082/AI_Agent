# AGENTS.md — Quy trình AI Agent chuẩn (Dự án song song master2 / master3 + SQL Server)

> File này là **luật cứng** áp dụng cho mọi AI Agent (Planner, Coder, Porter, Tester/Reviewer) trên dự án này. Vi phạm bất kỳ luật **Zero-Tolerance** nào = **FAIL ngay lập tức**.

---

## 1. Bối cảnh dự án & Tech Stack
- Dự án lớn (**> 500 file mỗi version**), chạy song song **2 version**: `master2` (v2 — khách hàng cũ) và `master3` (v3 — khách hàng mới).
- Thông thường 1 task áp dụng cho **cả 2 nhánh** (sửa 1 nhánh trước, commit lấy `<commit_id>`, rồi port sang nhánh còn lại), trừ khi ticket ghi rõ chỉ custom riêng 1 nhánh.
- **Tech Stack:** ASP.NET Core MVC (.NET 7) + HTML / CSS / JavaScript (Bootstrap) + **SQL Server 2017** *(chỉ dùng cú pháp T-SQL tương thích SQL Server 2017 — cấm dùng hàm chỉ có ở bản 2019/2022+ như `GREATEST`, `LEAST`, `GENERATE_SERIES`)*.
- **Database:** SQL Server 2017 (`master2` và `master3`). Stored Procedure / View / Function **không nằm trong git** và đồng nghiệp có thể sửa trực tiếp trên DB mà không ghi chú.
- **Môi trường chạy dev:** Người dùng **100% build/chạy bằng `dotnet watch run`**. AI **KHÔNG tự ý chạy `dotnet build` / `dotnet run`** trừ khi người dùng yêu cầu rõ (tránh chậm và xung đột lock file).

---

## 2. Phân tách vai trò (Role Separation — Linh hoạt CLI & Model)
Không để 1 phiên AI vừa tự nghĩ, vừa tự code, vừa tự test. **Người dùng tự chọn CLI (`agy`, `codex`, ...) và model tùy thời điểm** (không gán cứng hãng/tên model):

| Vai trò | Skill tương ứng | Cách vận hành thực tế | Quyền hạn |
|---|---|---|---|
| **Planner** | `.agents/skills/plan-task/SKILL.md` | **Phiên chuyên trách cố định** (nạp context 1 lần, 100% phiên đó chỉ lên plan) | **Read-only** — chỉ đọc code, Graphify, snapshot SQL, viết `PLAN.md` |
| **Coder** | `.agents/skills/implement-plan/SKILL.md` | Phiên riêng (đổi model/CLI linh hoạt theo thời điểm) | Ghi code đúng theo `PLAN.md` đã duyệt, sinh script SQL tách v2/v3 |
| **Porter** | `.agents/skills/port-version/SKILL.md` | Phiên riêng (đổi model/CLI linh hoạt) | Chuyển thay đổi từ `<commit_id>` giữa `master2` ↔ `master3` an toàn |
| **Tester / Reviewer** | `.agents/skills/verify-task/SKILL.md` | **Context mới** (ưu tiên khác model với Coder để soi khách quan) | **Read + Test** — soi `git diff`, test UI trên Orca browser qua `orca` CLI, check SQL, đẩy Notion |

---

## 3. Sáu Luật Zero-Tolerance (Cấm tuyệt đối)

### Luật 1 — Cấm làm mất code của đồng nghiệp (Patch-Only + Deleted-Lines Audit)
- Coder **CHỈ ĐƯỢC sửa đúng đoạn liên quan** theo `PLAN.md` (patch cục bộ). **CẤM viết lại / ghi đè nguyên file**.
- **CẤM tự ý xóa, dọn dẹp, hoặc refactor** hàm/logic không nằm trong `PLAN.md` (kể cả khi thấy trông "lạ" hoặc "dư" — đó có thể là code đồng nghiệp vừa thêm cho case khác).
- Trước khi kết thúc task, Tester **BẮT BUỘC** đọc toàn bộ các dòng bị xóa (`-`) trong `git diff`: bất kỳ hàm/logic nào bị xóa mà không ghi rõ trong `PLAN.md` → **FAIL ngay**.

### Luật 2 — Cấm đoán mò (No Guessing — Stop & Ask)
- **KHÔNG BAO GIỜ** tự bịa tên cột DB, `id`/`name` HTML, tên tham số sto, hoặc mã nghiệp vụ.
- Nếu phát hiện tên cột DB và `id`/`name` trên UI/HTML hoặc DTO **không khớp nhau** → **DỪNG LẠI**, liệt kê bảng mapping đang lệch và **hỏi người dùng xác nhận** ngay ở bước Planner.

### Luật 3 — Cấm Silent Fallback tên trường
- **TUYỆT ĐỐI CẤM** viết chuỗi fallback chữa cháy kiểu `data.ColA ?? data.colA ?? data.a ?? ""` khi không chắc tên cột/biến.
- Mỗi trường chỉ được dùng **đúng 1 tên chính xác** đã kiểm chứng từ file code và schema thật.

### Luật 4 — Fail-Fast: Cấm gán giá trị nghiệp vụ mặc định ở `else` / `default`
- Với mọi nhánh `if / else if` hoặc `switch` mapping trạng thái/mã (đặc biệt khi lưu DB hoặc gửi sang **cổng thông tin / API đối tác**):
  - Nhánh `else` / `default` **BẮT BUỘC phải báo lỗi / throw exception / chặn gửi** kèm giá trị không hợp lệ.
  - **TUYỆT ĐỐI KHÔNG** gán mặc định một mã nghiệp vụ hợp lệ (ví dụ: `else { code = "B"; }`), trừ khi người dùng duyệt rõ ràng trong `PLAN.md`.

### Luật 5 — Bảo mật cấu hình SQL (`appsettings`) & Chỉ được ĐỌC DB khi được phép
- **TUYỆT ĐỐI CẤM** tự ý đọc `appsettings.json`, `appsettings.*.json`, `Web.config`, `.env`, hoặc bất kỳ file nào chứa connection string / mật khẩu SQL **trừ khi người dùng cho phép rõ ràng** trong phiên làm việc đó.
- **Kể cả khi được người dùng cho phép** đọc/truy vấn SQL: AI **CHỈ ĐƯỢC chạy lệnh ĐỌC (read-only)** như `SELECT`, `OBJECT_DEFINITION`, `sp_helptext`, metadata query. **TUYỆT ĐỐI CẤM** chạy `INSERT`, `UPDATE`, `DELETE`, `ALTER`, `CREATE`, `DROP`, `TRUNCATE`, hay `EXEC` làm thay đổi dữ liệu/schema.

### Luật 6 — An toàn Git: Cấm `git push` & Cấm code trực tiếp trên `master2` / `master3`
- **TUYỆT ĐỐI CẤM** AI chạy `git push` (dưới mọi hình thức, kể cả `push`, `push -u`, `push --force`). Việc push và tạo PR/MR **chỉ do con người thực hiện**.
- **CẤM sửa code hoặc commit trực tiếp trên nhánh `master2` hoặc `master3`**.
- Trước khi sửa bất kỳ file nào, bắt buộc phải **tách nhánh mới (branch off)** từ `master2` hoặc `master3` (ví dụ: `feat/<TASK_ID>-v3` từ `master3`, `feat/<TASK_ID>-v2` từ `master2`). Nếu `git branch --show-current` là `master2` hoặc `master3` → **DỪNG NGAY**, tách nhánh mới rồi mới làm.

---

## 4. Luật bắt buộc cho SQL Server (Chống ghi đè logic sto & sót script Prod)
1. **Đủ 2 bản hiện tại (Dual Snapshot):** Nếu task sửa sto/view/function chạy trên cả 2 version, **BẮT BUỘC** phải đưa cho AI cả 2 bản đang chạy thật trên SSMS: `before_v2.sql` (từ `master2`) và `before_v3.sql` (từ `master3`). Thiếu 1 trong 2 → **Planner từ chối lên plan**.
2. **So sánh (Diff) & Giữ nguyên logic riêng:** Planner bắt buộc đối chiếu `before_v2.sql` vs `before_v3.sql` để chỉ ra các đoạn logic đồng nghiệp đã thêm ở từng version; Coder chỉ sửa đúng đoạn cần thiết, **tuyệt đối không xóa/ghi đè logic cũ** trong sto.
3. **Tách script theo version:** Không bao giờ dùng chung 1 file `ALTER PROCEDURE` cho cả `master2` và `master3`. Luôn tạo riêng `04_deploy_v2.sql` (sửa trên nền `before_v2.sql`) và `04_deploy_v3.sql` (sửa trên nền `before_v3.sql`). File `before_v2.sql` / `before_v3.sql` chính là bản rollback.
4. **Thứ tự chạy chuẩn trên Prod** trong `DEPLOY_CHECKLIST.md`:
   `1. Table / Column (ALTER TABLE)` → `2. Index / Constraint` → `3. Function / View` → `4. Stored Procedure` → `5. Seed / Config Data (idempotent)`.
5. **AI không bao giờ chạy SQL ghi/ALTER lên DB Production.** Con người tự chạy sau khi duyệt.

---

## 5. Luật dùng Graphify (Bản đồ kiến trúc tách riêng v2 / v3)
- Tạo mới / cập nhật bản đồ dự án bằng skill `.agents/skills/map-project/SKILL.md`:
  - Tự động kiểm tra nhánh hiện tại tách từ `master2` hay `master3` (nếu không rõ → **dừng báo người dùng**, cấm ghi lộn version).
  - Lưu tách riêng vào `graphify-out/master2/` và `graphify-out/master3/` (tự ẩn `graphify-out/` trong `.git/info/exclude`, không đụng `.gitignore` công ty).
- Dùng Graphify (`graphify-out/<master2|master3>/graph.json`, `GRAPH_REPORT.md`) ở bước **Planner** để tra nhanh call graph và blast radius.
- **Graphify có thể cũ** so với code vừa `git pull`: chỉ dùng để *định vị nhanh*, trước khi kết luận hoặc sửa **luôn mở file thật trên máy để xác nhận**.

---

## 6. Cổng duyệt của con người (Human Gates)
- **Gate 1:** Người dùng duyệt `PLAN.md` → Coder mới được viết code.
- **Gate 2:** Người dùng duyệt `TEST_REPORT.md` + `DEPLOY_CHECKLIST.md` + `git diff` → mới merge & deploy.
- **Task chưa coi là DONE** nếu chưa có `DEPLOY_CHECKLIST.md` đã cross-check với `git diff` (và đồng bộ lên Online Docs qua MCP nếu đã cấu hình).
