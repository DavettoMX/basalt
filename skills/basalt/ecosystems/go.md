# Basalt: Go Detection & Extraction

## Detection Patterns

### Database / Schema
- `**/models/**/*.go` files containing `gorm:` tags — GORM
- `**/models/**/*.go` files containing `db:` or `sqlx:` tags — SQLx
- `**/ent/schema/**/*.go` containing `ent.Schema` — Ent ORM
- `**/migrations/**/*.sql` — Raw SQL migrations

### API / Routes
- `**/handlers/**/*.go`, `**/handler/**/*.go` containing `gin.Context` — Gin
- `**/handlers/**/*.go` containing `http.Handler` or `http.HandlerFunc` — net/http
- `**/*.go` containing `chi.Router` or `chi.NewRouter` — Chi
- `**/*.go` containing `echo.Context` — Echo
- `**/*.go` containing `fiber.Ctx` — Fiber

### Application / Business Logic
- `**/internal/**/*.go`, `**/pkg/**/*.go` containing exported types (`type X struct`) or exported functions — exclude files already matched as handlers or models
- **Domain naming:** Use the package name as the domain name (e.g., `internal/billing/` → domain `billing`)
- Separate domain per package directory with distinct responsibility

## Extraction Rules

### Database spec.decree (GORM)
- `gorm:"primaryKey"` → `!` suffix
- `gorm:"type:varchar"` / `string` → `s`, `int` / `int64` → `i`, `float64` → `f`
- `bool` → `b`, `time.Time` → `t`, `datatypes.JSON` → `j`
- `gorm:"uniqueIndex"` → `@unique`
- `gorm:"index"` → `#[field]`
- `*Type` (pointer) → `?` prefix (nullable)
- `gorm:"default:value"` → `=val`
- Foreign key fields (`UserID uint` + `User User`) → `->User.id`

### Database spec.decree (SQLx)
- Map Go types: `string` → `s`, `int64` → `i`, `float64` → `f`, `bool` → `b`, `time.Time` → `t`
- `sql.NullString` / `*string` → `?` prefix
- FK relationships inferred from field naming (`UserID` → `->User.id`)

### API spec.decree
- `r.GET("/path", handler)` → `GET /path`
- `r.POST("/path", handler)` → `POST /path`
- Route params `:id` preserved
- Middleware groups with `auth` → `@auth`
- Request struct fields → `>fields`
- Response struct → `->Entity` or `->Entity[]`

### Application spec.decree
- Exported structs → `+StructName` with fields
- Exported methods on structs → `.MethodName(params) ->return`
- Only include exported methods (capitalized) — skip unexported helpers
- Constants (`const X = value`) → `K NAME type =value`
- Custom types with `iota` → `+TypeName : val1,val2,val3`
- Type mappings: `string` → `s`, `int`/`int64` → `i`, `float64` → `f`, `bool` → `b`, `time.Time` → `t`, `map[string]interface{}` → `j`

### body.decree additions
- **Database:** GORM hooks (`BeforeCreate`, `AfterUpdate`), soft delete (`gorm.DeletedAt`), auto-migration notes
- **API:** Gin middleware chains, custom validators, error handling patterns, graceful shutdown
- **Application:** goroutine patterns, channel-based orchestration, context propagation, retry strategies

## Example

### Go + GORM + Gin

Given Go structs with `gorm:` tags and Gin route groups:

#### Root manifest.decree
```
S inventory 0.3.0 postgres
D database [Warehouse,Item,StockMovement]
D api [warehouses,items] >database
```

#### database/spec.decree
```
@v1

+Warehouse
 id u!
 name s
 location s
 active b =true

+Item
 id u!
 sku s @unique
 name s
 ?description s
 warehouse ->Warehouse.id
 #[sku]
 #[warehouse]

+StockMovement
 id u!
 item ->Item.id
 qty i
 type s
 created_at t =now
 #[item,created_at]
```
