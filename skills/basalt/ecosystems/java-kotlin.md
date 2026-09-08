# Basalt: Java / Kotlin Detection & Extraction

## Detection Patterns

### Database / Schema
- `**/*.java`, `**/*.kt` containing `@Entity` and `@Table` — JPA / Hibernate
- `**/*.java`, `**/*.kt` containing `@Document` — Spring Data MongoDB
- `**/migrations/**/*.sql`, `**/db/migration/**/*.sql` — Flyway / Liquibase

### API / Routes
- `**/*Controller.{java,kt}` containing `@RestController` or `@Controller` — Spring MVC
- `**/*Controller.{java,kt}` containing `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping` — Spring
- `**/*Resource.{java,kt}` containing `@Path` — JAX-RS (Jersey, Quarkus)

### Application / Business Logic
- `**/service/**/*.{java,kt}`, `**/core/**/*.{java,kt}` containing `@Service`, `@Component`, or plain classes with business logic
- `**/domain/**/*.{java,kt}` containing domain model classes
- **Domain naming:** Use the package name as domain name (e.g., `com.app.billing` → domain `billing`)

## Extraction Rules

### Database spec.decree (JPA)
- `@Id` + `@GeneratedValue` → `!` suffix. `GenerationType.UUID` → `u!`, `GenerationType.IDENTITY` → `i!`
- `String` → `s`, `Integer`/`Long` → `i`, `Double`/`BigDecimal` → `f`, `Boolean` → `b`, `LocalDateTime`/`Instant` → `t`
- `@Column(nullable = false)` → required (no prefix). `@Column(nullable = true)` or no annotation → `?` prefix
- `@Column(unique = true)` → `@unique`
- `@ManyToOne` + `@JoinColumn(name = "...")` → `->Entity.field`
- `@Column(columnDefinition = "jsonb")` → `j`

### API spec.decree (Spring)
- `@GetMapping("/path")` → `GET /path`
- `@PostMapping("/path")` → `POST /path`
- `@PathVariable` params preserved: `/users/{id}` → `/users/:id`
- `@RequestBody` type → `>fields`
- Return type `ResponseEntity<Entity>` → `->Entity`
- `@PreAuthorize("hasRole('ADMIN')")` → `@role(admin)`
- `@Secured` or Spring Security config → `@auth`

### Application spec.decree
- Classes with `@Service` or `@Component` → `+ClassName` with `.method(params) ->return`
- POJOs / data classes / records → `+Entity` with fields
- Java enums → `+EnumName : VAL1,VAL2,VAL3`
- Kotlin `data class` → `+Entity` with fields
- Kotlin `sealed class` / `enum class` → `+Name : val1,val2`
- `static final` constants → `K NAME type =value`

### body.decree additions
- **Database:** Hibernate fetch strategies (LAZY/EAGER), `@Transactional` boundaries, Flyway migration ordering, `@EntityListeners` audit hooks
- **API:** Spring Security filter chain, exception handler (`@ControllerAdvice`), validation groups (`@Validated`), `@Async` methods
- **Application:** dependency injection patterns, `@Transactional` propagation, `@Scheduled` tasks, `@EventListener` patterns
