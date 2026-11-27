---
name: ask-map
description: Tra cứu nhanh (read-only) "endpoint / chức năng này gọi sto nào hay dùng EF entity nào" và ngược lại "sto này được gọi ở đâu", tách theo v2/v3. Trả lời ngay từ ENDPOINT_MAP.md đã lưu nếu còn mới, nếu chưa có thì lần theo code thật rồi lưu lại cho lần sau.
---

# Skill: `ask-map` (Tra cứu nhanh Endpoint ↔ STO / Entity)

## Khi nào dùng
Người dùng hỏi kiểu:
- *"Endpoint `/ThuTien/GetDanhSach` đang gọi sto nào?"*
- *"Chức năng Xuất Excel màn Thu tiền code ở đâu, gọi gì?"*
- *"Sto `sp_ThuTien_DanhSach` được gọi ở những chỗ nào?"*
- *"Hàm này dùng sto hay EF thuần?"*

## Nguyên tắc
- **Read-only tuyệt đối:** không sửa code, không `git checkout` / đổi nhánh, không chạy SQL. Chỉ được ghi `graphify-out/<master2|master3>/ENDPOINT_MAP.md` (bộ nhớ đệm tra cứu, đã nằm trong `.git/info/exclude`) và nháp thuật ngữ trong `KNOWLEDGE_ROOT/_proposed/`.
- **Không đoán (Luật 2):** chỉ trả lời tên sto / entity **đã thấy trong code thật**. Không tìm thấy → nói rõ *"không tìm thấy"*, kèm chỗ đã tìm.
- **Không đọc** `appsettings*.json` / `Web.config` / `.env` (Luật 5).
- **Trả lời ngắn trước, chi tiết sau:** dòng đầu là câu trả lời thẳng (*"Gọi sto `sp_X`"* / *"EF thuần: `_context.ThuTien`"*), sau đó mới là chuỗi gọi.

## Quy trình

### Bước 1 — Xác định version
1. Người dùng nói rõ `v2` / `v3` → dùng đúng version đó.
2. Không nói → xác định nhánh hiện tại tách từ `master2` hay `master3` (cùng cách ở `map-project` Bước 1: so `git rev-list --count <BASE_V2>..HEAD` với `<BASE_V3>..HEAD` — tên thật ở `AGENTS.md` mục 1, dùng `origin/...` nếu thiếu local). Không xác định được → hỏi người dùng.
3. Cần version **không phải nhánh đang đứng** → đọc file bằng `git show <BASE_V2|BASE_V3>:<path>` (vd `git show master_2:Controllers/X.cs`, không checkout).
4. Người dùng hỏi cả 2 version → trả lời từng version và **chỉ rõ chỗ khác nhau**.

### Bước 2 — Tra bộ nhớ đệm `ENDPOINT_MAP.md`
1. Mở `graphify-out/<ver>/ENDPOINT_MAP.md` (chưa có → sang Bước 3).
2. Có dòng khớp → kiểm tra còn mới: `git log -1 --format=%h <ref> -- <các file trong dòng đó>` **trùng** cột `Commit file` → **trả lời ngay** (ghi *"theo map ngày ..."*).
3. Lệch commit (file đã bị sửa) → coi như chưa có, sang Bước 3.

### Bước 3 — Lần theo code thật
1. **Lần đầu dùng trên version này** (mục `Mẫu nhận diện` trong `ENDPOINT_MAP.md` còn trống):
   - Tìm cách dự án gọi DB: ví dụ `CommandType.StoredProcedure`, `EXEC `, `FromSqlRaw` / `FromSqlInterpolated`, `ExecuteSqlRaw`, Dapper `Query` / `Execute` có `commandType`, helper riêng của dự án (vd `CommonServices.ExecSto(...)`), và EF `_context.<DbSet>`.
   - Liệt kê các mẫu tìm thấy kèm 1 ví dụ file + `Class.Method` → **hỏi người dùng xác nhận** → ghi vào mục `Mẫu nhận diện`. Từ lần sau dùng lại, không hỏi nữa.
2. Lần theo chuỗi gọi: **Route / JS gọi AJAX** → `Controller.Action` → `Service.Method` (có thể qua nhiều tầng) → **điểm truy cập DB** (tên sto / DbSet entity / SQL raw).
3. Câu hỏi ngược (*"sto X được gọi ở đâu"*): tìm tên sto trong code, lần ngược lên `Service` → `Controller.Action` → Route; liệt kê **tất cả** chỗ gọi.
4. Chuỗi gọi đứt (gọi động, tên sto ghép chuỗi, reflection) → nói rõ *"đứt tại ..."*, không đoán phần còn lại.
5. Dùng đúng thuật ngữ `GLOSSARY.md` khi trả lời. Thấy 1 khái niệm mang tên khác nhau (UI / DTO / DB, hoặc v2 ≠ v3) mà glossary chưa có → cuối câu trả lời đề xuất và tạo nháp `KNOWLEDGE_ROOT/_proposed/<YYYY-MM-DD>_G-<slug>.md`.

### Bước 4 — Trả lời & Lưu lại
1. Trả lời theo mẫu:
   ```text
   [v3] Gọi sto `sp_ThuTien_DanhSach` (tham số: @TuNgay, @DenNgay, @HinhThucTT)
   Chuỗi gọi: GET /ThuTien/GetDanhSach → ThuTienController.GetDanhSach → ThuTienServices.GetListAsync → sp_ThuTien_DanhSach
   Nguồn: đã kiểm tra code thật (commit a1b2c3d)
   ```
2. Ghi / cập nhật dòng tương ứng trong `graphify-out/<ver>/ENDPOINT_MAP.md` (tạo file theo khung bên dưới nếu chưa có). Không xóa dòng của endpoint khác.

## Khung `ENDPOINT_MAP.md` (tạo khi chưa có)
```markdown
# ENDPOINT_MAP — <master2|master3>
> Bộ nhớ đệm của skill `ask-map`. Chỉ để tra nhanh — sai lệch với code thật thì code thật là đúng.

## Mẫu nhận diện truy cập DB (người dùng đã xác nhận)
| Kiểu | Mẫu trong code | Ví dụ (File + Class.Method) |
|---|---|---|

## Bản đồ
| Route / Chức năng | Controller.Action | Service.Method | Truy cập DB (STO / EF Entity / SQL raw) | File liên quan | Commit file | Ngày |
|---|---|---|---|---|---|---|
```
