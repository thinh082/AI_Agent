# NHÁP KHỞI TẠO GLOSSARY — HisSoft (v2 / v3)

- **Ngày tạo:** 2026-11-26
- **Nguồn quét (read-only):** `C:\Project\HisSoft4\HisSoft` (`HissoftContext.cs`, `Models/Entities/*.cs`, `Views/QL_TiepNhanBenhNhan`, `Views/QL_KhamBenh`, `Views/QL_TaiChinh`) + đối chiếu `master_2` vs `master_3` tại `C:\Project\HisSoft`.
- **Trạng thái:** Nháp — chờ người dùng duyệt (`duyệt hết` / `bỏ dòng ...` / `sửa dòng ...`) bằng skill `add-knowledge` trước khi đưa vào `GLOSSARY.md`.
- **Quy ước:** Ô `?` = chưa xác nhận trực tiếp từ UI/DB của bản đó (không đoán).

| Thuật ngữ | Viết tắt | UI `id` / `name` | DTO / C# | DB v3 (`Bảng.Cột`) | DB v2 (`Bảng.Cột`) | Tránh dùng | Ghi chú |
|---|---|---|---|---|---|---|---|
| Bệnh nhân | BN | `?` | `DmBenhNhan` | `DM_BenhNhan` | `DM_BenhNhan` | Patient | Bảng danh mục gốc bệnh nhân |
| ID Bệnh nhân | IDBN | `?` | `DmBenhNhan.Id` · `QlVaoVien.Idbn` · `QlChiDinh.IdbenhNhan` · `KskKhamSucKhoeDinhKy.IdBenhNhan` | `DM_BenhNhan.ID` · `QL_VaoVien.IDBN` · `QL_ChiDinh.IDBenhNhan` | Giống v3 | `PatientId` | **Lệch tên giữa các bảng:** `IDBN` vs `IDBenhNhan` vs `IdBenhNhan` |
| Mã bệnh nhân | MaBN | `Mabn` (TiepNhan) | `DmBenhNhan.MaBn` | `DM_BenhNhan.MaBN` | `DM_BenhNhan.MaBN` | `PatientCode` | UI dùng `Mabn` (b thường) |
| Họ tên bệnh nhân | TenBN | `Tenbn` / `hoTen` (TiepNhan) · `TenBn` (TaiChinh) | `DmBenhNhan.TenBn` · `KskKhamSucKhoeDinhKy.HoTen` · `KskLaiXe.HO_TEN` | `DM_BenhNhan.TenBN` · `KSK_KhamSucKhoeDinhKy.HO_TEN` · `KSK_LaiXe.HO_TEN` | Giống v3 | `FullName` | **Lệch tên mạnh** giữa DM (`TenBN`) và KSK (`HO_TEN`) |
| Số CCCD | CCCD | `SoCCCD` (TiepNhan) | `DmBenhNhan.SoCccd` · `KskKhamSucKhoeDinhKy.SoCccd` · `KskLaiXe.SO_CCCD` | `DM_BenhNhan.SoCCCD` · `KSK_LaiXe.SO_CCCD` | Giống v3 | `CMND`, `IdentityNo` | KSK lái xe dùng `UPPER_SNAKE_CASE` |
| Số điện thoại | SĐT | `SoDienThoai` (TiepNhan) | `DmBenhNhan.DienThoai` | `DM_BenhNhan.DienThoai` | `DM_BenhNhan.DienThoai` | `Phone` | UI `SoDienThoai` ≠ DB `DienThoai` |
| Giới tính | GT | `IdgttraVe` (BHYT) | `DmBenhNhan.Idgt` | `DM_BenhNhan.IDGT` → `DM_GioiTinh.ID` | `DM_BenhNhan.IDGT` | `Gender` | |
| Hồ sơ vào viện / Lượt khám | VV / HSVV | `?` | `QlVaoVien` | `QL_VaoVien` | `QL_VaoVien` | `Visit`, `Encounter` | Mỗi lượt khám/điều trị tạo 1 dòng `QL_VaoVien` |
| Mã vào viện | MaVV | `?` | `QlVaoVien.MaVaoVien` | `QL_VaoVien.MaVaoVien` | `QL_VaoVien.MaVaoVien` | `MaHoSo` | |
| Ngày giờ vào viện | — | `NgayGioVaoVien` (HoSoVaoVien) | `QlVaoVien.NgayGioVaoVien` | `QL_VaoVien.NgayGioVaoVien` | `QL_VaoVien.NgayGioVaoVien` | `NgayVao` | |
| Đã ra viện | — | `?` | `QlVaoVien.DaRaVien` | `QL_VaoVien.DaRaVien` | `QL_VaoVien.DaRaVien` | `IsDischarged` | Default `0` |
| Mã loại khám chữa bệnh | MaLoaiKCB | `MaLoaiKcb` (HoSoVaoVien) | `QlVaoVien.MaLoaiKcb` · `QlPhieuSinhHieu.MaLoaiKcb` | `QL_VaoVien.MaLoaiKCB` | `QL_VaoVien.MaLoaiKCB` | `LoaiKham` | Cột mã KCB theo BHYT |
| Quầy tiếp nhận | Quầy | `MaQuay` / `quayTiepNhan` | `QlVaoVien.MaQuay` | `QL_VaoVien.MaQuay` | `QL_VaoVien.MaQuay` | `Counter` | |
| Thẻ bảo hiểm y tế | BHYT | `MaThe` / `MatheBHYT` (TiepNhan) | `QlTheBhyt` (`MaThe`) | `QL_TheBHYT.MaThe` | `QL_TheBHYT.MaThe` | `InsuranceCard` | |
| Mã đăng ký ban đầu | MaDKBD | `MaDkbd` (TiepNhan) | `QlTheBhyt.MaDkbd` | `QL_TheBHYT.MaDKBD` | `QL_TheBHYT.MaDKBD` | `MaCSKCB` | Nơi đăng ký KCB ban đầu trên thẻ BHYT |
| Mã số BHXH | BHXH | `MaSoBhxh` (TiepNhan) | `QlTheBhyt.MaSoBhxh` · `DmBenhNhan.MaBhxh` (v3) | `QL_TheBHYT.MaSoBHXH` · `DM_BenhNhan.MaBhxh` | `QL_TheBHYT.MaSoBHXH` *(chưa có trên `DM_BenhNhan`)* | `SocialNo` | **Khác v2/v3:** `DmBenhNhan.MaBhxh` chỉ có ở `master_3` |
| Ngày miễn cùng chi trả | CCT | `NgayMienCCT` (TiepNhan) | `QlTheBhyt.NgayMienCct` | `QL_TheBHYT.NgayMienCCT` | `QL_TheBHYT.NgayMienCCT` | — | |
| Phiếu chẩn đoán | CĐ | `FormTTChanDoan` | `QlChanDoan` | `QL_ChanDoan` | `QL_ChanDoan` | `Diagnosis` | Chi tiết ở `QL_ChanDoanCT` |
| Mã bệnh ICD | ICD | `cbICD` / `cbICDYHCT` | `DmIcd` · `QlChanDoan.MaBenhChinh` | `DM_ICD` · `QL_ChanDoan.MaBenhChinh` | Giống v3 | `DiseaseCode` | Bệnh YHCT dùng `DM_ICD_YHCT` |
| Phiếu chỉ định dịch vụ | CĐDV | `?` | `QlChiDinh` / `QlChiDinhCt` | `QL_ChiDinh` / `QL_ChiDinhCT` | Giống v3 | `Order` | |
| Dịch vụ kỹ thuật | DVKT | `?` | `DmDichVuKyThuat` (`MaDichVu`, `TenDichVu`) | `DM_DichVuKyThuat` | `DM_DichVuKyThuat` | `Service` | Cột giá: `GiaTrongGio`, `GiaNgoaiGio`, `GiaBanDem` |
| Toa thuốc / Đơn thuốc | Toa | `MaLoaiDonThuoc` (KhamBenh) | `QlToaThuoc` / `QlToaThuocCt` | `QL_ToaThuoc` / `QL_ToaThuoc_CT` | Giống v3 | `Prescription` | |
| Thu tiền / Tài chính | TC | `TaiChinh.cshtml` (`cbNguoiThu`, `PhaiTra`) | `QlTaiChinh` / `QlTaiChinhCt` | `QL_TaiChinh` / `QL_TaiChinhCT` | Giống v3 | `Billing`, `Invoice` | Số chứng từ: `SoChungTu`; cờ hủy: `DaHuy` |
| Tạm ứng | TƯ | `TienTamUng` (TaiChinh) | `QlTamUng` | `QL_TamUng` | `QL_TamUng` | `Deposit` | Sử dụng tạm ứng ở `QL_SuDungTamUngCT` |
| Phiếu hoàn trả | HT | `?` | `QlPhieuHoanTra` | `QL_PhieuHoanTra` | `QL_PhieuHoanTra` | `Refund` | |
| Phiếu sinh hiệu | SH | `TTSinhHieu` (TiepNhan) | `QlPhieuSinhHieu` / `QlPhieuSinhHieuCt` | `QL_PhieuSinhHieu` / `QL_PhieuSinhHieu_CT` | Giống v3 | `VitalSign` | |
| Bệnh án | BA | `?` | `QlBenhAn` (`MaLuuTru`, `DaKy`) | `QL_BenhAn` | `QL_BenhAn` | `MedicalRecord` | Tờ điều trị: `QL_BenhAn_ToDieuTri` |
| Nội trú giường bệnh | NTG | `?` | `QlNoiTruGiuong` / `DmGiuongBenh` | `QL_NoiTru_Giuong` / `DM_GiuongBenh` | Giống v3 | `Bed` | |
| Cận lâm sàng | CLS | `?` | `ClsPhieuCl` / `ClsPhieuClsCt` | `CLS_PhieuCLS` / `CLS_PhieuCLS_CT` | Giống v3 | `Paraclinical` | Chẩn đoán hình ảnh, siêu âm, nội soi... |
| Xét nghiệm | XN | `?` | `ClsPhieuXn` / `ClsPhieuXnct` | `CLS_PhieuXN` / `CLS_PhieuXNCT` | Giống v3 | `LabTest` | Liên kết máy XN: `CLS_PhieuXN_May` |
| Khám sức khỏe định kỳ | KSK ĐK | `?` | `KskKhamSucKhoeDinhKy` | `KSK_KhamSucKhoeDinhKy` | `KSK_KhamSucKhoeDinhKy` | `HealthCheck` | **Khác v2/v3:** cột `DaGuiTinh` có ở `master_3`, chưa có ở `master_2` |
| Khám sức khỏe lái xe | KSK LX | `?` | `KskLaiXe` | `KSK_LaiXe` | `KSK_LaiXe` | — | Cột C# và DB đều viết `UPPER_SNAKE_CASE` (`HO_TEN`, `SO_CCCD`) |
| Hàng hóa / Thuốc / VTYT | HH | `?` | `HhDmHangHoa` (`MaHangHoa`, `TenHangHoa`) | `HH_DM_HangHoa` | `HH_DM_HangHoa` | `Product`, `Medicine` | Gồm thuốc tân dược, YHCT, VTYT, máu |
| Kho hàng / Kho dược | Kho | `cbKhoKeToa` (KhamBenh) | `HhDmKhoHang` (`MaKhoHang`, `TenKhoHang`) | `HH_DM_KhoHang` | `HH_DM_KhoHang` | `Warehouse` | |
| Phiếu nhập kho | PNK | `?` | `HhPhieuNhapKho` / `HhPhieuNhapKhoCt` | `HH_PhieuNhapKho` / `HH_PhieuNhapKho_CT` | Giống v3 | `StockIn` | |
| Phiếu xuất kho | PXK | `?` | `HhPhieuXuatKho` / `HhPhieuXuatKhoCt` | `HH_PhieuXuatKho` / `HH_PhieuXuatKho_CT` | Giống v3 | `StockOut` | |
| Khoa | Khoa | `cbKhoa` (TaiChinh) · `IdKhoaHienTai` (KhamBenh) | `DmKhoa` (`MaKhoa`, `TenKhoa`) | `DM_Khoa` | `DM_Khoa` | `Department` | |
| Phòng buồng | Phòng | `IdPhong` (TiepNhan) · `IdPhongBuong` (KhamBenh) | `DmPhongBuong` (`MaPhong`, `TenPhong`) | `DM_PhongBuong` | `DM_PhongBuong` | `Room` | UI lúc dùng `IdPhong`, lúc dùng `IdPhongBuong` |
| Nhân viên / Bác sĩ | NV / BS | `IdBacSi` (KhamBenh) | `DmNhanVien` (`MaNhanVien`, `TenNhanVien`, `Macchn`) | `DM_NhanVien` | `DM_NhanVien` | `Staff`, `Doctor` | Mã chứng chỉ hành nghề: `Macchn` |
| Hóa đơn điện tử | HĐĐT | `SoHD`, `KyHieuHd`, `NgayXuat` (TaiChinh) | `QlHoaDonDo` / `QL_HoaDonDienTuMisa` | `QL_HoaDonDo` | `QL_HoaDonDo` | `EInvoice` | Tích hợp MISA / hóa đơn mới |
| Liên thông XML / QĐ 130 | XML130 | `?` | `QlKetQuaXml` · `QL_QD130Controller` | `QL_KetQuaXML` | `QL_KetQuaXML` | `XML4210` | Gửi cổng giám định BHYT |
| Tiêm chủng Quốc gia | TCQG | `?` | `DmBenhNhan.MaDoiTuongTCQG` · `QL_TiemChungQuocGiaController` | `DM_BenhNhan.MaDoiTuongTCQG`, `*IdTinh/*IdXa` | *(chưa có ở v2)* | — | **Khác v2/v3:** nhóm cột TCQG & QĐ 159 mới có ở `master_3` |
| Ký số văn bản | KS | `?` | `QlKySo` · `HT_KySoVanBanController` | `QL_KySo` | `QL_KySo` | `DigitalSign` | |

---

## Các điểm lệch tên đáng chú ý (Cần lưu ý khi code & port v2 ↔ v3)

1. **Lệch tên khóa ngoại Bệnh nhân giữa các bảng:**
   - `QL_VaoVien`, `QL_TheBHYT`, `QL_PhieuSinhHieu`: `IDBN` (`Idbn`)
   - `QL_ChiDinh`, `QL_ToaThuoc`, `QL_TaiChinh`, `QL_ChanDoan`: `IDBenhNhan` (`IdbenhNhan`)
   - `KSK_KhamSucKhoeDinhKy`, `KSK_LaiXe`: `IdBenhNhan`
2. **Lệch kiểu đặt tên giữa module chung và KSK:**
   - `DM_BenhNhan`: `TenBN`, `SoCCCD`, `NgaySinh` (`PascalCase`)
   - `KSK_KhamSucKhoeDinhKy`: C# `PascalCase` (`HoTen`, `SoCccd`), DB `UPPER_SNAKE_CASE` (`CAN_NANG`, `CHIEU_CAO`...)
   - `KSK_LaiXe`: Cả C# lẫn DB đều dùng `UPPER_SNAKE_CASE` (`HO_TEN`, `SO_CCCD`, `NGAY_SINH`)
3. **Lệch giữa UI `name` và C#/DB:**
   - `TiepNhanBenhNhan.cshtml`: `Mabn` (C# `MaBn`, DB `MaBN`), `Tenbn` / `hoTen` (C# `TenBn`, DB `TenBN`), `SoDienThoai` (DB `DienThoai`), `MatheBHYT` / `MaThe`
   - `HoSoVaoVien.cshtml` dùng `IdPhong`, trong khi `QL_KhamBenh` dùng `IdPhongBuong`
4. **Khác biệt thực tế giữa `master_2` (v2) và `master_3` (v3) trong `C:\Project\HisSoft`:**
   - Tên nhánh gốc thực tế của repo HisSoft là **`master_2` / `master_3`** (có dấu gạch dưới `_`), khác với `master2` / `master3` đang ghi trong `AGENTS.md` và `map-project` / `ask-map`.
   - `master_3` đã thêm nhiều cột chưa có ở `master_2`: trên `DM_BenhNhan` (`IdNoiLamViec`, `IDDoiTuongPhi`, `DiaChiTamTru`, `MaBhxh`, nhóm cột `TCQG` theo QĐ 159), trên `KSK_KhamSucKhoeDinhKy` (`DaGuiTinh`), và các bổ sung trên `QL_VaoVien`, `QL_TaiChinh`, `QL_ToaThuoc`, `QL_ChiDinh`, `QL_ChanDoan`.
