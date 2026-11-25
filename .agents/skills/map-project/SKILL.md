---
name: map-project
description: Quy trình tự động nhận diện nhánh gốc (master2 hay master3), tạo mới hoặc cập nhật bản đồ kiến trúc dự án (Graphify) vào đúng thư mục riêng graphify-out/master2 hoặc graphify-out/master3, tự ẩn trong .git/info/exclude để không ảnh hưởng git công ty.
---

# Skill: `map-project` (Tạo & Cập nhật Bản đồ Dự án tách riêng `master2` / `master3`)

## Mục tiêu
- Lưu tách riêng 2 bản đồ ngay trong repo hiện tại:
  - `graphify-out/master2/` — bản đồ của nhánh gốc `master2` (v2)
  - `graphify-out/master3/` — bản đồ của nhánh gốc `master3` (v3)
- **Chặn tuyệt đối việc ghi lộn bản đồ v2 sang v3 (hoặc ngược lại)** bằng bước kiểm tra nhánh gốc bắt buộc.

## Quy trình bắt buộc

### Bước 1 — Xác định nhánh gốc (`master2` hay `master3`) — BẮT BUỘC
Chạy kiểm tra git trên repo hiện tại (ví dụ dự án `HIS`, nhánh `thinh_master2`):
1. Lấy tên nhánh hiện tại: `git branch --show-current`.
2. Xác định nhánh hiện tại là `master2` / `master3` hay được **branch off (tách ra)** từ nhánh nào:
   - So sánh với các ref `master2` / `origin/master2` và `master3` / `origin/master3`:
     ```powershell
     git rev-list --count master2..HEAD
     git rev-list --count master3..HEAD
     ```
     *(Nếu local chưa có `master2`/`master3`, dùng `origin/master2` và `origin/master3`).*
   - **Quy tắc kết luận:**
     - Nếu đang đứng trên `master2`, HOẶC khoảng cách từ `master2` nhỏ hơn rõ rệt so với `master3` (và khớp ngữ cảnh nhánh nếu có, vd `thinh_master2`) → **Đích = `master2`** (`graphify-out/master2/`).
     - Nếu đang đứng trên `master3`, HOẶC khoảng cách từ `master3` nhỏ hơn rõ rệt so với `master2` → **Đích = `master3`** (`graphify-out/master3/`).
     - **Nếu KHÔNG xác định được rõ** (nhánh tách từ nhánh khác không phải `master2`/`master3`, 2 khoảng cách bằng nhau, hoặc tên nhánh mâu thuẫn với git ancestry) → **DỪNG NGAY LẬP TỨC**, in rõ nhánh hiện tại + kết quả kiểm tra và **hỏi người dùng xử lý**. Tuyệt đối không đoán mò hay ghi đè bản đồ.

### Bước 2 — Bảo vệ Git công ty & Bảo mật
1. Kiểm tra `.git/info/exclude` (KHÔNG sửa `.gitignore` chung của công ty).
2. Đảm bảo `.git/info/exclude` đã có `graphify-out/` và `tasks/` (chưa có thì thêm vào cuối file).
3. **Tuân thủ Luật 5 (`AGENTS.md`):** Không đọc hoặc trích xuất nội dung `appsettings*.json`, `Web.config`, `.env`.

### Bước 3 — Kiểm tra `graphify` & Tạo / Cập nhật đúng thư mục version
1. Kiểm tra `graphify` đã cài chưa (`Get-Command graphify`). Nếu chưa cài, báo người dùng lệnh cài (`uv tool install graphifyy` hoặc `pip install graphifyy` rồi `graphify install`).
2. Đặt thư mục đích là `TARGET_DIR = graphify-out/<master2|master3>` (tạo thư mục nếu chưa có).
3. **Tạo mới / Cập nhật bản đồ** *(tuyệt đối KHÔNG xóa hay chạm vào thư mục của version còn lại, và KHÔNG xóa `ENDPOINT_MAP.md` của skill `ask-map`)*:
   - Kiểm tra `graphify --help` xem có hỗ trợ cờ output (`-o` / `--output`) không:
     - Nếu có cờ output: chạy tạo mới (`graphify . -o <TARGET_DIR>`) hoặc cập nhật (`graphify update -o <TARGET_DIR>` nếu đã có `<TARGET_DIR>/graph.json`).
     - Nếu không có cờ output: chạy `graphify .` (xuất vào `graphify-out/`), sau đó di chuyển các file đầu ra (`graph.json`, `GRAPH_REPORT.md`, `graph.html`, ...) vào đúng `<TARGET_DIR>/` (giữ nguyên thư mục của version kia).

### Bước 4 — Xác nhận & Tóm tắt
1. Xác nhận `<TARGET_DIR>/GRAPH_REPORT.md` và `<TARGET_DIR>/graph.json` đã tạo/cập nhật thành công.
2. Đọc nhanh `<TARGET_DIR>/GRAPH_REPORT.md` và báo cáo ngắn gọn:
   - Nhánh hiện tại (`<branch>`) → đã xác nhận tách từ **`master2`** hoặc **`master3`** → đã lưu vào `graphify-out/<ver>/`.
   - Tóm tắt nhanh các module chính & God Nodes.
   - Xác nhận `git status` sạch (`.git/info/exclude` đã ẩn `graphify-out/`).
