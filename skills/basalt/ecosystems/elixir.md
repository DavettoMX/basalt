# Basalt: Elixir Detection & Extraction

## Detection Patterns

### Database / Schema
- `**/lib/**/schema.ex`, `**/*_schema.ex` containing `use Ecto.Schema` — Ecto schemas
- `**/priv/repo/migrations/**/*.exs` — Ecto migrations
- `**/*.ex` containing `schema "table_name" do` — Ecto schema blocks

### API / Routes
- `**/router.ex` containing `scope`, `pipe_through`, `get`, `post` — Phoenix Router
- `**/*_controller.ex` containing `use.*Controller` — Phoenix Controllers
- `**/*_live.ex` containing `use.*LiveView` — Phoenix LiveView

### Application / Business Logic
- `**/lib/**/*.ex` containing `defmodule` with public functions (`def `) — exclude schemas and controllers
- **Domain naming:** Use the module namespace (e.g., `MyApp.Billing` → domain `billing`)

## Extraction Rules

### Database spec.decree (Ecto)
- `field :name, :string` → `s`, `:integer` → `i`, `:float`/`:decimal` → `f`, `:boolean` → `b`, `:utc_datetime`/`:naive_datetime` → `t`, `:map` → `j`
- `field :id, :binary_id, primary_key: true` → `u!`
- `belongs_to :entity, Entity` → `->Entity.id`
- `has_many` / `has_one` → document in body.decree
- `timestamps()` → `created_at t =now` + `updated_at t =now`
- Unique constraints from migrations (`unique_index`) → `@unique`

### API spec.decree
- `get "/path", Controller, :action` → `GET /path`
- `post "/path", Controller, :action` → `POST /path`
- `pipe_through [:api, :auth]` → `@auth` for routes in that scope
- Changeset cast fields → `>fields`
- `render(conn, data)` → `->Entity`

### Application spec.decree
- Modules with `def` functions → `+ModuleName` with `.function(params) ->return`
- Structs (`defstruct`) → `+StructName` with fields
- Module attributes (`@constant value`) → `K NAME type =value`
- Typespecs (`@spec`) used to determine param/return types

### body.decree additions
- **Database:** Ecto changeset validations, multi/transaction patterns, preload strategies
- **API:** Phoenix plugs pipeline, channel/websocket patterns, LiveView mount/handle_event lifecycle
- **Application:** GenServer state management, Supervisor trees, Task.async patterns, PubSub usage
