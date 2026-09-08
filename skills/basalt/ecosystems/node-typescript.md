# Basalt: Node.js / TypeScript Detection & Extraction

## Detection Patterns

### Database / Schema
- `**/*.prisma` — Prisma schemas
- `**/entity/**/*.ts` files containing `@Entity` — TypeORM
- `**/models/**/*.ts` files containing `@Table` or `@Column` — Sequelize with decorators

### API / Routes
- `**/routes/**/*.{ts,js}`, `**/router/**/*.{ts,js}` containing `router.` or `app.` — Express / Fastify
- `**/controllers/**/*.{ts,js}` containing route definitions or `@Controller` — NestJS / Express
- `**/*.controller.ts` containing `@Get`, `@Post`, `@Put`, `@Delete` — NestJS

### Frontend / UI
- `**/app/**/page.{tsx,jsx,ts,js}` — Next.js App Router pages
- `**/pages/**/*.{tsx,jsx,ts,js}` (excluding `_app`, `_document`, `api/`) — Next.js Pages Router / Nuxt pages
- `**/src/routes/**/*.{svelte,ts}` — SvelteKit routes
- `**/src/views/**/*.vue` — Vue/Nuxt view components
- `**/components/**/*.{tsx,jsx,vue,svelte}` — Reusable UI components
- `**/src/app/**/*.component.ts` containing `@Component` — Angular components

### State Management
- `**/*Context.{tsx,jsx}`, `**/*Provider.{tsx,jsx}` containing `createContext` — React Context
- `**/*store.{ts,js}`, `**/*slice.{ts,js}` containing `createSlice` or `configureStore` — Redux Toolkit
- `**/*store.{ts,js}` containing `create(` from `zustand` — Zustand
- `**/stores/**/*.{ts,js}` containing `defineStore` — Pinia
- `**/*store.{ts,js}` containing `writable(` or `readable(` — Svelte stores

### API Consumption (scan within discovered frontend files)
- Files containing `fetch(`, `axios.`, `useSWR`, `useQuery`, `$fetch`, `trpc.` — identify which pages/components call which endpoints
- Shared API client files: `**/lib/api.{ts,js}`, `**/services/**/*.{ts,js}` — read to understand base URL and method mappings

### Application / Business Logic
- `**/src/services/**/*.{ts,js}`, `**/src/lib/**/*.{ts,js}`, `**/src/core/**/*.{ts,js}` containing `export class` or significant exported functions — exclude files already matched as routes or frontend

## Extraction Rules

### Database spec.decree (Prisma)
- `@id` → `!` suffix
- `String`, `Int`, `Float`, `Boolean`, `DateTime`, `Json` → `s`, `i`, `f`, `b`, `t`, `j`
- `@default(...)` → `=val` (`@default(now())` → `=now`, `@default(uuid())` → omit)
- `@relation(fields: [...], references: [...])` → `->Entity.field`
- `@@index([...])` → `#[fields]`
- `@unique` → `@unique`
- `@@unique([...])` → `@unique[fields]`
- `?` optional marker on type → `?` prefix on field name

### Database spec.decree (TypeORM)
- `@PrimaryGeneratedColumn("uuid")` → `u!`, `@PrimaryGeneratedColumn()` → `i!`
- `@Column({ type: "varchar" })` → `s`, etc.
- `@ManyToOne(() => Entity)` / `@JoinColumn()` → `->Entity.field`
- `@Index([...])` → `#[fields]`
- `@Column({ unique: true })` → `@unique`
- `@Column({ nullable: true })` → `?` prefix

### API spec.decree
- `router.get("/path", ...)` → `GET /path`
- `router.post("/path", ...)` → `POST /path`
- Route params `:id` preserved as-is
- Middleware with `auth`, `authenticate`, `requireAuth` → `@auth`
- Middleware with `authorize("role")` or `requireRole` → `@role(name)`
- Request body types from TypeScript interfaces → `>fields`
- Response types → `->Entity` or `->Entity[]`

### Frontend spec.decree
- **Page detection:**
  - Next.js App Router: each `app/**/page.tsx` → `P` declaration. Route from directory structure (`app/products/[slug]/page.tsx` → `P /products/:slug`). `generateStaticParams` → `@ssg`, `async` server component without `'use client'` → `@ssr`, `'use client'` → `@csr`.
  - Next.js Pages Router: each `pages/**/*.tsx` → `P`. `getStaticProps` → `@ssg`, `getServerSideProps` → `@ssr`.
  - Vue/Nuxt: `pages/` directory structure maps to routes. SvelteKit: `src/routes/**/+page.svelte` maps to routes.
- **Component detection:**
  - Scan `components/` directories. Each exported function/class returning JSX/template → `C`.
  - Extract props from: TypeScript interfaces (`interface Props`, `type Props`), `defineProps<>()` (Vue), `export let` (Svelte), `@Input()` (Angular).
  - Map prop types: `string` → `s`, `number` → `i`/`f`, `boolean` → `b`, entity references → `Entity`.
  - Only include components with non-trivial logic (API calls, state consumption, significant props). Skip pure layout/wrapper components.
- **State detection:**
  - `createContext` + Provider pattern → `~ContextName`. Read context value type for fields.
  - `createSlice` / `configureStore` → `~SliceName`. Read `initialState` for fields.
  - `defineStore` → `~StoreName`. Read `state()` return type.
  - `create()` from zustand → `~StoreName`. Read store type.
- **API consumption detection:**
  - In each page/component, scan for: `fetch('/api/...`, `fetch(\`...`, `axios.get('/...`, `useSWR('/...`, `useQuery(`, `trpc.`.
  - Map URL patterns to matching `A` group routes from the api domain.
  - `<<` for GET requests (reads), `>>` for POST/PUT/PATCH/DELETE (mutations).
  - If a shared API client file exists (e.g., `lib/api.ts`), read it to resolve base URLs.
- **Component composition:** Scan JSX/template for `<ComponentName` references → `{Component1,Component2}`.
- **Layout detection (Next.js App Router):**
  - `app/layout.tsx` = root layout, `app/products/layout.tsx` wraps `/products/*` pages.
  - Record as `@layout(Name)` only if the layout has meaningful logic (auth guards, data fetching).

### body.decree additions
- **Database:** Prisma `onDelete` cascade behavior, `@updatedAt` auto-update, `@@map` table name overrides
- **API:** Express middleware chains, `express-validator` rules, `$transaction` boundaries, httpOnly cookie auth details, CORS setup
- **Frontend:** `next/image` vs native `<img>` usage, `parseImages()` or similar data normalization utilities, gradient/placeholder fallback patterns, IntersectionObserver lazy-loading, Auth flow (httpOnly cookie hydration via `/auth/me`, middleware.ts route protection)
- **Application:** Service class orchestration, external API client patterns, caching strategies

## Example

### Node.js + Prisma + Express (Full-Stack with Next.js Frontend)

#### Root manifest.decree
```
S ecommerce 1.0.0 postgres
D database [User,Product,Order,OrderItem,CartItem] (Session)
D api [auth,orders,products,cart] >database
F frontend [Home,Products,ProductDetail,Cart,Checkout,Orders] {ProductCard,ImageGallery,AddToCart,CartItemRow} ~AuthCtx,CartCtx >api
```

#### database/spec.decree
```
@v1

+User
 id u!
 email s @unique
 password s @sens
 name s
 created_at t =now
 #[email]

+Product
 id u!
 name s
 slug s @unique
 price f
 images s ="[]"
 categoryId i ->Category.id
 #[slug]

+Order
 id u!
 user ->User.id
 status s ="pending"
 total f
 created_at t =now
 #[user,status]

+OrderItem
 id u!
 order ->Order.id
 product ->Product.id
 qty i
 unit_price f
 #[order]

+CartItem
 id u!
 user ->User.id
 productVariantId i ->ProductVariant.id
 quantity i
 @unique[user,productVariantId]
```

#### api/spec.decree
```
@v1
>database::User(id:u,email:s)
>database::Product(id:u,slug:s)
>database::Order(id:u,status:s)
>database::CartItem(id:u)

A auth
 POST /register >email,password,name ->User
 POST /login >email,password ->User
 POST /logout ->ok
 GET /me @auth ->User

A products
 GET /featured ->Product[]
 GET / ?category,gender,minPrice,maxPrice,search,page,limit ->Product[]
 GET /:slug ->Product+variants

A cart @auth
 GET / ->CartItem[]
 POST / >productVariantId,quantity ->CartItem
 PATCH /:id >quantity ->CartItem
 DEL /:id ->CartItem

A orders @auth
 POST / >addressId ->Order+items
 GET / ->Order[]
 GET /:id ->Order+items
```

#### frontend/spec.decree
```
@v1
>api::products(GET /featured,GET /,GET /:slug)
>api::cart(GET /,POST /)
>api::orders(POST /,GET /)
>api::auth(POST /login,POST /register,GET /me)

~AuthCtx
 user:j?
 isAuth:b =false

~CartCtx
 items:j[] =[]
 total:f =0

P / @ssg
 <<products.GET /featured ->Product[]
 {ProductCard,HeroBanner}

P /products @csr
 <<products.GET / ?category,gender,minPrice,maxPrice ->Product[]
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

P /orders @csr @guard(auth)
 <<orders.GET / ->Order[]
 {OrderCard}

C ProductCard
 props: product:Product

C ImageGallery
 props: images:s[]

C AddToCart
 props: product:Product, variant:ProductVariant
 >>cart.POST / >productVariantId,quantity
 ~CartCtx

C CartItemRow
 props: item:CartItem
 ~CartCtx
```

#### database/body.decree
```markdown
## User
Password hashed with bcrypt (10 rounds) in auth service before storage.
Email uniqueness: enforced at DB level (@unique) + validated at API with custom 409 error.

## Order
Status transitions: PENDING → CONFIRMED → SHIPPED → DELIVERED. No backward transitions enforced in code.
Total computed at creation: sum(OrderItem.qty * OrderItem.price). Never recalculated after creation.

## CartItem
Upsert pattern: adding existing userId+productVariantId increments quantity instead of inserting duplicate.
Cascade: cleared atomically during order creation inside $transaction.
```

#### api/body.decree
```markdown
## auth
Login/register set httpOnly cookie "token" (sameSite: lax, maxAge: 7d). No Authorization header used.
Register auto-logs-in by setting same cookie. Password validation: min 6 chars via express-validator.
All auth errors return generic 401 — prevents user enumeration.

## orders
POST /orders runs inside $transaction: creates order + reduces variant stock + clears user cart.
If any variant has insufficient stock, entire transaction rolls back with 400 + failing variant IDs.

## products
Gender filter maps Spanish→English in service layer: hombre→MEN, mujer→WOMEN, ninos→KIDS, unisex→UNISEX.
GET /featured returns 8 newest products with category+variants included.
```

#### frontend/body.decree
```markdown
## ProductCard
Renders first image via native <img> with object-cover, NOT next/image — no auto-optimization.
parseImages() (lib/utils.ts) normalizes product.images (JSON string | array | null) → string[].
Fallback: gradient placeholder picked deterministically by product.id % 6, with SVG bag icon.
Hover: scale-105 transition on image container. Category badge overlaid top-left.

## ImageGallery
Used on /products/:slug detail page. Renders ALL product images in scrollable gallery.
Uses next/image with blur placeholder + IntersectionObserver for lazy-loading.

## Auth flow
httpOnly cookie = no JS access to token. On app mount, /auth/me called to hydrate AuthCtx.
If 401, user treated as unauthenticated. middleware.ts redirects from /cart, /checkout, /orders to /login.
```
