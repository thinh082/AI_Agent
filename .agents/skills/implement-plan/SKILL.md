---
name: implement-plan
description: Quy trình chuẩn cho AI Coder thực thi đúng theo PLAN.md đã duyệt, tuân thủ 6 luật Zero-Tolerance và sinh script SQL Server tách riêng v2/v3 không làm mất logic cũ.
---

# Skill: `implement-plan` (AI Coder)

## Điều kiện bắt buộc trước khi chạy
- Đã có `tasks/<YYYY-MM-DD>_<TASK_ID>/PLAN.md` (**nguồn chuẩn duy nhất**) với **`Trạng thái Gate 1: Đã duyệt`**. File `plans\<YYYY-MM-DD>_<TASK_ID>.html` chỉ là bản xem trực quan — nếu HTML lệch nội dung với `PLAN.md` thì làm theo `PLAN.md` và báo người dùng. Nếu có `UI_PLAN\<YYYY-MM-DD>_<TASK_ID>.html` thì phải bám sát bố cục Bootstrap và đúng 100% các `id`/`name` đã chốt trong file đó. Nếu chưa có plan hoặc còn câu hỏi mở chưa trả lời → **DỪNG, không code**.

## Quy trình thực hiện

### Bước 1 — Đọc kỹ `PLAN.md` & Kiểm tra nhánh Git (BẮT BUỘC)
1. Đọc toàn bộ `PLAN.md` (đặc biệt: Phạm vi KHÔNG làm, Bảng Mapping UI↔DB, Diff v2/v3, Danh sách bước).
   - Plan có nhiều **Rev** (mục 11) → làm theo **Rev mới nhất đã duyệt**. Nhận tin *"PLAN Rev N đã duyệt"* → đọc lại **toàn bộ** `PLAN.md`, làm các bước `[Rev N: MỚI / SỬA / HOÀN TÁC]`. Bước `HOÀN TÁC` là lý do hợp lệ để gỡ code đã viết ở Rev trước — chỉ gỡ đúng phần ghi trong bước đó.
2. Chạy `git branch --show-current`:
   - Người dùng đã **tạo sẵn và checkout** nhánh (vd `Thinh_Ksk_M3`). Kiểm tra đủ 4 điểm theo `AGENTS.md` Luật 6: không phải `master2`/`master3`, nhánh gốc đúng, khớp version trong `PLAN.md`, hậu tố tên khớp. **AI không tự tạo / đổi nhánh**; sai hoặc không rõ → **DỪNG báo người dùng**.
3. **KHÔNG đọc** `appsettings*.json` / `Web.config` / `.env` trừ khi người dùng cho phép rõ ràng. **KHÔNG BAO GIỜ chạy `git push`.**

### Bước 2 — Sửa Code (Tuân thủ 6 luật Zero-Tolerance + `aspnet-backend`)
- Với code backend ASP.NET Core (.NET 7): tuân thủ thêm quy chuẩn trong `.agents/skills/aspnet-backend/SKILL.md` (Interface+Class cùng file, chọn linh hoạt EF Core vs STO và Model/DTO vs `dynamic`, chuẩn Response `{code, message, data}`, Transaction, Validation).
0a. **Bước `[super]`** (cả plan nếu `PLAN.md` ghi `Super plan: Có`, hoặc từng bước được đánh dấu `[super]`):
   - Áp **đúng nguyên văn** bản vá: tìm đoạn gốc → thay / thêm đúng như plan. **Không "cải tiến"**, không viết lại theo ý mình.
   - Đoạn gốc **không tìm thấy** hoặc **khớp > 1 chỗ** → **DỪNG báo người dùng** (code đã đổi sau khi lên plan).
   - Bản vá **sai rõ ràng** (sai cú pháp, lệch tên so với Bảng Mapping / `GLOSSARY.md`, vi phạm 6 luật) → **DỪNG báo người dùng**, không tự sửa cho khác plan.
   - Bước không có `[super]` → làm như bình thường theo các ý bên dưới.
0. **Theo kích cỡ:** `-s`/`-m` làm liền các bước. **`-l`** làm **từng giai đoạn** theo mục 7 `PLAN.md`; hết mỗi giai đoạn **DỪNG** để người dùng kiểm tra `dotnet watch run` và tự commit rồi mới sang giai đoạn sau.
1. **Patch-Only:** Chỉ sửa đúng những đoạn cần thiết theo `PLAN.md`. **Cấm viết lại nguyên file.**
2. **Không dọn dẹp tiện tay:** Không xóa, đổi tên, hoặc refactor bất kỳ hàm/đoạn logic nào không có trong `PLAN.md`.
3. **Đúng tên 1–1:** Dùng chính xác tên cột DB, `id`/`name` HTML theo Bảng Mapping trong `PLAN.md`. **Cấm tuyệt đối chuỗi fallback kiểu `a ?? A ?? ""`.** Tên biến / hàm / test **mới** đặt theo đúng thuật ngữ trong `GLOSSARY.md`.
4. **Fail-Fast:** Mọi nhánh `else` / `default` của mapping trạng thái/mã phải throw exception / báo lỗi rõ ràng kèm giá trị đầu vào sai; **cấm gán giá trị nghiệp vụ mặc định**.
5. Nếu trong lúc code phát hiện thực tế khác với `PLAN.md` → **DỪNG LẠI báo người dùng cập nhật Plan**, không tự ý sáng tạo.
6. **KHÔNG tự chạy `dotnet build` / `dotnet run`:** Người dùng 100% build bằng `dotnet watch run`. Sau khi sửa xong, tự rà lại syntax/using/kiểu dữ liệu/tham số trên các file vừa sửa; nếu nghi ngờ có lỗi compile hoặc cần người dùng kiểm tra `dotnet watch run` thì **dừng báo rõ** để người dùng check log `dotnet watch run` rồi mới bàn giao tiếp.
7. **Code theo kho kiến thức:** Bước nào trong `PLAN.md` gắn mã `P/X/D` → mở đúng mục đó trong `KNOWLEDGE_ROOT` (khai báo trong `AGENTS.md` mục 7) và làm theo (Pattern = làm theo, Pitfall = tránh, Domain = tuân quy tắc nghiệp vụ). Mẫu lệch với code thật → **DỪNG báo người dùng** (như ý 5).
8. **Bước chưa có mẫu (ngoài khuôn):** được tự chọn *cách code*, ưu tiên theo *cách làm dự kiến* trong `PLAN.md`. **"Ngoài khuôn" ≠ "ngoài phạm vi"**: vẫn chỉ sửa đúng file/hàm trong `PLAN.md` (Luật 1). Nếu tự chọn cách làm hoặc làm khác dự kiến → ghi vào `tasks/<task>/CODER_NOTES.md` (chỉ tạo khi có): `Bước | File + Class.Method / STO | Cách làm | Lý do`.

### Bước 3 — Sinh Script SQL Server (Tách riêng v2 / v3 — Không ghi đè logic cũ)
Với mọi thay đổi DB của task, lưu vào `tasks/<task>/`:
1. **Script cấu trúc bảng / cột / index / seed** (nếu có):
   - Đặt tên có số thứ tự chạy rõ ràng:
     - `01_table_v3.sql` / `01_table_v2.sql` (bọc `IF COL_LENGTH('dbo.TableName', 'ColName') IS NULL` để chạy lại an toàn — idempotent).
     - `02_index_v3.sql` / `02_index_v2.sql`
     - `05_seed_v3.sql` / `05_seed_v2.sql`
     - `99_rollback_v3.sql` / `99_rollback_v2.sql`: lệnh quay lui cho cột / index / seed mới và `DROP` sto/view/function **mới tạo** (viết theo thứ tự ngược `5 → 1`, idempotent, ghi chú rõ nếu `DROP COLUMN` gây mất dữ liệu).
     - Cột mới phải tương thích ngược (`NULL` hoặc có `DEFAULT`) để code cũ trên Prod không lỗi khi DB chạy trước code.
2. **Script Function / View** (nếu có — chạy trước sto vì sto có thể phụ thuộc):
   - Sửa **cục bộ** trên nền bản `before` tương ứng trong `snapshots/` → xuất `03_func_view_v3.sql` / `03_func_view_v2.sql` (giữ nguyên toàn bộ logic riêng của từng version).
   - Function/View **mới** → viết idempotent bằng `CREATE OR ALTER` (có sẵn trên SQL Server 2017), rollback bằng `DROP` trong `99_rollback_*.sql`.
   - **Không gộp** Function/View vào `04_deploy_*.sql`.
3. **Script Stored Procedure:**
   - Sửa **cục bộ** trên nền `snapshots/before_v3.sql` → xuất `04_deploy_v3.sql` (giữ nguyên toàn bộ logic riêng của `master3`).
   - Sửa **cục bộ** trên nền `snapshots/before_v2.sql` → xuất `04_deploy_v2.sql` (nếu task áp dụng v2, giữ nguyên toàn bộ logic riêng của `master2`).
   - Giữ nguyên `snapshots/before_v2.sql` và `snapshots/before_v3.sql` làm bản **backup/rollback** (không sửa đè lên file trong `snapshots/`).

### Bước 4 — Tạo nháp `DEPLOY_CHECKLIST.md`
- Tạo `tasks/<task>/DEPLOY_CHECKLIST.md` theo mẫu `.agents/templates/DEPLOY_CHECKLIST.md`, liệt kê đủ tất cả script theo thứ tự 1 → 5.
- **Tự kiểm tra cặp script trước khi bàn giao:** task áp dụng **v2 + v3** → mỗi file `0x_*_v3.sql` phải có file `0x_*_v2.sql` tương ứng (sinh trên nền `before_v2*.sql`), hoặc ghi rõ `Không có (lý do)` cho v2 trong `DEPLOY_CHECKLIST.md`. Thiếu → sinh bổ sung ngay, không bàn giao khi còn thiếu.

### Bước 5 — Kiểm tra với `dotnet watch run` & Bàn giao cho Tester
- Tóm tắt ngắn gọn các file code đã sửa và các file SQL đã sinh, kèm các bước ngoài khuôn (nếu có `CODER_NOTES.md`).
- Nhắc người dùng **liếc nhanh terminal `dotnet watch run`** xem có lỗi biên dịch không:
  - Nếu đỏ → người dùng dán lỗi lại để Coder sửa ngay.
  - Nếu task có script SQL → liệt kê thứ tự file `01 → 05` để người dùng **tự chạy trên DB Dev/Test** (AI không chạy), người dùng chạy xong báo lại.
  - Nếu xanh (và đã chạy xong script trên DB Dev nếu có) → chuyển sang **AI Tester (context mới)** chạy skill `verify-task` (test UI bằng `orca` CLI + audit diff + đẩy Notion) trước khi commit/push.
