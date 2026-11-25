---
name: add-knowledge
description: Nạp kiến thức mới (Pattern / Pitfall / Domain / kịch bản E2E) vào kho .agents/knowledge theo khuôn chuẩn, thêm thuật ngữ hoặc khởi tạo GLOSSARY.md, kiểm tra trùng, tách v2/v3; và duyệt các bản nháp trong _proposed/ (duyệt / sửa / bỏ) để AI code theo khuôn của team.
---

# Skill: `add-knowledge` (Nạp & Duyệt Kho Kiến Thức)

## Vị trí kho & Nguyên tắc
- Kho nằm tại `KNOWLEDGE_ROOT` khai báo trong `AGENTS.md` mục 7 (repo `AI_Agent`, **không** nằm trong dự án HIS). Mọi đường dẫn bên dưới tính từ `KNOWLEDGE_ROOT`.
- Skill này **CHỈ được ghi file trong `KNOWLEDGE_ROOT`**. Không sửa code dự án, không sửa skill khác, không chạy SQL.
- **Cấm đưa vào kho:** dữ liệu bệnh nhân, connection string, nội dung `appsettings*.json` / `Web.config` / `.env`, snapshot sto Prod nguyên bản. Code mẫu phải lược bỏ giá trị thật.
- **Không bịa:** code mẫu chỉ lấy từ người dùng cung cấp hoặc từ file thật đã mở đọc. Không có nguồn → ghi rõ `Chưa kiểm chứng với code thật`.
- **Không ghi số dòng** (`path:line`): tham chiếu bằng `đường dẫn file` + `Class.Method` / `tên STO` theo từng version.
- **Không tự `git commit` / `git push`**: xong việc nhắc người dùng commit repo `AI_Agent`.

Skill có 4 chế độ:
- *"thêm kiến thức / ghi lại ..."* (kể cả kịch bản E2E) → **Chế độ A**
- *"duyệt kho nháp"* → **Chế độ B**
- *"thêm thuật ngữ ..."* → **Chế độ C**
- *"khởi tạo glossary"* → **Chế độ D** (chạy trong phiên đang mở dự án HIS)

---

## Chế độ A — Thêm kiến thức do người dùng cung cấp
Kiến thức do chính người dùng đưa vào được coi là đã duyệt, nhưng vẫn phải cho người dùng xem bản soạn trước khi ghi.

1. **Đọc `INDEX.md`**, tìm mục trùng hoặc gần trùng (theo tiêu đề, tag, version).
   - Có mục trùng → đề xuất **cập nhật mục cũ** (không tạo mục mới), nêu rõ phần sẽ thêm/sửa.
2. **Hỏi bổ sung trong 1 lượt** (chỉ hỏi những gì còn thiếu):
   - Loại: Pattern (`P`) / Pitfall (`X`) / Domain (`D`) / Kịch bản E2E (`E` 1 màn hình, `F` luồng nhiều tab)?
   - Áp dụng `v2` / `v3` / `v2+v3`? Hai bản có làm khác nhau không?
   - Có file / hàm / STO tham chiếu trong dự án không?
3. **Nếu có tham chiếu file và đang mở được dự án**: mở file thật, trích đoạn mẫu ≤ 25 dòng (đã lược giá trị nhạy cảm). Không mở được → ghi `Chưa kiểm chứng với code thật`.
4. **Cấp mã**: số kế tiếp của loại đó theo `INDEX.md` (vd đã có `P003` → `P004`).
5. **Soạn theo khuôn** `_templates/ENTRY.md`: `Trạng thái: Chính thức`, `Ngày kiểm chứng` = hôm nay, `Nguồn: người dùng nhập trực tiếp`.
6. **Hiển thị bản soạn → chờ người dùng xác nhận** (`ok` / sửa gì).
7. Sau khi xác nhận:
   - Ghi file `<patterns|pitfalls|domain>/<Mã>-<slug-khong-dau>.md`.
   - Thêm 1 dòng vào đúng bảng trong `INDEX.md`.
   - Kịch bản E2E: dùng khuôn `_templates/E2E.md`, ghi vào `e2e/<Mã>-<slug>.md`. **Không ghi mật khẩu, host/port máy cá nhân, dữ liệu bệnh nhân thật.**
8. **Kiểm tra trần kho**: `INDEX.md` > 80 mục → đề xuất gộp mục nhỏ, hoặc nâng mẫu dùng ở mọi nơi lên `.agents/skills/aspnet-backend/SKILL.md` (chỉ đề xuất, người dùng duyệt mới sửa).

---

## Chế độ B — Duyệt kho nháp (`_proposed/`)
Bản nháp do `retro-task` (hoặc AI khác) tạo ra. **Chỉ người dùng mới quyết định** nháp nào vào kho chính thức.

1. Liệt kê toàn bộ `_proposed/*.md` thành bảng: `File nháp | Loại đề xuất | Tiêu đề | Nguồn (task, điểm) | Số lần đã dùng | Trùng với mục nào trong INDEX`.
2. Với từng nháp, người dùng trả lời 1 trong 4:
   - **`duyệt`**:
     - Nháp loại **Pattern**: chỉ vào `patterns/` khi **đã dùng ≥ 2 lần** (xem `Lịch sử dùng`) **hoặc** người dùng xác nhận chắc chắn sẽ dùng lại. Chưa đủ → hỏi lại người dùng, mặc định giữ ở `_proposed/`.
     - Cấp mã chính thức, đổi `Trạng thái: Chính thức`, cập nhật `Ngày kiểm chứng`, chuyển file vào đúng thư mục, thêm dòng `INDEX.md`, xóa file nháp.
     - Nháp là **cập nhật cho mục đã có** → sửa mục đó, cập nhật `Ngày kiểm chứng`, xóa file nháp.
     - Nháp loại **G** (thuật ngữ) → thêm / sửa dòng trong `GLOSSARY.md` (theo quy tắc Chế độ C), xóa file nháp.
     - Nháp loại **E / F** (kịch bản E2E) → cấp mã, chuyển vào `e2e/`, thêm dòng bảng *Kịch bản E2E* trong `INDEX.md`. Nháp *cập nhật kịch bản* (giao diện đổi) → sửa kịch bản đó.
     - Nháp loại **PROCESS** (đề xuất sửa skill / `AGENTS.md`) → **không tự sửa skill**; tóm tắt đề xuất cho người dùng, chỉ sửa khi người dùng yêu cầu rõ ràng ở bước sau.
   - **`sửa`**: chỉnh theo ý người dùng rồi hỏi lại.
   - **`bỏ`**: xóa file nháp (người dùng đã xác nhận bằng chính lệnh `bỏ`).
   - **`để sau`**: giữ nguyên. Nháp tồn > 30 ngày → nhắc người dùng trong lần duyệt sau.
3. Báo tóm tắt: đã duyệt / sửa / bỏ / giữ bao nhiêu nháp, các mã mới, và nhắc người dùng **commit repo `AI_Agent`**.

---

## Chế độ C — Thêm thuật ngữ vào `GLOSSARY.md`
1. Đọc `GLOSSARY.md`, tìm trùng:
   - **Cùng nghĩa, khác tên** → hỏi người dùng chọn 1 tên chuẩn; tên còn lại đưa vào cột `Tránh dùng`.
   - **Cùng tên, khác nghĩa** → hỏi người dùng tách thành 2 thuật ngữ rõ ràng.
2. Lấy tên UI `id`/`name`, DTO, `Bảng.Cột` v2 / v3 **từ code thật** nếu đang mở được dự án (v2 đọc bằng `git show master2:<path>`, không checkout). Không kiểm chứng được → để `?`, ghi lý do ở cột `Ghi chú`. **Không đoán.**
3. Hiển thị dòng sẽ thêm → người dùng `ok` → ghi vào bảng.
4. Glossary vượt ~150 dòng → đề xuất bỏ thuật ngữ ít dùng hoặc chuyển phần giải thích dài sang `domain/D###`.

## Chế độ D — Khởi tạo glossary (1 lần, trong phiên đang mở dự án HIS)
1. Xác định version đang đứng (cách ở `map-project` Bước 1); version còn lại đọc bằng `git show <master2|master3>:<path>`.
2. Quét **chỉ đọc**: tên menu / màn hình (layout, Views), nhãn các form chính, Model / DTO hay dùng, entity / `DbContext` (tên bảng, cột). **Không** đọc `appsettings*.json` / `Web.config` / `.env`; không truy vấn DB trừ khi được phép (chỉ `SELECT` metadata).
3. Chọn **30–50 thuật ngữ** cốt lõi, xuất hiện nhiều nhất (bệnh nhân, hồ sơ, BHYT, thu tiền, ...). Ô chưa chắc để `?`.
4. Ghi nháp `_proposed/<YYYY-MM-DD>_GLOSSARY-init.md` (cùng cột với `GLOSSARY.md`), kèm danh sách chỗ lệch tên đáng chú ý (UI ≠ DB, v2 ≠ v3).
5. Người dùng duyệt: `duyệt hết` / `bỏ dòng ...` / `sửa dòng ...` → ghi các dòng đã duyệt vào `GLOSSARY.md`, xóa nháp.

## Ranh giới với `aspnet-backend`
- `aspnet-backend/SKILL.md` = **chuẩn nền đúng cho mọi task** (cấu trúc Controller/Service, Response, Transaction, Validation).
- Kho kiến thức = **mẫu theo tình huống cụ thể, lỗi đặc thù, nghiệp vụ HIS**, đọc theo tag.
- Mẫu nào trở thành "dùng ở mọi task" → đề xuất nâng lên `aspnet-backend` và xóa khỏi kho (người dùng duyệt).
