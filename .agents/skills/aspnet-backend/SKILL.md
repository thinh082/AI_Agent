---
name: aspnet-backend
description: Quy chuẩn viết code backend ASP.NET Core (.NET 7) theo đúng style dự án: cấu trúc Controller/Service, chọn linh hoạt EF Core vs Stored Procedure, chọn linh hoạt dynamic vs Strongly-Typed Model/DTO, chuẩn API Response {code, message, data}, Transaction và Validation.
---

# Skill: `aspnet-backend` (Quy chuẩn Code Backend ASP.NET Core .NET 7)

Skill này quy định **chuẩn code backend** của dự án để AI Coder viết nhất quán với style của team. Luôn áp dụng song song với **6 Luật Zero-Tolerance** trong `AGENTS.md` (cấm đoán mò, cấm silent fallback, bắt buộc Fail-Fast ở `else`/`default`).

> **Nguyên tắc ngôn ngữ:** Phân tích, giải thích, kế hoạch và comment trong code dùng **Tiếng Việt**. Tên class, method, biến dùng **Tiếng Anh** (hoặc giữ nguyên quy ước đặt tên hiện có của module).

> **Ranh giới với kho kiến thức:** Skill này chỉ giữ **chuẩn nền đúng cho mọi task**. Mẫu theo tình huống cụ thể, lỗi đặc thù và nghiệp vụ HIS nằm trong kho kiến thức (`KNOWLEDGE_ROOT`, `AGENTS.md` mục 7) — đọc theo mã `P/X/D` được gắn trong `PLAN.md`.

---

## 1. Chọn đúng công cụ truy cập dữ liệu & kiểu dữ liệu (Linh hoạt theo từng trường hợp)

### A. EF Core vs Stored Procedure (SQL Server 2017)
- **KHÔNG ép mọi chỗ đều phải dùng Entity Framework:**
  - **Dùng EF Core (LINQ)** khi: CRUD đơn giản, đọc/kiểm tra tồn tại nhẹ (`.AsNoTracking()`, `.AnyAsync()`, `.Select(...)`).
  - **Dùng Stored Procedure** khi: báo cáo, truy vấn join nhiều bảng phức tạp, xử lý dữ liệu lớn, hoặc màn hình/module đó đang dùng STO sẵn (lưu ý tuân thủ luật SQL Server 2017 và tách script v2/v3 trong `AGENTS.md`).
- Nếu cần thay đổi file trong thư mục `Models/` (Entities) → **dừng lại giải thích lý do và xin phép người dùng trước**.

### B. `dynamic` vs Model/DTO rõ ràng (Strongly-Typed)
- **KHÔNG ép lúc nào cũng trả về `dynamic`:**
  - **Dùng `Task<dynamic>`** khi: endpoint đơn giản, dữ liệu trả về linh hoạt phục vụ hiển thị nhanh trên UI và không cần tái sử dụng kiểu chặt chẽ.
  - **BẮT BUỘC dùng Model / DTO rõ ràng (Input Model + Output Model)** khi:
    - Hàm nghiệp vụ quan trọng, cần chuẩn hóa chặt đầu vào / đầu ra (tính toán, thu tiền, lưu nhiều bảng, xuất Excel, **gửi cổng thông tin / API đối tác**).
    - Hàm được gọi lại ở nhiều nơi hoặc cần map rõ ràng 1–1 với cột DB / HTML (giúp compiler bắt lỗi sai tên trường ngay lập tức, loại bỏ nguy cơ đoán mò).

---

## 2. Cấu trúc Service (`<FeatureName>Services.cs`)

Interface và Class nằm **cùng 1 file**, **KHÔNG tạo file Interface riêng**:

```csharp
public interface I<FeatureName>Services
{
    // Chỉ expose các method được gọi từ Controller
    // Chọn Task<OutputModel> (khi cần chuẩn chặt) hoặc Task<dynamic> (khi trả JSON linh hoạt)
    Task<dynamic> GetListAsync(FilterRequest request);
    Task<ApiResult<CreateResponse>> CreateAsync(CreateRequest request);
}

public class <FeatureName>Services : I<FeatureName>Services
{
    private readonly AppDbContext _context;
    // Inject thêm CommonServices hoặc connection gọi STO nếu cần

    public <FeatureName>Services(AppDbContext context)
    {
        _context = context;
    }

    // === PUBLIC METHODS (expose qua Interface) ===

    public async Task<dynamic> GetListAsync(FilterRequest request)
    {
        // Logic nghiệp vụ (EF Core hoặc gọi STO tùy trường hợp)
    }

    // === PRIVATE METHODS (nội bộ, không expose) ===

    private async Task<bool> CheckExistsAsync(int id)
    {
        return await _context.TableName.AnyAsync(x => x.Id == id);
    }
}
```

**Checklist khi viết Service:**
- [ ] Tất cả method I/O dùng `async/await`
- [ ] Chọn đúng `Model/DTO` (khi cần chuẩn đầu vào/đầu ra) hay `dynamic` (khi linh hoạt)
- [ ] Chọn đúng **EF Core** hay **Stored Procedure** theo tính chất bài toán và cấu trúc sẵn có của module
- [ ] Query EF Core chỉ đọc có `.AsNoTracking()` và `.Select()` đúng trường cần thiết
- [ ] Kiểm tra tồn tại dùng `.AnyAsync()`, không dùng `.Count()` hay `.FirstOrDefault()`
- [ ] Logic phức tạp bọc trong `try...catch` (không nuốt lỗi)
- [ ] Chuỗi Insert/Update/Delete nhiều bảng bắt buộc dùng **Transaction**

---

## 3. Cấu trúc Controller (`<FeatureName>Controller.cs`)

Controller mỏng — **không đặt logic nghiệp vụ trong Controller**, chỉ gọi Service:

```csharp
[Route("api/[controller]")] // hoặc giữ đúng route MVC hiện có của dự án
public class <FeatureName>Controller : Controller // hoặc ControllerBase với Web API thuần
{
    private readonly I<FeatureName>Services _services;

    public <FeatureName>Controller(I<FeatureName>Services services)
    {
        _services = services;
    }

    // Ưu tiên chỉ dùng [HttpGet] và [HttpPost]
    [HttpPost("create")]
    public async Task<dynamic> Create([FromBody] CreateRequest request)
    {
        return await _services.CreateAsync(request);
    }
}
```

---

## 4. Đăng ký Dependency Injection (`Program.cs`)
Khi tạo Service mới, đăng ký trong `Program.cs` (patch đúng 1 dòng, cẩn thận file global):
```csharp
builder.Services.AddScoped<I<FeatureName>Services, <FeatureName>Services>();
```

---

## 5. Chuẩn API Response
Mọi API **bắt buộc** trả về đúng format `{ code, message, data }`:
```json
// Thành công
{ "code": 200, "message": "Thêm mới thành công", "data": { ... } }

// Lỗi nghiệp vụ / dữ liệu đầu vào không hợp lệ (Fail-Fast)
{ "code": 400, "message": "Dữ liệu không hợp lệ: ..." }

// Không tìm thấy
{ "code": 404, "message": "Không tìm thấy dữ liệu" }

// Lỗi hệ thống
{ "code": 500, "message": "Đã xảy ra lỗi, vui lòng thử lại" }
```

---

## 6. Patterns quan trọng

### Transaction (bắt buộc khi tác động nhiều bảng)
```csharp
await using var transaction = await _context.Database.BeginTransactionAsync();
try
{
    // Thực hiện các thao tác DB
    await _context.SaveChangesAsync();
    await transaction.CommitAsync();
    return new { code = 200, message = "Thành công" };
}
catch (Exception ex)
{
    await transaction.RollbackAsync();
    // Ghi log chi tiết `ex` theo cơ chế log hiện có của dự án — KHÔNG trả ex.Message ra client (lộ thông tin nội bộ)
    return new { code = 500, message = "Đã xảy ra lỗi, vui lòng thử lại" };
}
```
> Cân nhắc cấu hình `IsolationLevel` (vd: `IsolationLevel.Serializable`) nếu trong transaction có đọc/cộng/trừ số dư, thu tiền, tồn kho... để tránh Dirty Read / Race Condition.

### Validate DTO đầu vào
Nếu DTO có nhiều trường cần kiểm tra, viết hàm `Validate()` ngay bên trong class DTO:
```csharp
public class CreateRequest
{
    public string Name { get; set; }

    public string? Validate()
    {
        if (string.IsNullOrEmpty(Name))
            return "Tên không được để trống";
        return null; // Hợp lệ
    }
}
```

### Kiểm tra trùng lặp / tồn tại trước khi Insert / Update / Delete
```csharp
// Trước khi Insert (unique)
bool exists = await _context.Users.AnyAsync(u => u.Email == request.Email);
if (exists) return new { code = 400, message = "Email đã tồn tại trong hệ thống" };

// Trước khi Update / Delete
bool found = await _context.Users.AnyAsync(u => u.Id == request.Id);
if (!found) return new { code = 404, message = "Không tìm thấy dữ liệu" };
```

### Logic dùng chung → `CommonServices`
Các helper dùng ở nhiều module (format ngày, sinh mã, kiểm tra quyền...) đặt vào `CommonServices`.
