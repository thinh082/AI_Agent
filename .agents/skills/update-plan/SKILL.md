---
name: update-plan
description: Cập nhật PLAN.md giữa chừng khi task đang làm (yêu cầu đổi, Coder dừng vì thực tế khác plan, Tester FAIL do plan thiếu, Porter thấy v2 khác). Tăng Rev, đánh dấu bước MỚI / SỬA / HỦY (kèm hoàn tác), xin duyệt lại phần thay đổi rồi báo phiên Coder làm tiếp.
---

# Skill: `update-plan` (Cập nhật Plan giữa chừng — Planner)

## Khi nào dùng
Người dùng nói *"Cập nhật plan <TASK_ID>: <thay đổi>"*, thường trong phiên Planner. Các tình huống:
- Người dùng đổi / thêm yêu cầu khi task đang làm.
- Coder **DỪNG** vì code thật khác plan (đoạn gốc `[super]` không thấy, thiếu cột, lệch tên...).
- Tester **FAIL** do plan thiếu case / thiếu bước.
- Porter thấy nhánh đích (v2) khác, cần bước riêng.

## Nguyên tắc
- Planner vẫn **read-only với code**: chỉ sửa `PLAN.md` (+ `snapshots/` nếu người dùng dán sto mới, xem `plan-task` Bước 1). Không sửa code, không chạy SQL ghi, không đổi nhánh.
- **Không xóa lịch sử plan.** Bước bị hủy giữ lại (gạch ngang) để Tester đối chiếu.
- Bước đã code mà nay bị hủy → phải có **bước hoàn tác** rõ ràng (file + `Class.Method` / STO + đoạn cần gỡ). Đây là lý do hợp lệ duy nhất để code bị xóa qua Cổng 1 (Luật 1).
- Áp dụng lại đầy đủ quy tắc `plan-task` cho **phần thay đổi**: bảng mapping, `GLOSSARY.md`, snapshot v2/v3 cho STO mới, chuông báo, định dạng `[super]`.

## Quy trình

### Bước 1 — Đọc hiện trạng (chỉ đọc)
1. `tasks/<task>/PLAN.md` (Rev mới nhất), `CODER_NOTES.md`, `TEST_REPORT.md` (nếu có).
2. Tiến độ code trên nhánh của task: `git status`, `git diff --stat`, `git log --oneline <nhánh gốc>..HEAD` → xác định bước nào **đã làm** / **chưa làm**.

### Bước 2 — Phân loại thay đổi
- **Trong phạm vi task** → cập nhật plan.
- **Phạm vi mới lớn** (chức năng khác, module khác) → đề xuất **tách task mới**, hỏi người dùng.
- Thay đổi làm task nặng hơn (vd `-s` giờ đụng STO) → hỏi có **nâng kích cỡ** không (không tự nâng).

### Bước 3 — Viết Rev mới vào `PLAN.md`
1. Tăng `Phiên bản plan: Rev N` ở đầu file; đổi `Trạng thái Gate 1` thành `Chờ duyệt (Rev N)`.
2. Mục 7: đánh dấu từng bước bị ảnh hưởng:
   - `[Rev N: MỚI]` bước thêm mới.
   - `[Rev N: SỬA]` bước đổi cách làm (ghi rõ đã làm chưa: nếu đã code → nêu phần phải sửa lại).
   - `~~bước cũ~~ [Rev N: HỦY]` + bước `[Rev N: HOÀN TÁC]` nếu bước đó đã được code.
3. Cập nhật mục liên quan khác: mapping (5), script SQL (8) — thêm / bỏ file `0x_*_v2/v3.sql`, Test Plan (9), câu hỏi mở (10).
4. Thêm 1 dòng vào mục **11. Lịch sử thay đổi plan**: `Rev | Ngày | Thay đổi | Bước ảnh hưởng | Lý do / Nguồn (người dùng / Coder / Tester / Porter) | Duyệt`.
5. Có file HTML plan → đồng bộ cùng nội dung.

### Bước 4 — Xin duyệt phần thay đổi (Gate 1 rút gọn)
Tóm tắt ngắn cho người dùng: các bước MỚI / SỬA / HỦY / HOÀN TÁC, script SQL thêm / bỏ, ảnh hưởng v2 / v3. **DỪNG chờ** người dùng gõ *"duyệt rev N"*.

### Bước 5 — Báo phiên Coder làm tiếp
1. Ghi `Trạng thái Gate 1: Đã duyệt (Rev N, YYYY-MM-DD)`.
2. `PLAN.md` có dòng `Phiên Coder: <handle>` (ghi lúc bàn giao ở `plan-task` Bước 6):
   - Gửi cho phiên đó (soạn nội dung vào file rồi dùng `--body-file`):
     ```text
     orca orchestration send --to <handle> --type dispatch --subject "PLAN Rev N - <TASK_ID>" --body-file <file> --json
     ```
     Nội dung: *"PLAN Rev N đã duyệt. Đọc lại toàn bộ tasks/<task>/PLAN.md, làm các bước đánh dấu Rev N (MỚI / SỬA / HOÀN TÁC), cập nhật DEPLOY_CHECKLIST.md nếu script đổi."*
   - Không gửi được (phiên đã đóng / không có handle) → mở phiên Coder mới theo `plan-task` Bước 6 với prompt trên, ghi lại handle mới.
3. Tester đã chạy trước đó → nhắc người dùng **chạy lại `verify-task`** sau khi Coder xong.
4. Task đã qua Gate 2 (đã commit / push) → thay đổi đi thành **commit mới** trên cùng nhánh; nhắc Porter phải port cả commit này.
