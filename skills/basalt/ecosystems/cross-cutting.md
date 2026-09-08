# Basalt: Cross-Cutting Detection & Extraction

These patterns apply across ecosystems. Load this package when the project contains `.proto` files or OpenAPI/Swagger specs.

## Detection Patterns

### gRPC / Protocol Buffers
- `**/*.proto` — Protocol Buffer definitions
- `**/*_grpc.{go,py,ts,js}` — Generated gRPC stubs (confirms gRPC usage)
- `**/*_pb2.py`, `**/*_pb2_grpc.py` — Python generated protobuf files

### OpenAPI / Swagger
- `**/openapi.{yaml,yml,json}` — OpenAPI 3.x specs
- `**/swagger.{yaml,yml,json}` — Swagger 2.x specs

## Extraction Rules

### gRPC spec.decree
- Each `service` block → `A` group declaration
- Each `rpc` method → route-like entry:
  - `rpc GetUser(GetUserRequest) returns (User)` → `GET /GetUser >GetUserRequest ->User`
  - `rpc ListOrders(ListRequest) returns (stream Order)` → `GET /ListOrders >ListRequest ->Order[]`
- `message` definitions → `+Entity` with fields
- Protobuf types: `string` → `s`, `int32`/`int64` → `i`, `float`/`double` → `f`, `bool` → `b`, `google.protobuf.Timestamp` → `t`, `bytes` → `s`
- `repeated` fields → array notation in response (`->Entity[]`)
- `oneof` → document in body.decree as variant behavior

### OpenAPI spec.decree
- Each tag group → `A` group declaration
- Each operation → `METHOD /path`:
  - `get: /users/{id}` → `GET /users/:id`
  - `post: /orders` → `POST /orders`
- `requestBody` schema → `>fields`
- `responses.200.content` schema → `->Entity` or `->Entity[]`
- `security` requirements → `@auth`
- `x-roles` or security scopes → `@role(name)`
- Path parameters `{id}` → `:id`
- Query parameters from `parameters` with `in: query` → `?param1,param2`

### body.decree additions
- **gRPC:** streaming patterns (server-stream, client-stream, bidirectional), deadline/timeout policies, interceptor chains, error code conventions
- **OpenAPI:** pagination patterns (cursor vs offset), rate limit headers, webhook configurations, discriminator/polymorphism
