# TEST & AUDIT REPORT — <TASK_ID>

- **Ngày:** YYYY-MM-DD
- **Nhánh kiểm tra:** `master3` / `master2`
- **Commit / Diff:** `<commit_id hoặc working tree>`
- **Kết luận tổng:** `[ ] PASS` / `[ ] FAIL`

---

## Cổng 1 — Deleted-Lines Audit (Kiểm tra 100% dòng bị xóa `-`)
| File | Hàm / Đoạn logic bị xóa | Có trong `PLAN.md`? | Đánh giá |
|---|---|---|---|
| | | Có / Không | OK / FAIL |

## Cổng 2 — Quét 6 Luật Zero-Tolerance
- `[ ]` Không ghi đè nguyên file / không sửa ngoài phạm vi `PLAN.md`
- `[ ]` Không có chuỗi fallback đoán tên trường (`??`, `||` chữa cháy)
- `[ ]` Không có nhánh `else` / `default` gán mặc định giá trị nghiệp vụ (Fail-Fast đạt)
- `[ ]` Khớp 100% Bảng Mapping UI ↔ API ↔ DB trong `PLAN.md`
- `[ ]` Không đọc/sửa/lộ `appsettings*.json`, `Web.config`, `.env` (chỉ đọc DB khi được phép, cấm lệnh ghi)
- `[ ]` Đang làm trên nhánh tách (KHÔNG sửa trực tiếp trên `master2` / `master3`) và AI không chạy `git push`

## Cổng 3 — Cross-Check `git diff` vs Script SQL (Chống sót Prod)
| Thay đổi trong Code (cột / bảng / sto / seed) | Script tương ứng trong `DEPLOY_CHECKLIST.md` | Thứ tự (1–5) | Giữ nguyên logic v2/v3 | Trạng thái |
|---|---|---|---|---|
| | | | Có / N/A | OK / THIẾU |

- `[ ]` Đã giữ nguyên mọi đoạn code riêng của v2 / v3 theo `PLAN.md`

## Cổng 4 — Kết quả Test Case
| # | Test Case | Kết quả mong đợi | Kết quả thực tế | PASS/FAIL |
|---|---|---|---|---|
| 1 | | | | |

## Cổng 5 — Đồng bộ Online Docs (MCP)
- **Link Online Docs:** `<URL hoặc "Chưa bật MCP — cần copy DEPLOY_CHECKLIST.md thủ công">`

## Danh sách lỗi cần Coder sửa (nếu FAIL)
1. ...
