# Basalt .decree Format Specification

## File Types

| File | Audience | Purpose |
|------|----------|---------|
| `manifest.decree` | AI agents | Project/domain map. Always read first. ~20-50 lines. |
| `spec.decree` | AI agents | Full structural contract for a domain. Fields, types, relations, constraints. ~50-150 lines. |
| `body.decree` | Both | Behavioral context and business rules. Implementation details not derivable from spec. Read only when deeper context needed. |
| `decisions.log` | Both | Append-only log of design decisions with rationale. |

## manifest.decree — Project Map

Root manifest describes the entire project. Domain manifests describe a single domain.

### Root Manifest Grammar

```
S <name> <version> <engine>
D <domain> [<pub_entities>] (<private_entities>) ><dependencies>
```

- `S` = Schema header. Engine: `postgres`, `mysql`, `sqlite`, `mongo`, `agnostic`, `node`, `go`, `python`, etc.
- `D` = Domain. `[X,Y]` = public entities. `(Z)` = private/internal. `>dep1,dep2` = dependencies on other domains.

Example:
```
S MyApp 1.0.0 postgres
D user_management [User,Role] (Session) >reference
D order_processing [Order,OrderItem] >user_management,product_catalog
D reference [Country,Currency]
```

### API Manifest Grammar

```
A <group> [@annotation...]
 <METHOD> <path> [?query_params] [>request_body] [->response] [@annotations]
```

- `A` = API group
- `>` = request body fields (`>Entity.*` = all fields, `>Entity.f1,f2` = specific)
- `->` = response type (`->Entity`, `->Entity[]`, `->Entity+relation`)
- `?` = query parameters
- `@auth` = requires authentication
- `@role(name)` = RBAC constraint

Example:
```
A orders @auth
 GET / ?status,page ->Order[]
 GET /:id ->Order+items
 POST / >OrderItem[] ->Order
 PATCH /:id/status >status ->Order @role(admin)
```

## spec.decree — Domain Contract

Compressed structural metadata for a single domain.

### Grammar

```
@v<n>

><domain>::<Entity>(<field>:<type>,...)

+PublicEntity [@annotations]
 <field> <type>[!] [=default] [->Ref.field] [@annotations]
 ?<field> <type>
 #[field1,field2]

-PrivateEntity [@annotations]
 ...
```

### Declarations

- `@v1` — spec version, always first line
- `><domain>::<Entity>(fields)` — forward declaration (import from another domain)
- `+Entity` — public entity (exposed outside domain)
- `-Entity` — private/internal entity

### Type Codes

| Code | Type |
|------|------|
| `u` | uuid |
| `s` | string |
| `i` | int |
| `f` | float |
| `t` | timestamp |
| `b` | bool |
| `j` | json |

### Field Constraints

| Syntax | Meaning |
|--------|---------|
| `!` | Primary key (suffix on type: `u!`) |
| `?field` | Nullable (prefix on field name) |
| `=val` | Default value (`="pending"`, `=now`, `=0`) |
| `->Entity.field` | Foreign key reference |
| `@sens` | Sensitive data (PII, credentials) |
| `@ttl(n)` | Time-to-live in seconds |
| `@unique` | Unique constraint |
| `#[f1,f2]` | Composite index |

### Method Declarations (Application Domains)

For service/orchestrator classes in application domains, declare public methods:

| Syntax | Meaning |
|--------|---------|
| `.method(param:type) ->Return` | Public method with typed params and return |
| `.method(p1:type,p2:type)` | Method with no return (void/side-effect) |
| `.method() ->Type[]` | Method returning a list |

### Enum Declarations

| Syntax | Meaning |
|--------|---------|
| `+EnumName : val1,val2,val3` | Enum with its values |

### Constant Declarations

| Syntax | Meaning |
|--------|---------|
| `K NAME type =value` | Named constant with type and value |

### Entity Annotations

| Syntax | Meaning |
|--------|---------|
| `@protected(op)` | Operation restriction: `del`, `update`, `all` |
| `@ttl(n)` | Entity-level TTL |
| `@sens` | All fields sensitive by default |

### Full Example

```
@v1
>user_management::User(id:u)
>product_catalog::Product(id:u,price:f)

+Order @protected(del)
 id u!
 user ->User.id
 status s ="pending"
 total f
 created_at t =now
 ?notes s
 #[user,status]

+OrderItem
 id u!
 order ->Order.id
 product ->Product.id
 qty i
 unit_price f
 #[order]

-Session
 id u!
 token s @sens
 expires t
 #[user]
 @ttl(86400)
```

## Frontend Manifest Grammar

New root manifest prefix `F` for frontend domains:

```
F <domain> [<pages>] {<components>} ~<stores> ><dependencies>
```

- `F` = Frontend domain. `[Page1,Page2]` = routable pages. `{Comp1,Comp2}` = reusable components. `~Store` = state stores/contexts. `>api` = API dependency.

Example:
```
S ecommerce 1.0.0 postgres
D database [User,Product,Order] (Session)
D api [auth,orders,products] >database
F frontend [Home,ProductList,ProductDetail,Cart,Checkout] {ProductCard,ImageGallery} ~CartCtx,AuthCtx >api
```

## Frontend spec.decree — UI Contract

Compressed structural metadata for frontend domains.

### Declarations

| Symbol | Meaning |
|--------|---------|
| `P` | Page (routable view) |
| `C` | Component (reusable UI unit) |
| `~` | State store/context |
| `<<` | Consumes API endpoint (reads data from) |
| `>>` | Mutates via API endpoint (writes data to) |

### Page/Component Annotations

| Syntax | Meaning |
|--------|---------|
| `@ssr` | Server-side rendered |
| `@ssg` | Statically generated |
| `@csr` | Client-side rendered |
| `@guard(condition)` | Route protection (e.g., `@guard(auth)`) |
| `@layout(Name)` | Wrapped by layout component |

### Grammar

```
@v1
>api::<group>(METHOD path,METHOD path)

~StoreName
 key:type [=default]

P /path [@annotations]
 <<group.METHOD path [->Response]
 >>group.METHOD path [>request]
 {Component,Component}
 ~StoreName

C ComponentName
 props: field:type, field:type
 <<group.METHOD path
 {ChildComponent}
 ~StoreName
```

### Full Example

```
@v1
>api::products(GET /,GET /:slug)
>api::cart(POST /,GET /)
>api::auth(POST /login,POST /register)

~AuthCtx
 user:j?
 isAuth:b =false

~CartCtx
 items:j[] =[]
 total:f =0

P / @ssg
 <<products.GET / ->Product[]
 {ProductCard,HeroBanner}

P /products @csr
 <<products.GET / ?category,gender,price ->Product[]
 {ProductCard,Filters,Pagination}

P /products/:slug @ssr
 <<products.GET /:slug ->Product+variants
 {ImageGallery,AddToCart,VariantSelector}
 ~CartCtx

P /cart @csr @guard(auth)
 <<cart.GET / ->CartItem[]
 {CartItemRow,CartSummary}
 ~CartCtx

P /checkout @csr @guard(auth)
 >>orders.POST / >addressId ->Order
 {CheckoutForm,CartSummary}
 ~CartCtx ~AuthCtx

C ProductCard
 props: product:Product
 {ImageThumb}

C ImageGallery
 props: images:s[]

C AddToCart
 props: product:Product, variant:ProductVariant
 >>cart.POST / >productVariantId,quantity
 ~CartCtx

C VariantSelector
 props: variants:ProductVariant[]

C CheckoutForm
 >>orders.POST / >addressId
 <<addresses.GET / ->Address[]
 ~AuthCtx
```

## body.decree — Behavioral Context

The third layer of the progressive pyramid. Contains implementation details, business rules, and rendering behavior that **cannot be inferred from the spec alone**. Free-form markdown, not a DSL.

### When to read body.decree

An agent reads body.decree only when:
- The question is about **how** something works (not **what** exists)
- The spec provides the structural answer but the task requires behavioral context
- Business rules, edge cases, or non-obvious implementation choices are relevant

### Format

```markdown
## EntityName | ComponentName | RouteName

Concise prose describing non-obvious behavior.
Reference source files when useful: `(src/path/file.ts:42)`
```

### What belongs in body.decree

- **Database:** cascade behavior, computed fields, query patterns, migration notes, seed data shape
- **API:** middleware chains, validation rules, error responses, rate limiting, side effects (emails, webhooks), auth flow details
- **Frontend:** rendering implementation (which HTML elements, which framework features), data transformation utilities, animation/interaction patterns, image handling, fallback logic, SSR hydration details

### What does NOT belong in body.decree

- Anything already in spec.decree (fields, types, relations, constraints)
- Anything already in decisions.log (design rationale with dates)
- Code snippets — describe behavior, don't copy code

### Example (database)

```markdown
## Order
Cascade: deleting an Order cascade-deletes OrderItems via Prisma onDelete.
Status transitions: PENDING → CONFIRMED → SHIPPED → DELIVERED. No backward transitions.
Total is computed at creation time from sum(OrderItem.qty * OrderItem.unit_price), never recalculated.

## User
Password hashed with bcrypt (10 rounds) in auth service before storage.
Email uniqueness enforced at DB level + validated at API level with custom error message.
```

### Example (api)

```markdown
## auth
Login sets httpOnly cookie "token" (sameSite: lax, maxAge: 7d). No Authorization header.
Register auto-logs-in (sets same cookie). Password validated: min 6 chars.
All auth errors return generic 401 to prevent user enumeration.

## orders
POST /orders runs inside $transaction: creates order, reduces variant stock, clears user cart.
If any variant has insufficient stock, entire transaction rolls back with 400 + variant IDs.
```

### Example (frontend)

```markdown
## ProductCard
Renders first image via native <img> with object-cover, NOT next/image — no auto-optimization.
parseImages() (lib/utils.ts) normalizes product.images (JSON string | array | null) → string[].
Fallback: gradient placeholder picked deterministically by product.id % 6, with SVG bag icon.
Hover: scale-105 transition on image container.

## ImageGallery
Used on /products/:slug. Renders ALL product images in scrollable gallery.
Uses next/image with blur placeholder + IntersectionObserver for lazy-loading.

## Auth flow
httpOnly cookie means no JS access to token. On app mount, /auth/me is called
to hydrate AuthCtx. If 401, user is treated as unauthenticated.
Middleware.ts redirects unauthenticated users from /cart, /checkout, /orders to /login.
```

## decisions.log

**Append-only log.** Running `/basalt` never truncates or overwrites existing entries — it only appends new decisions detected from architectural patterns. Design decisions belong here, not inline in spec files.

One decision per line:

```
<YYYY-MM-DD> <domain>/<Entity>.<field> "<rationale>"
```

Example:
```
2026-03-15 order_processing/Order.total "denormalized: JOIN cost 340ms on checkout with 10k concurrent items"
2026-03-10 user_management/User.country "FK to Country.code not .id: ISO codes are stable, avoids JOIN on display"
```

For general (non-field-specific) decisions, omit the field:
```
2026-03-17 api/auth "JWT over sessions: stateless for horizontal scaling"
```

## Minimal Project Example

A project with only API routes and no schema files:

### Root manifest.decree
```
S gateway 2.0.0 agnostic
D api [health,proxy,webhooks]
```

### api/spec.decree
```
@v1

A health
 GET /health ->ok
 GET /ready ->ok

A proxy @auth
 POST /forward >url,method,body ->response
 GET /status/:id ->status

A webhooks
 POST /stripe >event ->ok
 POST /github >event ->ok
```

No `database/` domain is generated. The `decisions.log` at root level is empty but present.
