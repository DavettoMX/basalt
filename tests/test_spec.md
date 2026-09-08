# Basalt Test Suite — Spider Schema Fixtures

Test suite for validating decree generation against SQL schemas derived from the
Spider benchmark. Each fixture targets specific grammar patterns and hierarchy
fidelity requirements.

## Test Matrix

| Fixture | Grammar targets | Hierarchy targets |
|---------|----------------|-------------------|
| `spider_concert` | Basic FKs, junction table, all type codes | Baseline: manifest lists entities, spec has correct fields, body has cascade behavior |
| `spider_self_ref` | Self-referencing FK (`->Entity.id` on same entity) | Manifest shows single entity; spec encodes the cycle; body explains tree traversal |
| `spider_university` | Deep FK chain (5 levels), nullable FKs | Manifest dependency graph is acyclic; spec forward-decls cross-domain; body captures computed fields |
| `spider_flights` | No explicit PK, composite unique, compound indexes | Spec omits `!` when no PK; composite `@unique` and `#[]` encode multi-column constraints |
| `spider_social` | Multiple self-refs on same entity, symmetric junction | Spec distinguishes two `->User.id` refs on one entity; junction has no extra payload fields |
| `spider_hospital` | All patterns combined (FK, self-ref, junction, no-PK, depth≥4) | Full 3-tier fidelity: manifest topology matches spec entities; spec constraints match SQL; body adds non-structural info only |

---

## Scenario 1 — `spider_concert`: Basic FKs + Junction Table

**Source:** Spider `concert_singer` (adapted)

**Schema shape:**
- `Stadium` — standalone entity
- `Singer` — standalone entity
- `Concert` — FK to Stadium
- `SingerInConcert` — junction: FK to Singer + FK to Concert

**Grammar coverage:**
- `->Entity.field` on two different target entities
- Junction table with two FKs and no business payload
- Type codes: `i`, `s`, `f`, `t`
- `!` (PK), `?` (nullable), `=` (default)

**Hierarchy assertions:**
- **Manifest:** `D database [Stadium,Singer,Concert,SingerInConcert]` — all 4 public
- **Spec:** SingerInConcert has exactly 2 FK arrows + its own PK, no extra fields
- **Body:** describes that SingerInConcert is a pure junction (no cascade, no payload)

---

## Scenario 2 — `spider_self_ref`: Self-Referencing FK

**Source:** Spider `employee_hire_evaluation` (adapted)

**Schema shape:**
- `Employee` — has `manager_id -> Employee.id` (nullable, CEO has NULL)
- `Department` — has `head_id -> Employee.id`
- `Evaluation` — FK to Employee

**Grammar coverage:**
- Self-referencing FK: `->Employee.id` inside `Employee` entity
- `?` on self-ref (nullable — root of tree has no manager)
- Cross-entity FK cycle: Employee→Employee, Department→Employee

**Hierarchy assertions:**
- **Manifest:** 3 entities, `Department` depends on having Employee resolved first
- **Spec:** Employee.manager field is `?manager ->Employee.id` (nullable + self-ref)
- **Body:** documents tree semantics (org chart), explains NULL = top-level

---

## Scenario 3 — `spider_university`: Deep Relation Chain (5 levels)

**Source:** Spider `college_2` (adapted)

**Schema shape:**
- `Department` (level 0)
- `Instructor` → Department (level 1)
- `Course` → Department (level 1)
- `Section` → Course (level 2)
- `Enrollment` → Section + Student (level 3, junction)
- `Student` → Department (level 1, also advisor → Instructor)
- `Advisor` → Student + Instructor (level 3, junction)

**Grammar coverage:**
- FK chain depth ≥ 5: Department → Course → Section → Enrollment → Student → Advisor → Instructor → Department
- Multiple FKs from one entity to different targets
- Nullable FK (`?advisor`)
- Junction tables at different depth levels

**Hierarchy assertions:**
- **Manifest:** dependency order is representable (no domain-level cycles since it's 1 domain)
- **Spec:** forward declarations are NOT needed (all entities in same domain); all `->` refs resolve within the file
- **Spec:** `Enrollment` and `Advisor` clearly identifiable as junctions (2+ FKs, minimal payload)
- **Body:** captures enrollment semantics (grade, semester), advisor assignment rules

---

## Scenario 4 — `spider_flights`: No Explicit PK + Composite Constraints

**Source:** Spider `flight_2` (adapted)

**Schema shape:**
- `Airport` — has PK
- `Airline` — has PK
- `Flight` — has PK, FKs to Airport (origin + destination)
- `FlightLeg` — NO explicit PK, identified by (flight_id, leg_number)
- `Reservation` — composite unique on (passenger_name, flight_id, date)

**Grammar coverage:**
- Entity WITHOUT `!` marker (FlightLeg has no single-column PK)
- Composite unique: `@unique[passenger_name,flight_id,date]`
- Two FKs to same entity type: `->Airport.id` appears twice on Flight (origin, destination)
- Compound index: `#[flight_id,leg_number]`

**Hierarchy assertions:**
- **Manifest:** FlightLeg is still listed as a public entity despite having no PK
- **Spec:** FlightLeg has NO field with `!` suffix; composite identity expressed via `#[]` or `@unique[]`
- **Spec:** Flight has two distinct `->Airport.id` references with different field names
- **Body:** explains FlightLeg is ordered by leg_number within a flight

---

## Scenario 5 — `spider_social`: Multiple Self-References + Symmetric Junction

**Source:** Synthetic (social network pattern)

**Schema shape:**
- `User` — standalone
- `Friendship` — junction: `user_a -> User.id`, `user_b -> User.id` (symmetric)
- `Message` — `sender -> User.id`, `recipient -> User.id`
- `Block` — `blocker -> User.id`, `blocked -> User.id`

**Grammar coverage:**
- Same target entity referenced multiple times from one entity (2x `->User.id`)
- Three different junction/relation tables all pointing to `User`
- Symmetric vs asymmetric relations (Friendship is symmetric, Block is not)
- `@unique[user_a,user_b]` on junction to prevent duplicate friendships

**Hierarchy assertions:**
- **Manifest:** All 4 entities listed; no dependencies (single domain)
- **Spec:** Each `->User.id` ref is on a distinctly-named field (sender vs recipient, user_a vs user_b)
- **Spec:** Field names preserve semantic meaning (not just `user_id_1`, `user_id_2`)
- **Body:** documents symmetry constraint on Friendship (a,b) = (b,a), asymmetry on Block

---

## Scenario 6 — `spider_hospital`: Combined Patterns (Integration)

**Source:** Synthetic (hospital management — all patterns combined)

**Schema shape:**
- `Department` — standalone
- `Doctor` → Department, `?supervisor -> Doctor.id` (self-ref)
- `Patient` — standalone, no explicit PK (identified by SSN composite)
- `Admission` → Patient + Doctor + Department (3 FKs, junction-like)
- `Treatment` → Admission + Doctor (deep: Department→Doctor→Admission→Treatment)
- `DoctorSpecialty` — junction: Doctor + Specialty (pure junction, no payload)
- `Specialty` — standalone

**Grammar coverage:**
- Self-referencing FK (Doctor.supervisor)
- No explicit PK (Patient uses `@unique` on SSN)
- Junction table (DoctorSpecialty)
- Deep FK chain (4 levels: Department → Doctor → Admission → Treatment)
- Nullable FK (?supervisor)
- `@sens` on Patient fields (SSN, medical_record_number)
- Three FKs on one entity (Admission)

**Hierarchy assertions:**
- **Manifest:** 7 entities, correct public/private classification (DoctorSpecialty could be private)
- **Spec:** All grammar symbols appear: `!`, `?`, `=`, `->`, `#[]`, `@sens`, `@unique`
- **Spec:** Patient has NO `!` field, has `@unique` on ssn
- **Spec:** Doctor.supervisor is `?supervisor ->Doctor.id`
- **Spec:** Admission has exactly 3 `->` references
- **Spec:** Treatment's FK chain is traceable: Treatment→Admission→Doctor→Department
- **Body:** documents triage rules, cascade behavior on patient discharge, sensitive data handling

---

## Validation Rules (Cross-Cutting)

These rules apply to ALL fixtures and validate decree correctness:

### V1 — Lossless FK Representation
Every `REFERENCES` / `FOREIGN KEY` in the SQL input MUST appear as a `->Entity.field` in the spec output.
**Count the FKs in SQL, count the `->` in spec — they must match.**

### V2 — Self-Reference Integrity
A `->Entity.id` where Entity is the SAME entity being declared must:
- Use `?` prefix if the column is nullable in SQL
- Resolve to a valid field in the same entity block

### V3 — Junction Table Identification
A junction table (2+ FKs, ≤1 non-FK non-PK field) must:
- Appear in the spec with its FK arrows intact
- Have minimal fields (PK + FKs + optional timestamp)
- Be documented in body.decree as a junction/association

### V4 — No-PK Entity Handling
When a SQL table has no `PRIMARY KEY`:
- The spec entity MUST NOT have any field with `!` suffix
- Identity should be expressed via `@unique[]` or `#[]`

### V5 — Relation Depth Traceability
For any FK chain A→B→C→...→N, each hop must be independently resolvable:
- Every `->Entity.field` must point to a declared entity
- The target field must exist in that entity's declaration
- Circular chains (self-refs) must be detectable by checking entity name matches

### V6 — Manifest-Spec Consistency
- Every entity in `D [public]` line of manifest must have a `+Entity` block in spec
- Every entity in `D (private)` must have a `-Entity` block in spec
- No entity in spec that isn't listed in manifest
- Entity count: `wc -l` of `+` and `-` lines in spec == count of entities in manifest

### V7 — Spec-Body Separation
- body.decree MUST NOT contain field names, types, or constraint syntax (that's spec's job)
- body.decree MUST contain behavioral information not derivable from spec
- Every `## Entity` header in body must correspond to an entity in spec
- No structural duplication between spec and body

### V8 — Manifest Topology
- If entity A references entity B via FK, and they're in different domains, the manifest must show `>dependency`
- Within a single domain, no dependency line is needed (all resolved internally)
- The manifest dependency graph must be acyclic at the domain level

### V9 — Type Code Fidelity
- SQL `INTEGER`/`INT`/`BIGINT` → `i`
- SQL `VARCHAR`/`TEXT`/`CHAR` → `s`
- SQL `FLOAT`/`REAL`/`DECIMAL`/`NUMERIC` → `f`
- SQL `BOOLEAN`/`BOOL` → `b`
- SQL `TIMESTAMP`/`DATETIME`/`DATE` → `t`
- SQL `UUID` → `u`
- SQL `JSON`/`JSONB` → `j`
- No type code is invented or omitted

### V10 — Constraint Completeness
- Every `NOT NULL` → field is NOT prefixed with `?`
- Every nullable column → field IS prefixed with `?`
- Every `DEFAULT x` → field has `=x`
- Every `UNIQUE` → field has `@unique` (single) or `@unique[cols]` (composite)
- Every `CREATE INDEX` → `#[fields]` in spec
