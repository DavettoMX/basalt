# Basalt: Python Detection & Extraction

## Detection Patterns

### Database / Schema
- `**/models.py`, `**/models/**/*.py` files containing `Column(` or `mapped_column` — SQLAlchemy / Alembic
- `**/migrations/**/*.sql` — Raw SQL migrations
- `**/schema.sql`, `**/init.sql` — Schema definition files

### API / Routes
- `**/*.py` containing `@app.get`, `@app.post`, `@app.put`, `@app.delete`, `@app.patch` — FastAPI
- `**/*.py` containing `@router.get`, `@router.post`, `@router.put`, `@router.delete` — FastAPI APIRouter
- `**/urls.py` containing `path(` or `urlpatterns` — Django
- `**/views.py`, `**/views/**/*.py` containing `class.*APIView` or `class.*ViewSet` — Django REST Framework

### Application / Business Logic
- Directories under `**/src/` (or project root) containing `__init__.py` with `.py` files that define `class ` — exclude directories already matched as database models or API routes
- Standalone `.py` files with significant class definitions (3+ methods) in `**/services/**`, `**/core/**`, `**/lib/**`
- **Domain naming:** Use the directory name as the domain name (e.g., `src/multas/` → domain `multas`, `src/notificaciones/` → domain `notificaciones`). If multiple related files exist in a directory, they form one domain.
- **When to create separate domains vs. merge:** Each directory under `src/` (or equivalent) that represents a distinct functional boundary gets its own domain. Signs of a distinct domain: own `__init__.py`, different responsibility. Signs to merge: tightly coupled files in the same directory, shared data structures, no clear boundary.

## Extraction Rules

### Database spec.decree
- `Column(Integer)` / `Integer` → `i`, `Column(String)` / `String` → `s`, `Column(Float)` / `Float` → `f`
- `Column(Boolean)` → `b`, `Column(DateTime)` / `DateTime` → `t`, `Column(JSON)` / `JSONB` → `j`
- `primary_key=True` → `!` suffix
- `nullable=True` → `?` prefix
- `default=` → `=val`
- `ForeignKey('table.field')` → `->Entity.field`
- `unique=True` → `@unique`
- `Index('name', 'col1', 'col2')` → `#[col1,col2]`

### API spec.decree
- `@app.get("/path")` → `GET /path`
- `@app.post("/path")` → `POST /path`
- Pydantic `BaseModel` request bodies → `>fields`
- Response model annotations → `->Entity` or `->Entity[]`
- `Depends(get_current_user)` or similar auth dependencies → `@auth`
- `Security(...)` with role checks → `@role(name)`

### Application spec.decree
- Classes decorated with `@dataclass` or inheriting from base data classes → `+Entity` with fields
- Classes inheriting from `Enum` → `+EnumName : val1,val2,val3`
- Service/orchestrator classes → `+ClassName` with `.method(params) ->return`
- Module-level constants (UPPER_CASE assignments) → `K NAME type =value`
- Only include **public methods** (no `_prefixed` helpers)
- Type hints map to decree types: `str` → `s`, `int` → `i`, `float` → `f`, `bool` → `b`, `datetime` → `t`, `dict`/`Any` → `j`

### body.decree additions
- **Database:** SQLAlchemy cascade settings (`cascade="all, delete-orphan"`), hybrid properties, event listeners, Alembic migration notes
- **API:** FastAPI dependency injection chains, Pydantic validator methods, background tasks (`BackgroundTasks`), CORS configuration
- **Application:** Orchestration flow (what calls what in order), external API integrations (URLs, retry strategies, timeouts), business rule thresholds and formulas, caching TTLs

## Example

### Python + FastAPI + SQLAlchemy

Given a project with SQLAlchemy models and FastAPI routes:

#### Root manifest.decree
```
S analytics 1.2.0 postgres
D database [User,Event,Report]
D api [events,reports] >database
```

#### database/spec.decree
```
@v1

+User
 id u!
 email s @unique
 tier s ="free"

+Event
 id u!
 user ->User.id
 type s
 payload j
 created_at t =now
 #[user,type]
 #[created_at]

+Report
 id u!
 user ->User.id
 ?title s
 config j
 generated_at t
 #[user]
```

### Python Application Domains (Business Logic)

Given a project with SQL schema + Python application modules in `src/`:

#### Root manifest.decree
```
S fotomultas 0.1.0 postgres
D database [Camara,Captura,PlacaDetectada,Propietario,Vehiculo,Infraccion,Notificacion] (Auditoria)
D multas [GestorMultas,DatosInfraccion] >database
D notificaciones [ServicioNotificaciones] >database
D api [ClientePadronVehicular,DatosVehiculo] >database
D evaluacion [EvaluadorOCR,MetricasDeteccion,MetricasOCR]
```

#### multas/spec.decree
```
@v1
>database::Infraccion(id:i)
>database::PlacaDetectada(id:i)
>database::Captura(id:i)

K UMA_DIARIA f =113.14
K DESCUENTO_PRONTO_PAGO f =50.00

+RangoExceso : leve,moderado,grave,muy_grave

+EstadoInfraccion : pendiente,notificada,pagada,cancelada,en_disputa,prescrita

+DatosInfraccion
 folio s
 velocidad_registrada f
 limite_velocidad i
 exceso_velocidad f
 monto_multa f
 monto_uma f
 rango RangoExceso

+GestorMultas
 umbral_confianza_ocr f =0.85
 .identificar_infraccion(captura:Captura) ->DatosInfraccion
 .consultar_vehiculo(placa:s) ->DatosVehiculo
 .calcular_monto(exceso:f) ->f
 .almacenar_infraccion(datos:DatosInfraccion) ->Infraccion
 .procesar_deteccion(captura:Captura) ->Infraccion
```

#### multas/body.decree
```markdown
## GestorMultas
Orchestrates the full violation lifecycle: detect → validate OCR → query vehicle → calculate fine → store → notify.
procesar_deteccion() is the main entry point — calls each step sequentially, rolls back on failure.
OCR confidence threshold: plates below 0.85 are rejected (not stored as infractions).
Vehicle data cached locally for 24h to avoid redundant API calls to government registry.

## Fine calculation
Uses UMA 2026 ($113.14/day). Four brackets by speed excess:
1-20 km/h: 5-10 UMAs, 21-40: 10-20, 41-60: 20-30, >60: 30-40.
50% early payment discount if paid within 15 calendar days of notification.
```
