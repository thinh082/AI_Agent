# X??? — Form KSK có 2 tầng validator khi bấm Lưu tab (.btn-save-tab)

- **Loại:** Pitfall
- **Tag:** `#ui` `#validate` `#ksk` `#ajax`
- **Áp dụng:** `v2+v3`
- **Trạng thái:** Nháp
- **Ngày kiểm chứng:** 2026-11-26 (v3 nhánh `Thinh_SuaKSK_M3`; v2 `origin/master_2` có đủ các hàm cùng tên)
- **Nguồn:** `KSK_LoaiKham` (lỗi TC5) — **Người duyệt:** ...

## Khi nào dùng
- Task đụng trường bắt buộc (`kskTruongBatBuocTheoMau`), nhãn bắt buộc (`.ksk-required-label`, dấu `*`), hoặc ẩn/hiện khối bằng `.d-none` trên form KSK.

## Nội dung
- **Triệu chứng:** thêm nhóm radio bắt buộc + ẩn 1 bảng bằng `.d-none` → nút "Lưu cận lâm sàng" bị chặn hoàn toàn, báo thiếu các ô không bắt buộc / đang ẩn.
- **Nguyên nhân:** bấm `.btn-save-tab` chạy **2 bộ validator**:
  1. `validateKskSectionsByTab` (chạy trước) → `laControlKskCanKiemTra` → `laTruongBatBuocKsk` → `timNhanTruongBatBuocKsk` — ở `KSK_KhamSucKhoeDinhKy2.js`.
  2. `laControlCoTheKiemTraTruocKhiLuuKsk` / `laTruongCoDauSaoKsk` — ở `KSK_SaveTabHandler2.js`.
  - `timNhanTruongBatBuocKsk` dò nhãn ngược lên tối đa 6 cấp → nhãn bắt buộc đặt ngay trước bảng bị "rò" xuống các ô của bảng.
  - `laControlKskCanKiemTra` không loại control (kể cả TomSelect) nằm trong `.d-none` như bộ (2).
- **Cách tránh:** Planner phải đọc **cả 2 bộ** khi lập plan; plan ghi rõ cách chặn rò nhãn và bỏ qua control trong `.d-none` ở **cả 2** nơi. Tester test case "đang ẩn 1 khối + lưu".

## Tham chiếu code thật
| Version | File | Class.Method / Tên STO |
|---|---|---|
| v3 | `HisSoft/wwwroot/dist/js/KSK_KhamSucKhoeDinhKy/KSK_KhamSucKhoeDinhKy2.js` | `validateKskSectionsByTab`, `laControlKskCanKiemTra`, `laTruongBatBuocKsk`, `timNhanTruongBatBuocKsk`, `xoaTrangTriTruongBatBuocKsk` |
| v3 | `HisSoft/wwwroot/dist/js/KSK_KhamSucKhoeDinhKy/KSK_SaveTabHandler2.js` | `laControlCoTheKiemTraTruocKhiLuuKsk`, `laTruongCoDauSaoKsk` |
| v2 | (cùng 2 file) | cùng tên hàm — đối chiếu thân hàm khi port |

## Khác biệt v2 / v3
- Tên hàm giống nhau; thân hàm có thể lệch — mở file thật.

## Cấm / Lưu ý
- `xoaTrangTriTruongBatBuocKsk` xoá class `ksk-required-group` gắn tĩnh trong HTML → khai báo trường bắt buộc qua `kskTruongBatBuocTheoMau`.

## Lịch sử dùng
| Ngày | Task | Điểm |
|---|---|---|
