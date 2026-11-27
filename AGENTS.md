# AGENTS.md — Quy trình AI Agent chuẩn (Dự án song song master2 / master3 + SQL Server)

> File này là **luật cứng** áp dụng cho mọi AI Agent (Planner, Coder, Porter, Tester/Reviewer) trên dự án này. Vi phạm bất kỳ luật **Zero-Tolerance** nào = **FAIL ngay lập tức**.

---

## 1. Bối cảnh dự án & Tech Stack
- Dự án lớn (**> 500 file mỗi version**), chạy song song **2 version**: `master2` (v2 — khách hàng cũ) và `master3` (v3 — khách hàng mới).
- Thông thường 1 task áp dụng cho **cả 2 nhánh** (sửa 1 nhánh trước, commit lấy `<commit_id>`, rồi port sang nhánh còn lại), trừ khi ticket ghi rõ chỉ custom riêng 1 nhánh.
- **Tên nhánh gốc thật (git):** v2 = **`master_2`**, v3 = **`master_3`**. Trong tài liệu gọi tắt `master2` / `master3`; **mọi lệnh git dùng tên thật** (ký hiệu `<BASE_V2>` = `master_2`, `<BASE_V3>` = `master_3`). Đổi tên nhánh → sửa dòng này + tham số `-BaseV2` / `-BaseV3` của `map.ps1`.
- **Tech Stack:** ASP.NET Core MVC (.NET 7) + HTML / CSS / JavaScript (Bootstrap) + **SQL Server 2017** *(chỉ dùng cú pháp T-SQL tương thích SQL Server 2017 — cấm dùng hàm chỉ có ở bản 2019/2022+ như `GREATEST`, `LEAST`, `GENERATE_SERIES`)*.
- **Database:** SQL Server 2017 (`master2` và `master3`). Stored Procedure / View / Function **không nằm trong git** và đồng nghiệp có thể sửa trực tiếp trên DB mà không ghi chú.
- **Môi trường chạy dev:** Người dùng **100% build/chạy bằng `dotnet watch run`**. AI **KHÔNG tự ý chạy `dotnet build` / `dotnet run`** trừ khi người dùng yêu cầu rõ (tránh chậm và xung đột lock file).

---

## 2. Phân tách vai trò (Role Separation — Linh hoạt CLI & Model)
Không để 1 phiên AI vừa tự nghĩ, vừa tự code, vừa tự test. **Người dùng tự chọn CLI (`agy`, `codex`, ...) và model tùy thời điểm** (không gán cứng hãng/tên model):

| Vai trò | Skill tương ứng | Cách vận hành thực tế | Quyền hạn |
|---|---|---|---|
| **Planner** | `.agents/skills/plan-task/SKILL.md` · `.agents/skills/update-plan/SKILL.md` (cập nhật plan giữa chừng) | **Phiên chuyên trách cố định** (nạp context 1 lần, 100% phiên đó chỉ lên plan) | **Read-only** — chỉ đọc code, Graphify, snapshot SQL, viết `PLAN.md` |
| **Coder** | `.agents/skills/implement-plan/SKILL.md` + `.agents/skills/aspnet-backend/SKILL.md` | Phiên riêng (đổi model/CLI linh hoạt theo thời điểm) | Ghi code đúng theo `PLAN.md` đã duyệt, sinh script SQL tách v2/v3 |
| **Porter** | `.agents/skills/port-version/SKILL.md` + `.agents/skills/aspnet-backend/SKILL.md` | Phiên riêng (đổi model/CLI linh hoạt) | Chuyển thay đổi từ `<commit_id>` giữa `master2` ↔ `master3` an toàn |
| **Tester / Reviewer** | `.agents/skills/verify-task/SKILL.md` | **Bắt buộc context mới**; **nên** khác model với Coder (nhất là task tiền / BHYT / cổng thông tin) | **Read + Test** — soi `git diff`, test UI trên Orca browser qua `orca` CLI, check SQL, đẩy Notion |
| **Tra cứu** | `.agents/skills/ask-map/SKILL.md` · `.agents/skills/wait-what/SKILL.md` | Phiên bất kỳ, hỏi nhanh | **Read-only** — chỉ ghi `graphify-out/<ver>/ENDPOINT_MAP.md` + nháp thuật ngữ |
| **Chẩn đoán bug** | `.agents/skills/diagnose-bug/SKILL.md` | Trước Planner (có thể cùng phiên Planner), chỉ với task sửa bug | **Read-only** — tái hiện trên Orca (Dev), viết `BUG_REPORT.md` + nháp kịch bản |
| **Tự học** | `.agents/skills/add-knowledge/SKILL.md` · `.agents/skills/retro-task/SKILL.md` | Phiên bất kỳ, model rẻ/nhanh là đủ | Chỉ ghi trong `KNOWLEDGE_ROOT` (mục 7) — nạp/duyệt kiến thức, chấm điểm task |

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
- **Người dùng tự tạo sẵn và checkout nhánh** tách từ `master2` / `master3` (ví dụ `Thinh_Ksk_M2` từ `master2`, `Thinh_Ksk_M3` từ `master3`). **AI KHÔNG tự tạo / đổi nhánh** (`git checkout`, `git switch`, `git branch`), chỉ **kiểm tra** trước khi sửa bất kỳ file nào:
  1. `git branch --show-current` là `<BASE_V2>` hoặc `<BASE_V3>` → **DỪNG NGAY**.
  2. Xác định nhánh gốc: so `git rev-list --count <BASE_V2>..HEAD` với `git rev-list --count <BASE_V3>..HEAD` (thiếu ref local thì dùng `origin/<BASE_V2>`, `origin/<BASE_V3>`) — số **nhỏ hơn rõ rệt** là nhánh gốc.
  3. Nhánh gốc phải **khớp version đang làm** trong `PLAN.md`; hậu tố tên nhánh (`_M2` / `_M3`) nếu có phải khớp nhánh gốc.
  4. Bất kỳ điểm nào không khớp hoặc không rõ → **DỪNG báo người dùng**, không tự xử lý nhánh.

---

## 4. Luật bắt buộc cho SQL Server (Chống ghi đè logic sto & sót script Prod)
1. **Đủ 2 bản hiện tại (Dual Snapshot):** Nếu task sửa sto/view/function chạy trên cả 2 version, **BẮT BUỘC** phải đưa cho AI cả 2 bản đang chạy thật trên SSMS: `before_v2.sql` (từ `master2`) và `before_v3.sql` (từ `master3`). Thiếu 1 trong 2 → **Planner từ chối lên plan**.
   - **Cách đưa snapshot:** tự lưu file vào `tasks/<task>/snapshots/`, **hoặc dán thẳng code sto vào chat Planner** (ghi `v3:` / `v2:` trước mỗi khối) → Planner tự lưu nguyên văn (`plan-task` Bước 1). Nhiều object trong 1 task → `before_v3_<TenObject>.sql`.
   - **Nguồn snapshot:** xuất từ **DB Production** (DB sẽ deploy thật). Nếu chỉ lấy được từ Dev → ghi rõ nguồn trong `PLAN.md` và bắt buộc đối chiếu lại với Prod ở bước Pre-Deploy (mục 6).
   - **Ngoại lệ sto/view/function MỚI** (chưa tồn tại trên DB): không có bản `before`, ghi rõ `Sto mới — không có before` trong `PLAN.md`; rollback bằng `DROP` trong `99_rollback_*.sql`.
2. **So sánh (Diff) & Giữ nguyên logic riêng:** Planner bắt buộc đối chiếu `before_v2.sql` vs `before_v3.sql` để chỉ ra các đoạn logic đồng nghiệp đã thêm ở từng version; Coder chỉ sửa đúng đoạn cần thiết, **tuyệt đối không xóa/ghi đè logic cũ** trong sto.
3. **Tách script theo version:** Không bao giờ dùng chung 1 file `ALTER PROCEDURE` cho cả `master2` và `master3`. Luôn tạo riêng `04_deploy_v2.sql` (sửa trên nền `before_v2.sql`) và `04_deploy_v3.sql` (sửa trên nền `before_v3.sql`). File `before_v2.sql` / `before_v3.sql` chính là bản rollback.
4. **Thứ tự chạy chuẩn trên Prod** trong `DEPLOY_CHECKLIST.md`:
   `1. Table / Column (ALTER TABLE)` → `2. Index / Constraint` → `3. Function / View` → `4. Stored Procedure` → `5. Seed / Config Data (idempotent)`.
5. **AI không bao giờ chạy SQL ghi/ALTER lên DB Production.** Con người tự chạy sau khi duyệt.
6. **Pre-Deploy Check (chống snapshot cũ):** Ngay trước khi chạy `04_deploy_*.sql` trên Prod, người dùng xuất lại sto hiện tại trên Prod và so với `before_*.sql`. **Nếu khác nhau** (đồng nghiệp đã sửa sto sau thời điểm snapshot) → **DỪNG**, cập nhật snapshot và sửa lại `04_deploy_*.sql` trên nền bản mới rồi mới chạy.
7. **Thứ tự DB trước, Code sau:** Chạy xong script SQL `1 → 5` trên Prod rồi mới deploy code. Script thêm cột phải tương thích ngược (cột mới `NULL` hoặc có `DEFAULT`) để code cũ vẫn chạy được.
8. **Rollback đầy đủ:** `before_*.sql` chỉ rollback sto/view/function đã có. Cột / index / seed / sto mới phải có `99_rollback_v2.sql` / `99_rollback_v3.sql` (chạy ngược `5 → 1`, cân nhắc mất dữ liệu khi `DROP COLUMN`).

---

## 5. Luật dùng Graphify (Bản đồ kiến trúc tách riêng v2 / v3)
- Tạo mới / cập nhật bản đồ dự án bằng skill `.agents/skills/map-project/SKILL.md`:
  - Tự động kiểm tra nhánh hiện tại tách từ `master2` hay `master3` (nếu không rõ → **dừng báo người dùng**, cấm ghi lộn version).
  - Lưu tách riêng vào `graphify-out/master2/` và `graphify-out/master3/` (tự ẩn `graphify-out/` trong `.git/info/exclude`, không đụng `.gitignore` công ty).
- Dùng Graphify (`graphify-out/<master2|master3>/graph.json`, `GRAPH_REPORT.md`) ở bước **Planner** để tra nhanh call graph và blast radius.
- **Tiết kiệm token:** dựng / cập nhật bản đồ bằng `map.ps1` (code-only, **không gọi model** — người dùng tự chạy, không cần AI). Tra bản đồ bằng `graphify query ... --budget 1500 --graph graphify-out/<ver>/graph.json` / `explain` / `affected`; **không đọc cả** `graph.json` / `GRAPH_REPORT.md`. Cấm `/graphify .`, `graphify label`, `graphify hook install` trừ khi người dùng yêu cầu rõ.
- **Tra nhanh "endpoint này gọi sto nào / sto này được gọi ở đâu"**: skill `.agents/skills/ask-map/SKILL.md` (read-only, lưu bộ nhớ đệm `graphify-out/<ver>/ENDPOINT_MAP.md`, tự kiểm tra còn mới theo commit của file).
- **Graphify có thể cũ** so với code vừa `git pull`: chỉ dùng để *định vị nhanh*, trước khi kết luận hoặc sửa **luôn mở file thật trên máy để xác nhận**.

---

## 6. Cổng duyệt của con người (Human Gates)
- **Gate 1:** Người dùng duyệt `PLAN.md` → Coder mới được viết code. **Plan đổi giữa chừng** → skill `update-plan` (Rev mới, đánh dấu MỚI / SỬA / HỦY + HOÀN TÁC) → người dùng *"duyệt rev N"* → Planner báo phiên Coder làm tiếp. Người dùng nói *"duyệt"* trong phiên Planner → Planner ghi `Gate 1: Đã duyệt`, hỏi AI dùng cho Coder và mở phiên chat mới qua `orca agent launch` (`plan-task` Bước 5).
- **Gate 2:** Người dùng duyệt `TEST_REPORT.md` + `DEPLOY_CHECKLIST.md` + `git diff` → mới merge & deploy. **Tester (AI) ghi Notion** trước Gate 2; người dùng commit xong báo *"đã commit"* → Tester cập nhật cột `Commit`. Người dùng chỉ tự đổi `Trạng thái` khi đã chạy Prod.
- **Task chưa coi là DONE** nếu chưa có `DEPLOY_CHECKLIST.md` đã cross-check với `git diff` (và đồng bộ lên Online Docs qua MCP nếu đã cấu hình).
- **Sau Gate 2** (task có port → sau khi nhánh port cũng PASS): chạy `retro-task` chấm điểm 1–5 *(khuyến khích, có thể bỏ qua)*.

---

## 7. Kho kiến thức & Chấm điểm (Tự học)
- **`KNOWLEDGE_ROOT` = `E:\Project\AI_Agent\.agents\knowledge`** — kho nằm trong repo `AI_Agent` (có commit), **không** copy vào dự án HIS. Đổi máy/đổi đường dẫn → chỉ sửa dòng này. CLI chạy sandbox có thể cần cấp quyền đọc (ghi khi tạo nháp) thư mục này.
- Cấu trúc: `INDEX.md` (mục lục — đọc trước) · `patterns/` (`P###` mẫu nên làm) · `pitfalls/` (`X###` lỗi cấm lặp) · `domain/` (`D###` nghiệp vụ) · `_proposed/` (nháp chờ duyệt) · `retro/RETRO_LOG.md` (nhật ký điểm) · `_templates/ENTRY.md` (khuôn mục) · **`GLOSSARY.md`** (thuật ngữ chung — **mọi vai trò đọc mỗi task**, dùng đúng tên) · `e2e/` (`E###` / `F###` kịch bản test Orca, khuôn `_templates/E2E.md`).
- **Planner** gắn mã `P/X/D` cho từng bước ở mục 7 `PLAN.md` + ghi revision kho. **Coder / Porter** làm theo mã đã gắn. **Tester** kiểm tra tuân thủ (Cổng 2).
- **"Ngoài khuôn" ≠ "Ngoài phạm vi":** bước chưa có mẫu → Coder được tự chọn *cách code* và ghi `tasks/<task>/CODER_NOTES.md`; nhưng sửa file/hàm ngoài `PLAN.md` **vẫn bị cấm** (Luật 1).
- **AI không tự ghi kho chính thức:** chỉ người dùng (qua `add-knowledge`) mới thêm/duyệt mục; AI chỉ tạo nháp trong `_proposed/`. Pattern chỉ được duyệt khi **đã dùng ≥ 2 lần** hoặc người dùng xác nhận chắc chắn dùng lại.
- Tham chiếu code trong kho dùng `file + Class.Method / tên STO`, **không ghi số dòng**; luôn mở file thật để xác nhận.
- Ngoại lệ ghi trực tiếp vào mục chính thức (**chỉ thêm dòng**, không đổi nội dung): `retro-task` thêm `Lịch sử dùng`; Tester thêm `Lịch sử chạy` của kịch bản E2E.
- **Task sửa bug** phải qua `diagnose-bug` (tái hiện được trên Orca + nguyên nhân gốc) trước khi lên plan sửa.
- AI trả lời khó hiểu / dài dòng → người dùng gõ `/wait-what`: AI nói lại tối đa 5 dòng bằng thuật ngữ `GLOSSARY.md`.
- **Cấm đưa vào kho:** dữ liệu bệnh nhân, connection string, nội dung `appsettings*.json` / `Web.config` / `.env`, snapshot sto Prod nguyên bản.

---

## 8. Kích cỡ Task (`-s` / `-m` / `-l`) & Chuông báo
- **Cú pháp:** `Lên plan <TASK_ID> [-s|-m|-l] [-v2|-v3] [+super]: <mô tả>` — không ghi version = cả `v2` + `v3`.
- **Cờ kích cỡ do người dùng gắn là quyết định cuối cùng.** Thiếu cờ → Planner đề xuất + hỏi, không tự chọn.
- **Kích cỡ chỉ quyết định lượng giấy tờ** (độ dài plan, HTML, mức soi của Tester). **6 luật Zero-Tolerance + luật SQL (mục 4) áp dụng cho MỌI kích cỡ.**

| | `-s` (nhỏ) | `-m` (vừa) | `-l` (lớn) |
|---|---|---|---|
| **Tiêu chí (của người dùng)** | Sửa thẳng 1 vài **chức năng đã có** ("sửa A, sửa B") | **Cụm nhiều chức năng** / chức năng mới trong **1 module/màn hình** | **Cụm chức năng lớn**: nhiều module/màn hình, luồng liên hoàn, tích hợp hệ thống ngoài |
| **PLAN.md** | Rút gọn (mục 1, 2A, 7, 9, 10 + 5 nếu lưu dữ liệu) | Đầy đủ | Đầy đủ, mục 7 chia **giai đoạn** |
| **Plan HTML / UI_PLAN** | Không | HTML khi người dùng yêu cầu; UI_PLAN khi có giao diện mới | Có |
| **Coder** | Làm liền | Làm liền | Từng giai đoạn, dừng cho người dùng check & commit |
| **Tester** | Cổng 1–2 đầy đủ, test nhanh, Notion chỉ khi có SQL | Đủ 5 cổng | Đủ 5 cổng, **bắt buộc khác model Coder** |
| **Retro** | Gõ mỗi điểm | Bình thường | Bình thường, nên ghi đủ nguyên nhân |

**Chuông báo** — task gắn `-s` mà có 1 trong các dấu hiệu sau → Planner **DỪNG hỏi** người dùng *giữ `-s`* (chỉ thêm phần an toàn bắt buộc) hay *nâng `-m`*; **không tự nâng**:
1. Đụng **STO / View / Function / bảng / cột** (→ dù giữ `-s` vẫn bắt buộc snapshot v2/v3 + script tách riêng + `DEPLOY_CHECKLIST.md`).
2. Đụng **tiền, BHYT, cổng thông tin, API đối tác**.
3. Phải **xóa** code / logic có sẵn.
4. Sửa **> 3 file**, hoặc **v2 và v3 khác nhau** ngay chỗ cần sửa.

### Super plan (`+super` / bước `[super]`)
Chuyển phần "nghĩ" sang Planner: bước `[super]` là **bản vá gần hoàn chỉnh** (đoạn code gốc nguyên văn + đoạn code mới), Coder chỉ tìm và thay.

| Coder | Task | Dùng |
|---|---|---|
| Mạnh (chậm cũng được) | Bình thường | **Plan thường** (không cờ) |
| Yếu / nhanh | Bất kỳ | **`+super`** — mọi bước dạng bản vá (`-l`: theo từng giai đoạn) |
| Mạnh | Có bước rủi ro cao | Plan thường; Planner **tự đánh dấu `[super]`** cho bước sửa STO/View/Function, mapping mã gửi cổng thông tin/đối tác, logic tiền |

- Coder gặp bước `[super]`: áp **đúng nguyên văn**; đoạn gốc không thấy / khớp > 1 chỗ / bản vá sai rõ ràng → **DỪNG báo**, không tự sửa khác plan.
- `Super plan: Có` → **Tester bắt buộc khác model với Coder** (bản vá do Planner viết cũng có thể sai).
- Ghi cột `Super plan` trong `RETRO_LOG.md` để `retro-task tổng kết` so *model nhanh + super* với *model mạnh + plan thường*.
