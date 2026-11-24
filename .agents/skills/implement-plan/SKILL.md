---
name: implement-plan
description: Quy trình chuẩn cho AI Coder thực thi đúng theo PLAN.md đã duyệt, tuân thủ 6 luật Zero-Tolerance và sinh script SQL Server tách riêng v2/v3 không làm mất logic cũ.
---

# Skill: `implement-plan` (AI Coder)

## Điều kiện bắt buộc trước khi chạy
- Đã có file kế hoạch `D:\Project\AI_Agent\plans\<YYYY-MM-DD>_<TASK_ID>.html` (hoặc `PLAN.md`) và **người dùng đã duyệt Gate 1**. Nếu có `D:\Project\AI_Agent\UI_PLAN\<YYYY-MM-DD>_<TASK_ID>.html` thì phải bám sát bố cục Bootstrap và đúng 100% các `id`/`name` đã chốt trong file đó. Nếu chưa có plan hoặc còn câu hỏi mở chưa trả lời → **DỪNG, không code**.

## Quy trình thực hiện

### Bước 1 — Đọc kỹ `PLAN.md` & Kiểm tra nhánh Git (BẮT BUỘC tách nhánh)
1. Đọc toàn bộ `PLAN.md` (đặc biệt: Phạm vi KHÔNG làm, Bảng Mapping UI↔DB, Diff v2/v3, Danh sách bước).
2. Chạy `git branch --show-current`:
   - **Nếu đang đứng trên `master2` hoặc `master3` → KHÔNG ĐƯỢC SỬA CODE.** Phải tách nhánh mới từ nó trước (vd: `git checkout -b feat/<TASK_ID>-v3`) rồi mới bắt đầu sửa.
3. **KHÔNG đọc** `appsettings*.json` / `Web.config` / `.env` trừ khi người dùng cho phép rõ ràng. **KHÔNG BAO GIỜ chạy `git push`.**

### Bước 2 — Sửa Code (Tuân thủ 6 luật Zero-Tolerance + `aspnet-backend`)
- Với code backend ASP.NET Core (.NET 7): tuân thủ thêm quy chuẩn trong `.agents/skills/aspnet-backend/SKILL.md` (Interface+Class cùng file, chọn linh hoạt EF Core vs STO và Model/DTO vs `dynamic`, chuẩn Response `{code, message, data}`, Transaction, Validation).
1. **Patch-Only:** Chỉ sửa đúng những đoạn cần thiết theo `PLAN.md`. **Cấm viết lại nguyên file.**
2. **Không dọn dẹp tiện tay:** Không xóa, đổi tên, hoặc refactor bất kỳ hàm/đoạn logic nào không có trong `PLAN.md`.
3. **Đúng tên 1–1:** Dùng chính xác tên cột DB, `id`/`name` HTML theo Bảng Mapping trong `PLAN.md`. **Cấm tuyệt đối chuỗi fallback kiểu `a ?? A ?? ""`.**
4. **Fail-Fast:** Mọi nhánh `else` / `default` của mapping trạng thái/mã phải throw exception / báo lỗi rõ ràng kèm giá trị đầu vào sai; **cấm gán giá trị nghiệp vụ mặc định**.
5. Nếu trong lúc code phát hiện thực tế khác với `PLAN.md` → **DỪNG LẠI báo người dùng cập nhật Plan**, không tự ý sáng tạo.
6. **KHÔNG tự chạy `dotnet build` / `dotnet run`:** Người dùng 100% build bằng `dotnet watch run`. Sau khi sửa xong, tự rà lại syntax/using/kiểu dữ liệu/tham số trên các file vừa sửa; nếu nghi ngờ có lỗi compile hoặc cần người dùng kiểm tra `dotnet watch run` thì **dừng báo rõ** để người dùng check log `dotnet watch run` rồi mới bàn giao tiếp.

### Bước 3 — Sinh Script SQL Server (Tách riêng v2 / v3 — Không ghi đè logic cũ)
Với mọi thay đổi DB của task, lưu vào `tasks/<task>/`:
1. **Script cấu trúc bảng / cột / index / seed** (nếu có):
   - Đặt tên có số thứ tự chạy rõ ràng:
     - `01_table_v3.sql` / `01_table_v2.sql` (bọc `IF COL_LENGTH('dbo.TableName', 'ColName') IS NULL` để chạy lại an toàn — idempotent).
     - `02_index_v3.sql` / `02_index_v2.sql`
     - `05_seed_v3.sql` / `05_seed_v2.sql`
2. **Script Stored Procedure / View / Function:**
   - Sửa **cục bộ** trên nền `snapshots/before_v3.sql` → xuất `04_deploy_v3.sql` (giữ nguyên toàn bộ logic riêng của `master3`).
   - Sửa **cục bộ** trên nền `snapshots/before_v2.sql` → xuất `04_deploy_v2.sql` (nếu task áp dụng v2, giữ nguyên toàn bộ logic riêng của `master2`).
   - Giữ nguyên `snapshots/before_v2.sql` và `snapshots/before_v3.sql` làm bản **backup/rollback** (không sửa đè lên file trong `snapshots/`).

### Bước 4 — Tạo nháp `DEPLOY_CHECKLIST.md`
- Tạo `tasks/<task>/DEPLOY_CHECKLIST.md` theo mẫu `.agents/templates/DEPLOY_CHECKLIST.md`, liệt kê đủ tất cả script theo thứ tự 1 → 5.

### Bước 5 — Kiểm tra với `dotnet watch run` & Bàn giao cho Tester
- Tóm tắt ngắn gọn các file code đã sửa và các file SQL đã sinh.
- Nhắc người dùng **liếc nhanh terminal `dotnet watch run`** xem có lỗi biên dịch không:
  - Nếu đỏ → người dùng dán lỗi lại để Coder sửa ngay.
  - Nếu xanh → chuyển sang **AI Tester (context mới)** chạy skill `verify-task` (test UI bằng `orca` CLI + audit diff + đẩy Notion) trước khi commit/push.
