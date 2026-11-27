# PLAN — <TASK_ID>: <Tiêu đề ngắn>

- **Ngày:** YYYY-MM-DD
- **Nhánh làm trước:** `master3` / `master2`
- **Version áp dụng:** `[ ] master2 (v2)`  `[ ] master3 (v3)` — *Lý do nếu chỉ làm 1 version:* ...
- **Trạng thái Gate 1:** `[ ] Chờ duyệt` / `[ ] Đã duyệt`
- **Kích cỡ:** `-s` / `-m` / `-l` *(do người dùng gắn)*
- **Chuông báo:** `Không` / `Có: <dấu hiệu> → Giữ -s` / `Có: <dấu hiệu> → Nâng -m`
- **Super plan:** `Có` (`+super` — mọi bước dạng bản vá) / `Từng bước` (chỉ các bước đánh dấu `[super]`) / `Không`
- **Combo gợi ý (`AGENTS.md` mục 9):** Planner `<mạnh|tiết kiệm>` · Coder `<mạnh|tiết kiệm + +super>` · Tester `<mạnh|tiết kiệm>` — *lý do: ...*
- **Loại task:** `STO` / `UI` / `API` / `Báo cáo` / `Cổng/Đối tác` / `Khác`
- **Revision kho kiến thức:** `<commit ngắn của repo AI_Agent>` *(thêm `+ chưa commit` nếu có)*
- **Model/CLI Planner (tùy chọn):** ...
- **Phiên bản plan:** `Rev 1` *(tăng khi chạy `update-plan`, xem mục 11)*
- **Phiên Coder:** `<handle — Planner ghi khi bàn giao qua Orca>`
- **Base commit:** `<git rev-parse --short HEAD lúc bàn giao — working tree phải sạch>`
- **Base commit v2:** `<Porter ghi khi bắt đầu port trên nhánh _M2 — bỏ trống nếu không port>`

> **Plan rút gọn cho `-s`:** chỉ bắt buộc điền mục **1, 2A, 7, 9, 10** (+ mục **5** nếu có lưu/gửi dữ liệu). Các mục khác ghi `Bỏ qua (-s)`. Nếu có chuông báo đụng DB/STO → **bắt buộc** điền thêm **2B, 2C, 4, 8**.
> **`-l`:** mục 7 chia theo **Giai đoạn** (mỗi giai đoạn kiểm chứng & commit riêng).

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

## 4. Bản SQL hiện tại (Snapshot) & Diff v2 vs v3 *(bắt buộc nếu đụng sto/view/function)*
- **Đã xuất đủ bản hiện tại từ SSMS:**
  - `[ ] snapshots/before_v2.sql` (từ `master2`)
  - `[ ] snapshots/before_v3.sql` (từ `master3`)
  - **Nguồn xuất:** `[ ] Production` `[ ] Dev` *(Dev → bắt buộc đối chiếu lại Prod ở Pre-Deploy Check)*
  - `[ ] Sto/View/Function mới — không có before` *(rollback bằng `DROP` trong `99_rollback_*.sql`)*
- **Kết quả Diff v2 vs v3:**
  - Giống hệt nhau / Có khác biệt ở các đoạn sau (phải giữ nguyên khi sửa):
    - `v3` có thêm: ...
    - `v2` có riêng: ...

## 5. Bảng Mapping UI ↔ API ↔ DB & Quy tắc Fail-Fast *(bắt buộc nếu lưu/gửi dữ liệu)*

| HTML `id` / `name` | API / DTO Field | DB Column (`Table.Col`) | Kiểu dữ liệu | Ghi chú |
|---|---|---|---|---|
| | | | | |

**Mapping mã / trạng thái (nhất là khi gửi cổng thông tin / API ngoài):**
- Giá trị hợp lệ: `... -> ...`
- **Nhánh `else` / `default` (Fail-Fast):** Báo lỗi `...` và chặn lưu/gửi (KHÔNG gán mã mặc định).

## 6. Phân tích ảnh hưởng (Impact Analysis)

| File / DB Object | v2 | v3 | Caller bị ảnh hưởng | Rủi ro |
|---|---|---|---|---|
| | | | | |

## 7. Các bước thực hiện & Kiến thức áp dụng
| # | Bước (nhỏ, kiểm chứng được) | Mẫu áp dụng (`P/X/D`) | Chưa có mẫu → Cách làm dự kiến & Cách kiểm chứng |
|---|---|---|---|
| 1 | ... | `P001` | — |
| 2 | ... | — | *Cách làm:* ... · *Kiểm chứng:* ... |
| 3 | `[super]` ... | — | Xem bản vá chi tiết bên dưới |

**Bản vá chi tiết cho các bước `[super]`** *(định dạng ở `plan-task` Bước 0 ý 6)*:

````markdown
### Bước N [super] — <Class.Method / tên STO> (<v3|v2>)
- **File:** `<đường dẫn>`
- **Tìm đoạn (copy NGUYÊN VĂN từ file thật, đủ dài để chỉ khớp đúng 1 chỗ):**
  ```csharp
  <đoạn code hiện tại>
  ```
- **Thay bằng / Thêm ngay sau / Thêm ngay trước:**
  ```csharp
  <đoạn code mới hoàn chỉnh — đã áp mẫu P/X, đúng tên GLOSSARY / mapping>
  ```
- **Không đụng:** <logic riêng version / code đồng nghiệp gần đó>
- **Không tìm thấy đoạn trên (hoặc khớp > 1 chỗ) → DỪNG báo người dùng.**
````

> `+super`: thêm tiền tố **`Lô k —`** vào tên bước (mỗi lô 3–5 bước); Planner bàn giao từng lô, mỗi lô một phiên Coder mới.
> Bước chưa có mẫu: Coder được tự chọn *cách code* nhưng **không được sửa ngoài file/hàm của plan** (Luật 1); làm khác dự kiến thì ghi `CODER_NOTES.md`.

## 8. Kế hoạch Script SQL & Rollback
- Thứ tự chạy Prod:
  1. `01_table_*.sql` (nếu có)
  2. `02_index_*.sql` (nếu có)
  3. `03_func_view_*.sql` (nếu có)
  4. `04_deploy_v3.sql` / `04_deploy_v2.sql` (tách riêng theo từng bản `before_*`)
  5. `05_seed_*.sql` (nếu có)
- **Rollback:** Chạy lại `snapshots/before_v3.sql` / `snapshots/before_v2.sql` (sto/view/function đã có) + `99_rollback_v3.sql` / `99_rollback_v2.sql` (cột / index / seed / sto mới).
- **Thứ tự deploy:** Chạy SQL `1 → 5` xong mới deploy code; cột mới `NULL` hoặc có `DEFAULT`.

## 9. Test Plan
- **Case chính (Happy path):** ...
- **Case biên & dữ liệu sai (kiểm tra Fail-Fast):** ...
- **Regression (đảm bảo logic riêng v2/v3 không hỏng):** ...
- **Kịch bản E2E dùng lại (`E/F` trong `KNOWLEDGE_ROOT/e2e/`):** `E001`, `F001` / *Không có*
- **Case tái hiện bug** *(nếu có `BUG_REPORT.md`)*: chạy lại các bước tái hiện → tín hiệu đỏ không còn.

## 10. Câu hỏi mở cần xác nhận trước khi code
- *(Liệt kê mọi cột lệch tên, logic chưa rõ. Nếu không có, ghi "Không có".)*

## 11. Lịch sử thay đổi plan *(skill `update-plan` ghi thêm, không xóa dòng cũ)*
| Rev | Ngày | Thay đổi | Bước ảnh hưởng (MỚI / SỬA / HỦY / HOÀN TÁC) | Lý do / Nguồn | Duyệt |
|---|---|---|---|---|---|
| Rev 1 | YYYY-MM-DD | Plan gốc | — | — | Gate 1 |
