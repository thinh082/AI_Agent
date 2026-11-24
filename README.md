# Bộ Quy Trình AI Agent Chuẩn (v2 / v3 + SQL Server)

Bộ khung này được thiết kế cho dự án **> 500 file mỗi version**, chạy song song **2 nhánh `master2` / `master3`**, dùng **SQL Server** (sto nằm ngoài git), giải quyết dứt điểm 4 nỗi đau:
1. Ghi đè mất code sto / mất hàm của đồng nghiệp.
2. Quên note script thêm cột / thêm sto khi lên Production.
3. AI đoán mò tên cột, viết silent fallback hoặc gán mặc định bừa ở nhánh `else`.
4. Port thay đổi giữa `master3` ↔ `master2` bị sót hoặc đè logic riêng.

---

## 1. Cấu trúc bộ khung

```text
.
├── AGENTS.md                           # Luật cứng (6 luật Zero-Tolerance + Tech Stack + SQL + Graphify)
├── plans/                              # Lưu Plan dạng HTML mở trình duyệt đọc cực dễ
│   └── _template/                      # Template mẫu (plan.html, plan.css, plan.js)
├── UI_PLAN/                            # Phác thảo giao diện Bootstrap mẫu để chốt UI trước khi code
│   └── _template/                      # Khung mockup mẫu (ui_mockup.html)
└── .agents/
    ├── skills/
    │   ├── aspnet-backend/SKILL.md     # Chuẩn code backend ASP.NET Core (.NET 7) của dự án
    │   ├── map-project/SKILL.md        # Tạo / cập nhật bản đồ dự án tách v2/v3 (Graphify)
    │   ├── plan-task/SKILL.md          # AI Planner (phiên cố định) — Xuất HTML Plan + UI_PLAN
    │   ├── implement-plan/SKILL.md     # AI Coder (đổi CLI/model linh hoạt)
    │   ├── port-version/SKILL.md       # AI Porter — Chuyển <commit_id> giữa master2 <-> master3
    │   └── verify-task/SKILL.md        # AI Tester (context mới + orca CLI + Notion MCP)
    └── templates/
        ├── PLAN.md
        ├── TEST_REPORT.md
        └── DEPLOY_CHECKLIST.md
```

---

## 2. Cách mang sang dự án thật
1. Copy `AGENTS.md` và thư mục `.agents/` vào thư mục gốc repo dự án của bạn *(nếu không muốn push lên git công ty thì thêm chúng + `tasks/` + `graphify-out/` vào `.git/info/exclude` — git sẽ tự bỏ qua mà không sửa `.gitignore` chung của công ty!)*.
2. Cài **Graphify** để map codebase > 500 file:
   ```powershell
   uv tool install graphifyy
   graphify install
   ```
   Sau mỗi lần `git pull` lớn, chạy cập nhật graph để Planner tra call graph nhanh.

---

## 3. Luồng làm việc hằng ngày cho 1 Task

### Bước 1 — Lưu bản sto hiện tại (Snapshot) nếu task đụng sto
- Trên SSMS, chuột phải vào sto cần sửa → **Script Stored Procedure as → ALTER To** trên **cả `master3` và `master2`**.
- Lưu thành 2 file `tasks/<YYYY-MM-DD>_<TASK_ID>/snapshots/before_v3.sql` và `before_v2.sql` (vừa để AI so sánh v2 vs v3 tránh đè mất logic đồng nghiệp, vừa làm bản backup/rollback sẵn).

### Bước 2 — Lên Plan (Phiên Planner cố định — tùy model bạn chọn)
- Gọi skill `plan-task`:
  > *"Dùng skill `plan-task` lập plan cho task `<TASK_ID>`: `<mô tả>`. Snapshot SQL ở `tasks/.../snapshots/`."*
- **Gate 1:** Bạn đọc & duyệt `PLAN.md` (đặc biệt check mục **Diff v2 vs v3** và **Bảng Mapping UI↔DB**).

### Bước 3 — Code trên nhánh tách đầu tiên (Coder — tùy CLI/model bạn chọn)
- Tách nhánh mới từ `master3` (không sửa trực tiếp trên `master3`):
  ```powershell
  git checkout master3 && git pull
  git checkout -b feat/<TASK_ID>-v3
  ```
- Gọi skill `implement-plan`:
  > *"Dùng skill `implement-plan` thực hiện đúng theo `tasks/.../PLAN.md`."*
- Coder sửa code (patch-only) + sinh script SQL tách riêng v2/v3 + tạo `DEPLOY_CHECKLIST.md`. *(AI không tự chạy `dotnet build`, bạn check nhanh terminal `dotnet watch run`; AI bị cấm `git push` và cấm đọc `appsettings` khi chưa được phép).*

### Bước 4 — Test & Audit (Context mới — tùy model bạn chọn)
- Mở phiên mới, gọi skill `verify-task`:
  > *"Dùng skill `verify-task` kiểm duyệt `tasks/.../PLAN.md` và `git diff` hiện tại."*
- Tester soi **100% dòng bị xóa**, quét **6 luật Zero-Tolerance**, **Cross-Check `git diff` vs Script SQL**, test UI trên tab Orca bằng **`orca` CLI**, rồi đẩy `DEPLOY_CHECKLIST.md` lên Notion (`Release DB Scripts`).
- **Gate 2:** Bạn duyệt → **bạn tự** `git commit` & `git push` nhánh `feat/<TASK_ID>-v3` → lấy `<commit_id>`.

### Bước 5 — Port sang nhánh tách từ `master2` (`master3` ↔ `master2`)
- Tách nhánh mới từ `master2` (không sửa trực tiếp trên `master2`):
  ```powershell
  git checkout master2 && git pull
  git checkout -b feat/<TASK_ID>-v2
  ```
- Gọi skill `port-version`:
  > *"Dùng skill `port-version` chuyển thay đổi từ commit `<commit_id>` sang nhánh hiện tại theo `tasks/.../PLAN.md`."*
- Chạy lại `verify-task` trên nhánh `feat/<TASK_ID>-v2` → **bạn tự** commit & push.

### Bước 6 — Lên Production
- Mở bảng **`Release DB Scripts`** trên Notion (lọc `Trạng thái != Done`), chạy script theo đúng thứ tự **1 → 5** cho `master3` rồi `master2`.
- Nếu có sự cố cần quay lui, chạy lại file `snapshots/before_v3.sql` hoặc `before_v2.sql` đã lưu sẵn.

---

## 4. Gợi ý gắn MCP Server cho Online Docs
- **Khuyên dùng Notion MCP**: Tạo 1 Notion Database tên `Release DB Scripts` với các cột:
  - `Task ID` (Title)
  - `Version` (Multi-select: `v2`, `v3`)
  - `Status` (Select: `Chưa chạy Prod`, `Đã chạy v3`, `Đã chạy v2`, `Done`)
  - `Date` (Date)
- Khi đó trong `verify-task`, AI Tester chỉ cần gọi Notion MCP tạo 1 page mới trong Database đó với nội dung `DEPLOY_CHECKLIST.md`. Trước giờ lên Prod, bạn lọc `Status != Done` là thấy đủ 100% script cần chạy, không bao giờ sót.
