# Basalt: Rust Detection & Extraction

## Detection Patterns

### Database / Schema
- `**/schema.rs` containing `table!` macro — Diesel
- `**/models/**/*.rs` containing `#[derive(` with `Queryable`, `Insertable`, `Selectable` — Diesel
- `**/*.rs` containing `#[derive(sqlx::FromRow)]` or `sqlx::query!` — SQLx
- `**/migrations/**/*.sql` — Raw SQL migrations (Diesel or SQLx)
- `**/entity/**/*.rs` containing `#[derive(DeriveEntityModel)]` — SeaORM

### API / Routes
- `**/*.rs` containing `#[get(`, `#[post(`, `#[put(`, `#[delete(` — Actix-web macros
- `**/*.rs` containing `axum::Router` or `axum::routing::` — Axum
- `**/*.rs` containing `rocket::` with `#[get(`, `#[post(` — Rocket

### Application / Business Logic
- `**/src/**/*.rs` containing `pub struct` with `pub fn` or `pub async fn` methods — exclude files already matched as models or handlers
- **Domain naming:** Use the module name from `mod.rs` or directory name

## Extraction Rules

### Database spec.decree
- Diesel `table!` columns: `Integer` → `i`, `Text`/`Varchar` → `s`, `Float`/`Double` → `f`, `Bool` → `b`, `Timestamp` → `t`, `Jsonb` → `j`
- `#[primary_key]` → `!` suffix
- `Nullable<Type>` or `Option<Type>` → `?` prefix
- `#[belongs_to(Entity)]` → `->Entity.id`

### API spec.decree
- Actix: `#[get("/path")]` → `GET /path`, `#[post("/path")]` → `POST /path`
- Axum: `.route("/path", get(handler))` → `GET /path`
- `web::Json<T>` or `Json<T>` request param → `>fields` (from struct T)
- `HttpResponse::Ok().json(entity)` → `->Entity`

### Application spec.decree
- `pub struct Name` → `+Name` with `pub` fields
- `pub fn method(&self, ...)` or `pub async fn method(&self, ...)` → `.method(params) ->return`
- `pub enum Name` → `+Name : Variant1,Variant2`
- `const NAME: type = value` → `K NAME type =value`
- Type mappings: `String`/`&str` → `s`, `i32`/`i64`/`usize` → `i`, `f64` → `f`, `bool` → `b`, `DateTime<Utc>` → `t`, `serde_json::Value` → `j`

### body.decree additions
- **Database:** Diesel connection pooling (r2d2/deadpool), migration embedding, custom SQL functions
- **API:** Tower middleware layers, extractors, error handling with `thiserror`/`anyhow`, graceful shutdown
- **Application:** `tokio` async patterns, `Arc<Mutex<>>` shared state, trait-based service abstractions
