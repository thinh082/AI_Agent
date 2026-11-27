---
name: port-version
description: Quy trình an toàn để chuyển thay đổi từ một commit_id ở nhánh master3 sang master2 (hoặc ngược lại) mà không ghi đè mất logic riêng của nhánh đích và không thiếu dependency/script SQL.
---

# Skill: `port-version` (Chuyển thay đổi `master2` ↔ `master3`)

> **BẮT BUỘC — đọc trước, không được quên:**
> 1. Kiểm tra nhánh đích theo Luật 6 (không tự tạo / đổi nhánh), working tree **sạch**, ghi `Base commit v2` (hoặc v3).
> 2. Đọc đủ `git show <commit_id>`; kiểm tra **dependency trên nhánh đích trước khi sửa** — thiếu / xung đột → **DỪNG hỏi**.
> 3. **Giữ nguyên logic riêng** của nhánh đích; không mang code đặc thù của version kia sang.
> 4. Script SQL nhánh đích sinh trên nền `before_v2` / `before_v3` của chính nhánh đó — **cấm copy đè** `04_deploy` của version kia.
> 5. Ghi `PROGRESS.md`, chạy `check.ps1` trước khi bàn giao Tester. Không `git push`.

## Khi nào dùng
Sau khi bạn đã hoàn thành + commit + push task trên 1 nhánh (vd `master3`), lấy `<commit_id>`, chuyển git sang nhánh còn lại (vd `master2`) và muốn AI đem thay đổi đó sang nhánh đích một cách an toàn.

## Quy trình bắt buộc

### Bước 1 — Kiểm tra nhánh tách & Đọc commit nguồn
1. Kiểm tra `git branch --show-current`:
   - **TUYỆT ĐỐI KHÔNG sửa trực tiếp trên `master2` hoặc `master3`.**
   - Người dùng đã **tạo sẵn và checkout** nhánh tách từ nhánh đích (vd `Thinh_Ksk_M2`). Kiểm tra theo `AGENTS.md` Luật 6 (nhánh gốc đúng nhánh đích) và working tree sạch. **AI không tự tạo / đổi nhánh**; sai hoặc không rõ → **DỪNG báo người dùng**.
   - **Working tree sạch** (`git status --porcelain` rỗng) rồi ghi `Base commit v2: <git rev-parse --short HEAD>` (hoặc `Base commit v3` nếu port ngược) vào đầu `PLAN.md` — `check.ps1` và Tester trên nhánh đích so từ mốc này. Chưa sạch → **DỪNG**, nhắc người dùng commit riêng việc khác trước.
   - Ghi tiến độ port vào `PROGRESS.md` (thêm các dòng `Port v2 — bước ...`) và chạy `check.ps1` trước khi bàn giao Tester, như Coder.
2. Chạy `git show <commit_id>` để đọc toàn bộ diff (từng file, từng dòng thêm/xóa) và commit message.
3. **KHÔNG đọc** `appsettings*.json` / `Web.config` / `.env` trừ khi người dùng cho phép. **KHÔNG BAO GIỜ chạy `git push`.**

### Bước 2 — Kiểm tra tương thích trên nhánh đích (BẮT BUỘC trước khi sửa)
Với từng file bị ảnh hưởng trong `<commit_id>`:
1. Mở file tương ứng trên nhánh đích và so sánh phần ngữ cảnh xung quanh chỗ cần sửa:
   - File có tồn tại ở đúng đường dẫn không?
   - Nhánh đích có **logic riêng của version** (vd: v2 có đoạn xử lý riêng cho khách hàng cũ) nằm gần chỗ cần sửa không?
2. **Kiểm tra Dependency:** Mọi hàm helper, class, cột DB, tham số sto, hoặc config mà `<commit_id>` gọi tới **có tồn tại trên nhánh đích không**?
3. **Nếu phát hiện xung đột logic hoặc thiếu dependency trên nhánh đích → DỪNG LẠI báo rõ cho người dùng** trước khi sửa. Không tự ý chế hoặc xóa code riêng của nhánh đích.
4. **Kho kiến thức:** Đọc các mục `P/X/D` gắn trong `PLAN.md` (tại `KNOWLEDGE_ROOT` (khai báo trong `AGENTS.md` mục 7)), đặc biệt phần **Khác biệt v2 / v3**, và áp dụng cách làm của **nhánh đích**. Mục không có hướng dẫn cho nhánh đích → coi là ngoài khuôn, ghi vào `tasks/<task>/CODER_NOTES.md`.

### Bước 3 — Áp dụng thay đổi (Patch-Only)
1. Chỉ áp dụng đúng thay đổi nghiệp vụ của `<commit_id>` lên nhánh đích.
2. **Tuyệt đối giữ nguyên** mọi code riêng của nhánh đích (không mang nhầm code đặc thù của v3 sang v2 hoặc ngược lại).
3. Tuân thủ đủ **6 luật Zero-Tolerance** trong `AGENTS.md` (không xóa hàm ngoài phạm vi, không đoán mò, không silent fallback, Fail-Fast ở `else`/`default`, bảo mật `appsettings` & chỉ đọc DB, cấm `git push` & cấm sửa trên `master2`/`master3`).
4. Với code backend ASP.NET Core (.NET 7): tuân thủ quy chuẩn trong `.agents/skills/aspnet-backend/SKILL.md` (khi cần điều chỉnh code cho khớp nhánh đích).

### Bước 4 — Kiểm tra Script SQL cho nhánh đích
1. Nếu `<commit_id>` có đụng cột DB / sto / seed data:
   - Kiểm tra `tasks/<task>/` đã có đủ script riêng cho nhánh đích chưa (`01_table_v2.sql`, `04_deploy_v2.sql` sửa trên nền `before_v2.sql` của `master2`, ...).
   - Nếu chưa có hoặc còn thiếu cột/sto → tạo bổ sung (tuyệt đối không copy nguyên `04_deploy_v3.sql` đè sang v2) và cập nhật `tasks/<task>/DEPLOY_CHECKLIST.md`.

### Bước 5 — Tự kiểm tra & Bàn giao Tester
1. Chạy `git diff` trên nhánh đích:
   - So sánh với `git show <commit_id>` để đảm bảo không sót đoạn nào và không xóa nhầm code riêng của nhánh đích.
2. Báo cáo rõ cho người dùng:
   - Các file đã port thành công.
   - Các điểm phải điều chỉnh cho phù hợp nhánh đích (nếu có).
   - Nhắc chạy `verify-task` trên nhánh đích trước khi push.
