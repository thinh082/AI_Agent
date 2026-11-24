---
name: port-version
description: Quy trình an toàn để chuyển thay đổi từ một commit_id ở nhánh master3 sang master2 (hoặc ngược lại) mà không ghi đè mất logic riêng của nhánh đích và không thiếu dependency/script SQL.
---

# Skill: `port-version` (Chuyển thay đổi `master2` ↔ `master3`)

## Khi nào dùng
Sau khi bạn đã hoàn thành + commit + push task trên 1 nhánh (vd `master3`), lấy `<commit_id>`, chuyển git sang nhánh còn lại (vd `master2`) và muốn AI đem thay đổi đó sang nhánh đích một cách an toàn.

## Quy trình bắt buộc

### Bước 1 — Kiểm tra nhánh tách & Đọc commit nguồn
1. Kiểm tra `git branch --show-current`:
   - **TUYỆT ĐỐI KHÔNG sửa trực tiếp trên `master2` hoặc `master3`.**
   - Phải đảm bảo đang đứng trên **nhánh tách mới** từ nhánh đích mới nhất (vd: `git checkout master2 && git pull && git checkout -b feat/<TASK_ID>-v2`), working tree sạch. Nếu đang đứng trên `master2`/`master3` → tạo nhánh tách trước khi sửa.
2. Chạy `git show <commit_id>` để đọc toàn bộ diff (từng file, từng dòng thêm/xóa) và commit message.
3. **KHÔNG đọc** `appsettings*.json` / `Web.config` / `.env` trừ khi người dùng cho phép. **KHÔNG BAO GIỜ chạy `git push`.**

### Bước 2 — Kiểm tra tương thích trên nhánh đích (BẮT BUỘC trước khi sửa)
Với từng file bị ảnh hưởng trong `<commit_id>`:
1. Mở file tương ứng trên nhánh đích và so sánh phần ngữ cảnh xung quanh chỗ cần sửa:
   - File có tồn tại ở đúng đường dẫn không?
   - Nhánh đích có **logic riêng của version** (vd: v2 có đoạn xử lý riêng cho khách hàng cũ) nằm gần chỗ cần sửa không?
2. **Kiểm tra Dependency:** Mọi hàm helper, class, cột DB, tham số sto, hoặc config mà `<commit_id>` gọi tới **có tồn tại trên nhánh đích không**?
3. **Nếu phát hiện xung đột logic hoặc thiếu dependency trên nhánh đích → DỪNG LẠI báo rõ cho người dùng** trước khi sửa. Không tự ý chế hoặc xóa code riêng của nhánh đích.

### Bước 3 — Áp dụng thay đổi (Patch-Only)
1. Chỉ áp dụng đúng thay đổi nghiệp vụ của `<commit_id>` lên nhánh đích.
2. **Tuyệt đối giữ nguyên** mọi code riêng của nhánh đích (không mang nhầm code đặc thù của v3 sang v2 hoặc ngược lại).
3. Tuân thủ đủ **4 luật Zero-Tolerance** (không đoán mò, không silent fallback, Fail-Fast ở `else`/`default`, không xóa hàm ngoài phạm vi).

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
