---
name: retro-task
description: Sau khi task qua Gate 2, hỏi người dùng chấm điểm 1-5, ghi 1 dòng vào RETRO_LOG.md, tạo bản nháp kiến thức/lỗi vào _proposed/ khi có bài học dùng lại được; và lệnh "tổng kết" để phân tích nên sửa quy trình, bổ sung kho hay đổi model theo từng vai trò.
---

# Skill: `retro-task` (Chấm điểm & Rút kinh nghiệm)

## Khi nào dùng
- Sau **Gate 2** của nhánh cuối cùng. Task có port → chạy sau khi nhánh port cũng qua `verify-task`.
- **Không bắt buộc**: người dùng có thể bỏ qua. Gõ mỗi con số điểm là đủ.
- Nên chạy ở phiên mới hoặc phiên Tester (cần đọc được `tasks/<task>/` của dự án và ghi được `KNOWLEDGE_ROOT`).

## Nguyên tắc
- `KNOWLEDGE_ROOT` khai báo trong `AGENTS.md` mục 7. Skill này chỉ ghi vào:
  - `retro/RETRO_LOG.md` (**chỉ append**, không sửa/xóa dòng cũ);
  - `_proposed/` (bản nháp);
  - mục `Lịch sử dùng` của các mục P/X/D đã áp dụng (**chỉ thêm dòng**, không đổi nội dung mục).
- **Không tự ghi vào kho chính thức**, không sửa skill / `AGENTS.md`, không sửa code dự án, không chạy SQL, không `git commit` / `git push`.
- **Không quy lỗi khi thiếu bằng chứng**: điểm ≤ 2 phải dựa vào `TEST_REPORT.md`, `git diff` hoặc lời người dùng; không đủ → ghi `Chưa rõ`.
- Không đưa dữ liệu bệnh nhân / cấu hình / connection string vào log hay nháp.

Người dùng nói *"chấm task / retro ..."* → **Chế độ A**. Người dùng nói *"retro tổng kết"* → **Chế độ B**.

---

## Chế độ A — Chấm 1 task

### Bước 1 — Tự thu thập (đọc, không hỏi)
Từ `tasks/<YYYY-MM-DD>_<TASK_ID>/`:
- `PLAN.md`: TASK_ID, kích cỡ, chuông báo, super plan, Rev cuối (mục 11) + lý do các Rev, version áp dụng, loại task, các mã `P/X/D` ở mục **Kiến thức áp dụng**, model Planner (nếu có ghi).
- `CODER_NOTES.md` (nếu có): các bước ngoài khuôn / lệch plan.
- `TEST_REPORT.md` (của từng nhánh): kết luận PASS/FAIL, lỗi đã gặp, model Tester (nếu có ghi).

### Bước 2 — Hỏi người dùng 1 lượt duy nhất
> **Task `<TASK_ID>` — chấm mức hoàn thành 1–5?** *(5 đúng ngay · 4 sửa nhỏ · 3 sửa đáng kể · 2 làm lại phần lớn · 1 hỏng)*
> Tùy chọn: khâu lỗi (Plan/Code/Test/Port), nguyên nhân, model từng vai trò, 1 điều nên giữ hoặc đổi.

- Người dùng chỉ gõ số và điểm **≥ 4** → `Khâu lỗi = Không`, `Nguyên nhân = Không có`.
- Điểm **≤ 3** mà người dùng không nêu nguyên nhân → AI đề xuất `Khâu lỗi` + `Nguyên nhân` (theo danh sách cố định trong `RETRO_LOG.md`) **kèm bằng chứng**, hỏi xác nhận đúng 1 câu. Người dùng không xác nhận → `Chưa rõ`.
- Model chưa có trong file và người dùng không nói → để trống.

### Bước 3 — Ghi `retro/RETRO_LOG.md`
Append đúng 1 dòng theo các cột của bảng `Nhật ký` (dùng đúng giá trị cố định đã quy định ở đầu file).

### Bước 4 — Cập nhật `Lịch sử dùng`
Với mỗi mã `P/X/D` đã gắn trong `PLAN.md`: thêm dòng `| Ngày | TASK_ID | Điểm |` vào mục `Lịch sử dùng` của file tương ứng.

### Bước 5 — Tạo nháp (CHỈ khi có bài học dùng lại được)
Tên file: `_proposed/<YYYY-MM-DD>_<TASK_ID>_<P|X|D|PROCESS>-<slug>.md`, theo khuôn `_templates/ENTRY.md`, `Trạng thái: Nháp`, ghi `Nguồn` = task + điểm.

| Điểm | Khi nào tạo nháp | Loại nháp |
|---|---|---|
| **4–5** | Bước ngoài khuôn trong `CODER_NOTES.md` chạy tốt và có khả năng lặp lại | `P` (ghi rõ đã dùng mấy lần; < 2 lần → ghi `Chờ lần dùng thứ 2`) |
| **4–5** | Mẫu đã gắn cần chỉnh nhỏ cho đúng thực tế | Nháp cập nhật mục cũ (ghi mã mục) |
| **3** | Lộ ra kiến thức còn thiếu (thiếu mẫu / hiểu sai nghiệp vụ) | `P` hoặc `D` ở dạng *"Cần bổ sung"* |
| **Mọi điểm** | Task lộ thuật ngữ mới hoặc tên lệch (UI ≠ DB, v2 ≠ v3) chưa có trong `GLOSSARY.md` | `G` (thuật ngữ) |
| **Mọi điểm** | Luồng Tester đã test chưa có kịch bản trong `e2e/` và có khả năng phải test lại | `E` / `F` (khuôn `_templates/E2E.md`) |
| **1–2** | Có bằng chứng rõ nguyên nhân | `X` (Pitfall) |
| **1–3** | Lỗi do chính quy trình / skill (vd plan template thiếu mục, skill không chặn được lỗi) | `PROCESS` — mô tả vấn đề + đề xuất sửa skill/`AGENTS.md` (**không tự sửa**) |

Không có bài học mới → **không tạo nháp**.

### Bước 6 — Báo lại
- Dòng đã ghi vào `RETRO_LOG.md`.
- Danh sách nháp đã tạo (nếu có) → nhắc chạy `add-knowledge` *"duyệt kho nháp"*.
- Nhắc người dùng commit repo `AI_Agent`.

---

## Chế độ B — Tổng kết (Bảng xếp hạng thật của dự án)
**Chỉ đọc và báo cáo, không sửa bất kỳ file nào.**

1. Đọc `retro/RETRO_LOG.md`. Dưới **5 task** → báo *"chưa đủ dữ liệu để kết luận"*, vẫn in bảng thô.
2. In các bảng (kèm **số task** ở mỗi ô để người dùng biết độ tin cậy):
   - **Coder:** điểm TB theo `model Coder × Loại task` + số lần `Khâu lỗi = Code` + số lần `Nguyên nhân = Không theo mẫu/luật`.
   - **Planner:** điểm TB theo `model Planner` + số lần `Khâu lỗi = Plan`.
   - **Tester:** theo `model Tester` — số lần **Tester PASS nhưng điểm ≤ 2** (để lọt lỗi); tách 2 nhóm **Tester cùng model Coder** vs **khác model Coder**.
   - Phân bố `Nguyên nhân` và `Khâu lỗi` toàn dự án; điểm TB theo `Loại task` và theo `Kích cỡ`.
   - **Cập nhật plan:** task có `Rev ≥ 3`, nguồn Rev hay đến từ đâu (người dùng đổi yêu cầu / Coder dừng / Tester FAIL) → Rev do Coder / Tester phát hiện thường là dấu hiệu `Plan sai/thiếu`.
   - **Super plan:** điểm TB theo `model Coder × Super plan (Có / Từng bước / Không)` → model nhanh + super có theo kịp model mạnh + plan thường không; số lần Coder DỪNG vì không tìm thấy đoạn gốc.
   - **Tiêu chí kích cỡ:** điểm TB của nhóm `Giữ -s` so với `-s` không chuông báo và `Nâng -m` → biết tiêu chí của người dùng hay chuông báo chuẩn hơn.
   - Mục kho: điểm TB của các task có dùng từng mã `P/X/D`; mục có `Ngày kiểm chứng` quá 90 ngày.
3. Kết luận theo quy tắc (chỉ kết luận khi mỗi nhóm so sánh có **≥ 3 task**, nếu không ghi *"chưa đủ dữ liệu"*):
   - **Nhiều model khác nhau cùng sai một kiểu** → lỗi **quy trình hoặc kho** → đề xuất sửa skill hoặc bổ sung kho.
   - **Một model thấp hơn rõ rệt** so với model khác ở **cùng loại task** → đề xuất **đổi model cho vai trò đó**.
   - **`Không theo mẫu/luật` lặp lại ở 1 model** → model không chịu theo khuôn → đề xuất đổi model.
   - **`Thiếu mẫu` / `Hiểu sai nghiệp vụ` chiếm nhiều** → lỗi không do model → in danh sách chủ đề cần học, gợi ý nạp bằng `add-knowledge`.
   - **Tester cùng model để lọt lỗi nhiều hơn khác model** → khuyến nghị bắt buộc khác model cho loại task đó.
   - Mục kho có điểm TB thấp hoặc quá hạn kiểm chứng → đề xuất xem lại mục đó.
   - Nhóm `Giữ -s` điểm thấp rõ rệt → đề xuất người dùng nâng `-m` khi gặp chuông báo đó; ngược lại điểm vẫn cao → đề xuất bỏ dấu hiệu đó khỏi danh sách chuông báo (`AGENTS.md` mục 8).
4. Kết thúc bằng 3–5 hành động ưu tiên cho người dùng (sửa gì, học gì, đổi model nào).
