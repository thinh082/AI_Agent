# DEPLOY CHECKLIST — <TASK_ID>: <Tiêu đề>

- **Ngày:** YYYY-MM-DD
- **Trạng thái Prod:** `[ ] Chưa chạy Prod`  `[ ] Đã chạy master3`  `[ ] Đã chạy master2`
- **Commit `master3`:** `<commit_id>`
- **Commit `master2`:** `<commit_id>`

> **LƯU Ý:** Chạy đúng thứ tự **1 → 5**. Luôn chạy `04_deploy_v3.sql` cho `master3` và `04_deploy_v2.sql` cho `master2` — tuyệt đối không dùng chung 1 file cho cả 2 DB.

---

## Tóm tắt nhanh (để đồng bộ cột `Chi tiết SQL` trên Notion)
- **Sửa STO:** *(chỉ ghi tên sto, mỗi tên 1 dòng)*
  - `...`
- **Thêm cột:** *(dán thẳng lệnh `IF COL_LENGTH(...) ALTER TABLE ...` idempotent)*
  ```sql
  -- IF COL_LENGTH(N'dbo.TenBang', N'TenCot') IS NULL
  -- BEGIN
  --     ALTER TABLE dbo.TenBang ADD TenCot INT NULL;
  -- END;
  ```

---

## Thứ tự chạy trên `master3` (v3)
- [ ] **1. Table / Column:** `01_table_v3.sql` *(hoặc: Không có)*
- [ ] **2. Index / Constraint:** `02_index_v3.sql` *(hoặc: Không có)*
- [ ] **3. Function / View:** `03_func_view_v3.sql` *(hoặc: Không có)*
- [ ] **4. Stored Procedure:** `04_deploy_v3.sql` *(Rollback: `snapshots/before_v3.sql`)*
- [ ] **5. Seed / Config Data:** `05_seed_v3.sql` *(hoặc: Không có)*

## Thứ tự chạy trên `master2` (v2)
- [ ] **1. Table / Column:** `01_table_v2.sql` *(hoặc: Không có)*
- [ ] **2. Index / Constraint:** `02_index_v2.sql` *(hoặc: Không có)*
- [ ] **3. Function / View:** `03_func_view_v2.sql` *(hoặc: Không có)*
- [ ] **4. Stored Procedure:** `04_deploy_v2.sql` *(Rollback: `snapshots/before_v2.sql`)*
- [ ] **5. Seed / Config Data:** `05_seed_v2.sql` *(hoặc: Không có)*

---

## Ghi chú triển khai & Kiểm tra sau deploy
- Backup / Rollback: chạy lại file tương ứng trong `snapshots/before_v3.sql` hoặc `snapshots/before_v2.sql`.
- Smoke test sau deploy: ...
