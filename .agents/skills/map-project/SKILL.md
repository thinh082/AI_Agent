---
name: map-project
description: Tạo mới / cập nhật bản đồ Graphify cho đúng version (graphify-out/master2 hoặc graphify-out/master3) bằng script map.ps1 chạy code-only (tree-sitter, không gọi model, không tốn token), tự nhận diện nhánh gốc v2/v3 và dừng nếu không rõ. Kèm cách tra bản đồ tiết kiệm token bằng graphify query.
---

# Skill: `map-project` (Bản đồ dự án tách riêng `master2` / `master3` — Tiết kiệm token)

## Nguyên tắc tiết kiệm token
- **Dựng bản đồ không cần AI:** `graphify extract . --code-only` (lần đầu) và `graphify update .` (các lần sau) đọc code bằng tree-sitter, **không gọi model**. Cách nhanh nhất là **người dùng tự chạy `map.ps1`** trong repo `AI_Agent`, không cần mở phiên AI:
  ```powershell
  powershell -ExecutionPolicy Bypass -File <repo AI_Agent>\map.ps1 -HisPath <thư mục HIS>          # cập nhật
  powershell -ExecutionPolicy Bypass -File <repo AI_Agent>\map.ps1 -HisPath <thư mục HIS> -Full    # dựng lại toàn bộ
  ```
- **CẤM** (trừ khi người dùng yêu cầu rõ): `/graphify .` (chế độ trợ lý, trích xuất ngữ nghĩa tài liệu bằng model), `graphify label` (đặt tên cụm bằng model), `graphify extract` **không** có `--code-only`.
- **CẤM** `graphify hook install` (sửa `.gitattributes` của công ty và git config).
- **Không đọc cả `graph.json` / `GRAPH_REPORT.md`.** Tra bằng lệnh có giới hạn token (xem mục *Tra bản đồ*).

## Quy trình (khi người dùng nhờ AI chạy)

### Bước 1 — Chạy script
1. Chạy `map.ps1 -HisPath <thư mục gốc dự án>` (thêm `-Full` nếu người dùng yêu cầu dựng lại, hoặc đổi rule `.graphifyignore`). Tên nhánh gốc mặc định `-BaseV2 master_2 -BaseV3 master_3` (theo `AGENTS.md` mục 1); khác thì truyền đúng tên.
2. Script tự: xác định version (đứng trên nhánh gốc, hoặc so `git rev-list --count <BASE_V2>..HEAD` với `<BASE_V3>..HEAD`, đối chiếu hậu tố `_M2` / `_M3`) → **không rõ thì DỪNG, không ghi**; tạo `.graphifyignore` mặc định (nếu chưa có) và ẩn trong `.git/info/exclude`; chạy graphify code-only; copy `graph.json`, `GRAPH_REPORT.md`, `graph.html` vào `graphify-out/<master2|master3>/`; ghi `META.md` (nhánh, commit, ngày).
3. Script **dừng** (exit ≠ 0) → báo đúng dòng `[DUNG] ...` cho người dùng, **không tự xử lý nhánh**.
4. Script không bao giờ xóa thư mục của version còn lại và không đụng `ENDPOINT_MAP.md` của skill `ask-map`.

### Bước 2 — Báo lại (ngắn)
- Version + commit trong `graphify-out/<ver>/META.md`.
- **Chỉ đọc ~40 dòng đầu** `GRAPH_REPORT.md` để tóm tắt module chính / god nodes (không đọc cả file).
- `git status` sạch (`graphify-out/`, `.graphifyignore` đã được ẩn).

## Tra bản đồ (Planner / ask-map / diagnose-bug)
- Luôn chỉ định đúng version và giới hạn token:
  ```text
  graphify query "<từ khóa trong code>" --budget 1500 --graph graphify-out/<master2|master3>/graph.json
  graphify explain "<tên node>" --graph graphify-out/<ver>/graph.json
  graphify affected "<tên node>" --depth 2 --graph graphify-out/<ver>/graph.json
  graphify path "<node A>" "<node B>" --graph graphify-out/<ver>/graph.json
  ```
- Exit `3` = nhiều node trùng tên (chọn 1 trong danh sách in ra) · exit `4` = không khớp (dùng tên có trong code).
- **Bản đồ còn mới không?** So commit trong `META.md`: `git diff --name-only <commit>..HEAD`. File liên quan task đã đổi → vẫn dùng bản đồ để định vị nhưng **mở file thật để xác nhận** (luôn bắt buộc theo `AGENTS.md` mục 5). Không cần dựng lại bản đồ sau mỗi `git pull`.
