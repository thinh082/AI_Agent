# PLAN — <TASK_ID>: <Tiêu đề ngắn>

- **Ngày:** YYYY-MM-DD
- **Nhánh làm trước:** `master3` / `master2`
- **Version áp dụng:** `[ ] master2 (v2)`  `[ ] master3 (v3)` — *Lý do nếu chỉ làm 1 version:* ...
- **Trạng thái Gate 1:** `[ ] Chờ duyệt` / `[ ] Đã duyệt`

---

## 1. Mục tiêu & Phạm vi
- **Cần làm:** ...
- **KHÔNG làm (out of scope):** ...

## 2. Danh sách chi tiết sẽ sửa (File Code · STO · Bảng/Cột DB)
**A. File Code (Controller / Service / View / JS):**
| File | Hành động | Hàm / Vị trí sửa | v2 / v3 |
|---|---|---|---|
| | | | |

**B. Stored Procedure / View / Function:**
| Tên STO / View / Function | Hành động | Nội dung sửa | v2 / v3 |
|---|---|---|---|
| | | | |

**C. Bảng & Cột Database (SQL Server 2017):**
| Bảng | Cột / Index | Thao tác | Kiểu dữ liệu / Ghi chú |
|---|---|---|---|
| | | | |

## 3. Context & Graphify Blast Radius
- **Graphify / Call graph liên quan:** (màn hình, controller, service, sto gọi nhau)
- **File code thật đã đọc để xác nhận:**
  - `path/to/file1`
  - `path/to/file2`

## 3. Bản SQL hiện tại (Snapshot) & Diff v2 vs v3 *(bắt buộc nếu đụng sto/view/function)*
- **Đã xuất đủ bản hiện tại từ SSMS:**
  - `[ ] snapshots/before_v2.sql` (từ `master2`)
  - `[ ] snapshots/before_v3.sql` (từ `master3`)
- **Kết quả Diff v2 vs v3:**
  - Giống hệt nhau / Có khác biệt ở các đoạn sau (phải giữ nguyên khi sửa):
    - `v3` có thêm: ...
    - `v2` có riêng: ...

## 4. Bảng Mapping UI ↔ API ↔ DB & Quy tắc Fail-Fast *(bắt buộc nếu lưu/gửi dữ liệu)*

| HTML `id` / `name` | API / DTO Field | DB Column (`Table.Col`) | Kiểu dữ liệu | Ghi chú |
|---|---|---|---|---|
| | | | | |

**Mapping mã / trạng thái (nhất là khi gửi cổng thông tin / API ngoài):**
- Giá trị hợp lệ: `... -> ...`
- **Nhánh `else` / `default` (Fail-Fast):** Báo lỗi `...` và chặn lưu/gửi (KHÔNG gán mã mặc định).

## 5. Phân tích ảnh hưởng (Impact Analysis)

| File / DB Object | v2 | v3 | Caller bị ảnh hưởng | Rủi ro |
|---|---|---|---|---|
| | | | | |

## 6. Các bước thực hiện (nhỏ, kiểm chứng được)
1. ...
2. ...

## 7. Kế hoạch Script SQL & Rollback
- Thứ tự chạy Prod:
  1. `01_table_*.sql` (nếu có)
  2. `02_index_*.sql` (nếu có)
  3. `03_func_view_*.sql` (nếu có)
  4. `04_deploy_v3.sql` / `04_deploy_v2.sql` (tách riêng theo từng bản `before_*`)
  5. `05_seed_*.sql` (nếu có)
- **Rollback:** Chạy lại `snapshots/before_v3.sql` / `snapshots/before_v2.sql`.

## 8. Test Plan
- **Case chính (Happy path):** ...
- **Case biên & dữ liệu sai (kiểm tra Fail-Fast):** ...
- **Regression (đảm bảo logic riêng v2/v3 không hỏng):** ...

## 9. Câu hỏi mở cần xác nhận trước khi code
- *(Liệt kê mọi cột lệch tên, logic chưa rõ. Nếu không có, ghi "Không có".)*
