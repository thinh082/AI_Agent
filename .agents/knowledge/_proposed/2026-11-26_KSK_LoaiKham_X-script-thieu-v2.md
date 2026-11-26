# X??? — Task v2+v3 nhưng Coder chỉ sinh script SQL *_v3.sql

- **Loại:** Pitfall
- **Tag:** `#sto` `#deploy` `#quy-trinh`
- **Áp dụng:** `v2+v3`
- **Trạng thái:** Nháp
- **Ngày kiểm chứng:** 2026-11-26
- **Nguồn:** `KSK_LoaiKham` — **Người duyệt:** ...

## Khi nào dùng
- Mọi task áp dụng cả v2 + v3 có script SQL.

## Nội dung
- **Triệu chứng:** Coder chỉ tạo bộ `*_v3.sql`, ghi "v2 sẽ xử lý ở phiên port riêng" dù `PLAN.md` áp dụng cả 2 và đã có `snapshots/before_v2.sql` → phải quay lại bổ sung `01/02/04/99_*_v2.sql`.
- **Nguyên nhân:** mục 7/8 của plan không ghi rõ "sinh đủ 2 bộ ngay vòng đầu"; Coder hiểu port = cả SQL.
- **Cách tránh:** Planner ghi 1 dòng ở mục 7 **và** 8: *"Coder sinh đủ `*_v3.sql` + `*_v2.sql` (mỗi bản dựng trên `before_` của version đó) và điền đủ 2 mục v2/v3 trong `DEPLOY_CHECKLIST.md` ngay vòng đầu; Porter chỉ port code."* Tester kiểm đủ 2 bộ ở Cổng SQL.
- Đề xuất cân nhắc thêm dòng này vào `.agents/templates/PLAN.md` mục 8 (người dùng duyệt).

## Lịch sử dùng
| Ngày | Task | Điểm |
|---|---|---|
