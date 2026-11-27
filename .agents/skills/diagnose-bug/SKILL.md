---
name: diagnose-bug
description: Chẩn đoán bug (read-only) trước khi lên plan sửa. Bắt buộc tái hiện được bug trên Orca browser (có tín hiệu đỏ) rồi mới đưa giả thuyết, kiểm chứng nguyên nhân gốc bằng cách chỉ đọc, xuất BUG_REPORT.md và kịch bản tái hiện để plan-task lên plan sửa.
---

# Skill: `diagnose-bug` (Chẩn đoán Bug — Read-only)

> **BẮT BUỘC — đọc trước, không được quên:**
> 1. **Read-only**: không sửa code, không build, không `EXEC` sto, không chạy SQL ghi. Chỉ thao tác trên app **Dev**, tạo dữ liệu chỉ qua UI.
> 2. Chưa tái hiện được bug (chưa có **tín hiệu đỏ**) → **không đưa giả thuyết**, DỪNG xin thêm thông tin.
> 3. Cần thêm log / debug tạm vào code → **hỏi người dùng**, không tự sửa.
> 4. Che dữ liệu nhạy cảm (`<REDACTED>`); không lưu mật khẩu.
> 5. Kết quả bắt buộc: `BUG_REPORT.md` (nguyên nhân gốc + bằng chứng) + nháp kịch bản tái hiện.

## Khi nào dùng
- Task là **sửa bug** (người dùng báo "lỗi / sai / không chạy / chậm"). Chạy **trước** `plan-task`, có thể ngay trong phiên Planner.
- Không dùng cho task thêm / đổi chức năng.

## Nguyên tắc (tuân thủ `AGENTS.md`)
- **Read-only:** không sửa code, không tự build / `dotnet run`, không chạy SQL ghi, **không `EXEC` sto**. Chỉ ghi file trong `tasks/<task>/` và nháp trong `KNOWLEDGE_ROOT/_proposed/`.
- **Chỉ thao tác trên app Dev** (`dotnet watch run` trỏ DB Dev/Test). Tạo dữ liệu **chỉ qua UI** trên Dev, đặt tên dễ nhận biết (vd `BN TEST <thời gian>`).
- `SELECT` / `OBJECT_DEFINITION` chỉ khi người dùng đã cho phép đọc DB trong phiên này (Luật 5).
- **Không có tín hiệu đỏ → không đoán nguyên nhân.** Không tái hiện được thì dừng và hỏi.
- Dùng đúng thuật ngữ `GLOSSARY.md`. Che mọi dữ liệu nhạy cảm (`<REDACTED>`) khi trích log / request.

## Bước 0 — Đầu vào
Hỏi 1 lượt những gì còn thiếu: màn hình / chức năng, version (`v2` / `v3` / cả hai), các bước người dùng làm, kết quả đúng mong đợi, kết quả sai thực tế, vai trò tài khoản. Nhắc người dùng **tự đăng nhập** tab Orca bằng tài khoản test (AI không giữ mật khẩu).

## Bước 1 — Tái hiện trên Orca (đây là bước quan trọng nhất)
1. Tìm kịch bản có sẵn trong `KNOWLEDGE_ROOT/e2e/` (theo `INDEX.md`) gần với luồng bị lỗi → dùng làm khung.
2. Thao tác bằng `orca` CLI (`tab create`, `snapshot`, `fill`, `click`, `eval`, `screenshot`), luôn gắn `--page <id>`.
3. Thu **tín hiệu đỏ** cụ thể, không mơ hồ: thông báo lỗi trên màn hình, lỗi JS console, response lỗi (`orca eval` đọc network / console), dữ liệu hiển thị sai so với mong đợi.
4. **Hoàn thành khi:** có chuỗi bước đã **chạy ít nhất 1 lần** và ra đúng tín hiệu đỏ đó (ghi lại bước + bằng chứng).
5. **Không tái hiện được** → DỪNG, liệt kê đã thử gì, xin người dùng: dữ liệu / tài khoản cụ thể, ảnh chụp, thời điểm lỗi, log (đã che dữ liệu nhạy cảm). **Không chuyển sang giả thuyết.**

## Bước 2 — Thu nhỏ
Bỏ bớt bước / dữ liệu cho tới khi còn **ít bước nhất** vẫn ra tín hiệu đỏ. Thử thêm trên version còn lại (nếu có môi trường): bug có ở cả v2 và v3 không?

## Bước 3 — Giả thuyết
1. Lần theo chuỗi gọi bằng skill `ask-map`: endpoint → `Controller.Action` → `Service` → sto / EF entity.
2. Đưa **3–5 giả thuyết**, xếp theo khả năng. Mỗi giả thuyết ghi rõ: *nếu đúng thì kiểm tra X sẽ thấy Y*.
3. Đọc file thật liên quan; với sto, đọc bản snapshot `tasks/<task>/snapshots/before_*.sql` (người dùng xuất từ SSMS) hoặc `OBJECT_DEFINITION` nếu được phép.

## Bước 4 — Kiểm chứng (chỉ đọc)
- Loại dần giả thuyết bằng bằng chứng: tham số gửi đi (`orca eval`), dữ liệu trả về, nhánh code tương ứng, `SELECT` dữ liệu Dev (nếu được phép), so v2 với v3.
- Cần thêm log / debug tạm vào code mới chứng minh được → **dừng hỏi người dùng** (AI không tự sửa code ở bước này).
- **Hoàn thành khi:** chỉ còn 1 nguyên nhân gốc, có bằng chứng trỏ tới đúng file + `Class.Method` / tên sto + đoạn logic.

## Bước 5 — Xuất kết quả & Bàn giao
1. Ghi `tasks/<YYYY-MM-DD>_<TASK_ID>/BUG_REPORT.md`:
   - Triệu chứng · Version bị ảnh hưởng · **Các bước tái hiện tối thiểu** · Tín hiệu đỏ (bằng chứng).
   - **Nguyên nhân gốc** (file + `Class.Method` / sto + đoạn logic) · Các giả thuyết đã loại và lý do.
   - Phạm vi sửa đề xuất (chưa phải plan) · Rủi ro / chỗ khác dùng chung logic đó.
2. Tạo nháp kịch bản tái hiện `KNOWLEDGE_ROOT/_proposed/<YYYY-MM-DD>_<TASK_ID>_E-<slug>.md` theo khuôn `_templates/E2E.md` (từ nay bug này luôn được kiểm tra lại sau khi người dùng duyệt).
3. Bàn giao `plan-task`: **Test Plan bắt buộc có case "chạy lại các bước tái hiện → tín hiệu đỏ không còn"**. Bug sửa thường là `-s` nếu chỉ sửa chức năng đã có; vẫn áp dụng chuông báo (`AGENTS.md` mục 8).
