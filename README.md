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
├── setup.ps1                           # Nối quy trình vào dự án (junction + AGENTS.md + exclude)
├── map.ps1                             # Dựng / cập nhật bản đồ Graphify code-only (không tốn token)
├── check.ps1                           # Kiểm tra máy móc 1 task (nhánh, file ngoài plan, SQL cấm, cặp script, dòng bị xóa)
├── docs/HUONG_DAN.pdf                  # Hướng dẫn sử dụng (bản gốc: docs/HUONG_DAN.html)
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
    │   ├── verify-task/SKILL.md        # AI Tester (context mới + orca CLI + Notion MCP)
    │   ├── update-plan/SKILL.md        # Cập nhật plan giữa chừng (Rev mới, duyệt lại phần đổi)
    │   ├── ask-map/SKILL.md            # Hỏi nhanh: endpoint này gọi sto nào / sto này gọi ở đâu
    │   ├── wait-what/SKILL.md          # Bắt AI nói lại ngắn gọn bằng thuật ngữ GLOSSARY
    │   ├── diagnose-bug/SKILL.md       # Task sửa bug: tái hiện trên Orca + tìm nguyên nhân gốc trước khi plan
    │   ├── add-knowledge/SKILL.md      # Nạp kiến thức mới + duyệt kho nháp
    │   └── retro-task/SKILL.md         # Chấm điểm 1–5 sau task + tổng kết vai trò × model
    ├── knowledge/                      # KHO KIẾN THỨC (KNOWLEDGE_ROOT — chỉ nằm ở repo này)
    │   ├── INDEX.md                    # Mục lục, AI đọc trước
    │   ├── GLOSSARY.md                 # Thuật ngữ chung (UI / DTO / DB v2 / v3) — mọi vai trò đọc mỗi task
    │   ├── e2e/                        # E### / F### kịch bản test Orca dùng lại
    │   ├── patterns/ pitfalls/ domain/ # P### mẫu nên làm · X### lỗi cấm lặp · D### nghiệp vụ
    │   ├── _proposed/                  # Nháp do AI đề xuất, chờ bạn duyệt
    │   ├── _templates/ENTRY.md         # Khuôn 1 mục kiến thức
    │   └── retro/RETRO_LOG.md          # Nhật ký điểm từng task
    └── templates/
        ├── PLAN.md
        ├── TEST_REPORT.md
        └── DEPLOY_CHECKLIST.md
```

---

## 2. Cách mang sang dự án thật
1. Clone repo `AI_Agent` về máy, rồi chạy **1 lệnh** trong PowerShell (tại thư mục `AI_Agent`):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup.ps1 -HisPath D:\Code\HIS
   ```
   - Tạo **junction** `.agents\skills`, `.agents\templates`, `plans\_template`, `UI_PLAN\_template` trong dự án trỏ về `AI_Agent` (sửa skill ở `AI_Agent` là dự án dùng bản mới ngay).
   - Copy `AGENTS.md` vào dự án và tự sửa `KNOWLEDGE_ROOT` theo vị trí `AI_Agent` trên máy đó.
   - Thêm `AGENTS.md`, `.agents/`, `plans/`, `UI_PLAN/`, `tasks/`, `graphify-out/` vào `.git/info/exclude` (không sửa `.gitignore` công ty).
   - Chạy lại bao nhiêu lần cũng được; không ghi đè thư mục/file thật, không đụng `AGENTS.md` nếu git công ty đang theo dõi file đó.
   - Sửa luật trong `AGENTS.md` xong → chạy lại với `-Update` để copy lại.
   - Mở **phiên mới** của CLI để kiểm tra skill (Codex: `/skills` hoặc `$ask-map`; Antigravity: `/ask-map`). **Không đặt tên skill là `learn`** — trùng lệnh có sẵn `/learn` của Antigravity.
2. Cài **Graphify** để map codebase > 500 file:
   ```powershell
   uv tool install graphifyy
   graphify install
   ```
   Dựng / cập nhật bản đồ **không tốn token AI** (code-only, không gọi model), tự nhận v2/v3 theo nhánh đang đứng:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\map.ps1 -HisPath D:\Code\HIS          # cập nhật (graphify update)
   powershell -ExecutionPolicy Bypass -File .\map.ps1 -HisPath D:\Code\HIS -Full    # dựng lại toàn bộ
   ```
   Không cần chạy sau mỗi `git pull`: AI luôn mở file thật để xác nhận; chạy khi tiện (vd đầu tuần, sau khi đổi nhánh M2 ↔ M3).

---

## 3. Luồng làm việc hằng ngày cho 1 Task

### Bước 1 — Lưu bản sto hiện tại (Snapshot) nếu task đụng sto
- Trên SSMS, chuột phải vào sto cần sửa → **Script Stored Procedure as → ALTER To** trên **cả `master3` và `master2`** — **lấy từ DB Production** (DB sẽ deploy thật). Sto mới chưa tồn tại thì không cần snapshot.
- ⚠️ `tasks/` bị ẩn khỏi git nên chỉ nằm trên máy bạn — bản snapshot sẽ được Tester đẩy kèm lên Notion làm bản sao lưu.
- Lưu thành 2 file `tasks/<YYYY-MM-DD>_<TASK_ID>/snapshots/before_v3.sql` và `before_v2.sql` (vừa để AI so sánh v2 vs v3 tránh đè mất logic đồng nghiệp, vừa làm bản backup/rollback sẵn).
- **Lười tạo file?** Dán thẳng code sto vào chat Planner, ghi `v3:` / `v2:` trước mỗi khối → Planner tự kiểm tra đủ (không bị cắt) và lưu nguyên văn vào `snapshots/`.

### Bước 2 — Lên Plan (Phiên Planner cố định — tùy model bạn chọn)
- **Task sửa bug:** chạy trước *"Dùng skill `diagnose-bug` cho bug `<TASK_ID>`: `<mô tả>`"* → AI tái hiện trên Orca, tìm nguyên nhân gốc, ghi `BUG_REPORT.md` → rồi mới lên plan.
- Gọi skill `plan-task`:
  > *"Dùng skill `plan-task`: Lên plan `<TASK_ID>` `-s|-m|-l` `[-v2|-v3]`: `<mô tả>`. Snapshot SQL ở `tasks/.../snapshots/`."*
  - Chọn model theo rủi ro (`AGENTS.md` mục 9): task `-s` dùng combo tiết kiệm; có STO / chuông báo → Planner mạnh; `-l` / tiền / BHYT → combo mạnh. Coder bị FAIL 2 lần → mở phiên Coder mới hạng mạnh (leo thang). Planner ghi `Combo gợi ý` vào plan.
  - `+super` chia **lô 3–5 bước**: Planner giao Lô 1, Coder xong báo → bạn gõ *"lô tiếp"* trong phiên Planner → Planner mở phiên Coder mới cho lô sau.
  - Coder là model nhanh / yếu → thêm `+super` (vd `Lên plan HIS-1240 -m +super: ...`): Planner viết sẵn bản vá cho từng bước, Coder chỉ tìm và thay.
  - Ví dụ: `Lên plan HIS-1234 -s -v3: sửa chức năng A, B ở màn Tiếp nhận` · `Lên plan HIS-1240 -m: bổ sung chức năng xuất Excel thu tiền` (không ghi version = cả v2+v3).
  - Tiêu chí: `-s` sửa thẳng chức năng đã có · `-m`/`-l` cụm nhiều chức năng tùy quy mô — xem `AGENTS.md` mục 8.
- **Gate 1:** Bạn đọc & duyệt `PLAN.md` (đặc biệt check mục **Diff v2 vs v3** và **Bảng Mapping UI↔DB**), rồi gõ *"duyệt"* → Planner hỏi Coder dùng AI nào (vd `codex`) → tự mở phiên chat mới cho Coder qua `orca agent launch`.

### Bước 3 — Code trên nhánh tách đầu tiên (Coder — tùy CLI/model bạn chọn)
- **Bạn tạo sẵn và checkout nhánh** từ `master3` (vd `Thinh_Ksk_M3`). AI chỉ kiểm tra nhánh đúng gốc, không tự tạo nhánh.
- Phiên Coder được Planner mở sẵn (hoặc bạn tự gọi skill `implement-plan`):
  > *"Dùng skill `implement-plan` thực hiện đúng theo `tasks/.../PLAN.md`."*
- Coder sửa code (patch-only) + sinh script SQL tách riêng v2/v3 + tạo `DEPLOY_CHECKLIST.md`. *(AI không tự chạy `dotnet build`, bạn check nhanh terminal `dotnet watch run`; AI bị cấm `git push` và cấm đọc `appsettings` khi chưa được phép).*

### Bước 4 — Test & Audit (Context mới — tùy model bạn chọn)
- Nếu task có script SQL: **bạn tự chạy** `01 → 05` (bản đúng version) trên **DB Dev/Test**, xong báo lại cho Tester *"đã chạy xong script"* (lỗi thì dán lỗi để trả về Coder).
- Mở phiên mới, gọi skill `verify-task`:
  > *"Dùng skill `verify-task` kiểm duyệt `tasks/.../PLAN.md` và `git diff` hiện tại."*
- Tester chạy **`check.ps1`** trước (kiểm tra máy móc: nhánh, file ngoài plan, file nhạy cảm, fallback `??`, SQL cấm, cặp script v2/v3, liệt kê 100% dòng bị xóa), rồi soi **100% dòng bị xóa**, quét **6 luật Zero-Tolerance**, **Cross-Check `git diff` vs Script SQL**, test UI trên tab Orca bằng **`orca` CLI**, rồi đẩy `DEPLOY_CHECKLIST.md` lên Notion (`Release DB Scripts`).
- **Gate 2:** Bạn duyệt → **bạn tự** `git commit` & `git push` nhánh `..._M3` → báo *"đã commit"* để Tester cập nhật cột `Commit` trên Notion.

### Bước 5 — Port sang nhánh tách từ `master2` (`master3` ↔ `master2`)
- **Bạn tạo sẵn và checkout nhánh** từ `master2` (vd `Thinh_Ksk_M2`).
- Gọi skill `port-version`:
  > *"Dùng skill `port-version` chuyển thay đổi từ commit `<commit_id>` sang nhánh hiện tại theo `tasks/.../PLAN.md`."*
- Chạy lại `verify-task` trên nhánh `..._M2` → **bạn tự** commit & push → báo *"đã commit"*.
- **Phần việc của AI dừng ở đây**: test đủ + Notion ghi đủ (sửa sto nào, thêm cột nào, commit).

### Bước 6 — Lên Production *(bạn tự làm — AI không tham gia, chỉ để nhắc)*
- Mở bảng **`Release DB Scripts`** trên Notion (lọc `Trạng thái != Done`), chạy script theo đúng thứ tự **1 → 5** cho `master3` rồi `master2`.
- **Trước khi chạy (Pre-Deploy Check):** xuất lại sto hiện tại trên Prod, so với `before_*.sql` — khác nhau (đồng nghiệp vừa sửa) thì **dừng**, cập nhật snapshot và sửa lại `04_deploy_*.sql`.
- Chạy xong SQL `1 → 5` rồi **mới deploy code**.
- Nếu có sự cố cần quay lui, chạy lại file `snapshots/before_v3.sql` hoặc `before_v2.sql` đã lưu sẵn, và `99_rollback_*.sql` cho cột / index / seed / sto mới.

### Bước 7 — Chấm điểm & Rút kinh nghiệm (khuyến khích)
- Sau Gate 2 của nhánh cuối: *"Dùng skill `retro-task` chấm task `<TASK_ID>`"* → gõ điểm 1–5 (gõ mỗi số là đủ).
- AI ghi 1 dòng vào `RETRO_LOG.md`, tạo nháp vào `_proposed/` nếu có bài học dùng lại được.
- Định kỳ: *"Dùng skill `retro-task` tổng kết"* → biết nên **sửa quy trình**, **bổ sung kho** hay **đổi model** cho vai trò nào.

### Lần đầu trên dự án — Khởi tạo glossary
- Mở phiên AI trong dự án HIS: *"Dùng skill `add-knowledge` khởi tạo glossary"* → AI đọc code, soạn nháp 30–50 thuật ngữ → bạn `duyệt hết` / `bỏ dòng ...` / `sửa dòng ...`.

### Đang làm mà cần đổi plan
- *"Dùng skill `update-plan`: Cập nhật plan `<TASK_ID>`: <thay đổi>"* → Planner đọc tiến độ code, ghi **Rev mới** (bước MỚI / SỬA / HỦY + HOÀN TÁC), bạn gõ *"duyệt rev N"* → Planner báo phiên Coder làm tiếp.

### Bất cứ lúc nào — Tra cứu nhanh
- AI nói khó hiểu / dài dòng → gõ `/wait-what`.
- Thêm thuật ngữ: *"Dùng skill `add-knowledge` thêm thuật ngữ: KSK = Khám sức khỏe ..."*.
- *"/ask-map endpoint `/ThuTien/GetDanhSach` gọi sto nào?"* · *"/ask-map sto `sp_X` được gọi ở đâu (v2)?"* → trả lời ngay nếu đã có trong `ENDPOINT_MAP.md`, chưa có thì AI lần theo code thật rồi lưu lại.

### Hằng ngày — Nạp kiến thức
- *"Dùng skill `add-knowledge` ghi lại: <kiến thức>, xem file/hàm <...>"* → AI soạn theo khuôn, bạn `ok` là vào kho.
- *"Dùng skill `add-knowledge` duyệt kho nháp"* → trả lời `duyệt / sửa / bỏ / để sau` cho từng nháp.
- Xong nhớ **commit repo `AI_Agent`** để giữ kiến thức.

---

## 4. Gợi ý gắn MCP Server cho Online Docs
- **Khuyên dùng Notion MCP**: Tạo 1 Notion Database tên `Release DB Scripts` với các cột:
  - `Task` (Title)
  - `Version` (Multi-select: `v2`, `v3`)
  - `Trạng thái` (Select: `Chưa chạy Prod`, `Đã chạy v3`, `Đã chạy v2`, `Done`)
  - `Loại SQL` (Multi-select: `Table/Col`, `Index`, `Func/View`, `Sto`, `Seed`)
  - `Commit` (Text)
  - `Ngày` (Date)
  - `Chi tiết SQL` (Text)
- Khi đó trong `verify-task`, AI Tester chỉ cần gọi Notion MCP tạo 1 page mới trong Database đó với nội dung `DEPLOY_CHECKLIST.md`. Trước giờ lên Prod, bạn lọc `Status != Done` là thấy đủ 100% script cần chạy, không bao giờ sót.
