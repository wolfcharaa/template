---
name: cake-development
description: Develop and review a modular CakePHP application with MessageBus scenarios, table-registry reads, React/Inertia UI, pragmatic hexagonal boundaries, and repository checks. Use for CakePHP implementation, refactoring, architecture review, and commit preparation.
metadata:
  short-description: CakePHP application workflow
---

# CakePHP Application Development

Use this skill together with the global `development` skill in CakePHP
application repositories that follow the module and scenario layout described
below. Repository documentation overrides the examples in this skill.

## Reference Routing

Use the main rules in this file first. Read supporting references only when they match the current task:

- `references/message-bus.md` for MessageBus contracts, handlers, async flows, bindings, and registry compilation.
- `references/table-stack.md` for table-registry definitions, rows endpoints, Inertia registry screens, and composableTable work.
- `references/data-history.md` for audit/history, append-only journals, immutable snapshots, relation history, source versions, and read-scope of historical data.
- `references/git-conventions.md` before committing, preparing branch history, or reviewing staged changes.
- `references/feature-architecture.md` only when touching legacy `src/Feature/*` code or reconciling old feature terminology with the current `src/Module/*` target shape.

## Architecture

Read `docs/architecture.md` before implementation or refactoring under `src/Module`.

The target module model is pragmatic hexagonal architecture:

- `UserInterface` for transport/framework boundary.
- `Capability` for business scenarios, MessageBus contracts, handlers, ports, results, orchestration, and business flow.
- `Infrastructure` for technical adapters/services/options.
- `Feature` for optional extensions and UI/read overlays such as table-registry, export/import, print, dashboard, map, calendar, or grid representations.
- `SharedKernel` for global technical services and stable common contracts without module ownership.

Do not create new module/feature `Bootstrap` directories; keep wiring in `config/di/*.yaml` and complex initialization in `src/DependencyInjection`. `Domain` is not a mandatory target layer. Do not introduce DDD ceremony, `Policy`, `Specification`, `Input`, `Criteria`, named collections, generic `Shared`, or `Model/` buckets just to satisfy a pattern. Existing `Domain`, `src/Feature`, `Orchestration`, `Aggregation`, and `Outbounding` code is legacy/transition placement.

Table-registry definitions, registry rows, XLSX/DOCX export/print, and similar overlays for module entities belong under `src/Module/<Module>/Feature/<Scenario>/...` unless they are the core business scenario itself. Avoid technical grouping such as `Feature/TableRegistry/...` while the module has a small number of feature scenarios; prefer `Feature/ListLicenses`, `Feature/ListItems`, `Feature/PrintLicenseDocx`, etc. Thin presenter/read overlays do not get MessageBus `*Message`, `*Handler`, `*Result`, or scenario `*Port` just for shape; keep controllers directly in the feature scenario folder and let them call concrete infrastructure readers/storage when there is no business orchestration. Business relation endpoints must be scenario-local under the owning module; do not add generic relation routes or hide module registries behind NSI registry endpoints. Temporary direct dependencies from new module handlers to legacy `src/Feature` providers are allowed only as explicit `#[Wip]` transition debt.

Do not expand a globally shared/root entity table with context-specific columns just because one module needs a few extra fields. Put contextual attributes and resource links into adjacent tables owned by the module/scenario that needs them, with only the columns required by that task. For links from workflow entities such as work-calendar events to organizations, individual cards, preventive-attention cards, premises, or other resources, create explicit relation tables per resource/case instead of a generic polymorphic relation table or catch-all JSON payload. The source of truth belongs to the owning workflow relation; read models may denormalize small projections only when it materially simplifies registry/query performance.

Treat cross-card relations as module skills, not as extra columns bolted onto the root entity. The root create/update scenario creates the root record and returns the minimal useful outcome; addresses, objects, premises, activity types, event links, archive state, and similar sections live in their own scenario/endpoint when they have their own lifecycle or validation. If the relation is an optional extension over an existing module workflow, place it under a focused `Feature/<BusinessRelationName>`; if it changes state or applies business rules, keep the same local hexagonal shape with thin `UserInterface`, MessageBus `Capability`, scenario-local port, and `Infrastructure` implementation. Do not make feature code depend on a generic "relation manager" just to avoid naming the concrete business relation.

When a shared root entity needs contextual profiles, keep the root entity clean and put contextual state into module-owned tables. Do not put contextual foreign keys or module-specific columns on the root table just to make one workflow convenient. Keep exact table names, payload shapes, and accepted business vocabularies in `docs/architecture.md` or the relevant `.context/*` decision file rather than duplicating them here.

For table design, start from the business fact the table owns:

- Root/profile tables store identity, lifecycle, display fields, and fields intrinsic to that profile.
- Cross-entity participation is stored in explicit associative tables with payload columns such as relation type, share, basis, period, status, archive/audit fields, and comments.
- Resource links use concrete relation tables per resource type or business case, for example organization profile to juridicals, areas, passport objects, premises, calendar events, or check materials.
- Do not use generic polymorphic relation tables, catch-all JSON payloads, nullable columns for multiple unrelated resource types, or one "relation manager" when different links have different meaning or shape.
- A relation table may be the source of truth for a derived projection, but the projection must be traceable to explicit relation purpose/type, not to "any related row".
- Use database constraints for obvious invariants: primary/foreign keys, indexes on referencing FK columns, check constraints for periods and nonblank required text, and partial unique indexes for active duplicate prevention. Add range/exclusion constraints only when a real period-overlap scenario exists. Mirror those invariants in the PHP application layer when they affect user workflows, so capabilities return clear validation/capability errors before the database constraint is hit; the database remains the final guard for races, imports, scripts, and manual data changes.

For organization-like workflows, model contextual profiles as working entities and connect root entities, activities, places, and other resources through module-owned relation tables. If a create flow needs to create a linked root entity as part of the same user action, keep the user workflow atomic and keep the root entity a real root record, not an embedded draft. Use the current architecture/decision document for the exact fields, reference values, and endpoint names.

When a large user action needs several existing operations, prefer a composite Message that contains smaller typed Message contracts and dispatches them through `MessageContextInterface` inside the aggregate handler. Do not flatten known child shapes into a god-object payload, and do not inject handlers directly. Use this for workflows such as "create a root entity and immediately attach/link it"; keep child messages reusable and stable.

Do not mix root entity registries with relation facts. Relation facts get their own workspace mode, read overlay, table-registry definition, or card section. When two relation modes have different shape, use separate endpoints/routes instead of one union endpoint with mostly empty columns or an optional scope parameter that changes the meaning of the response. When a relation has business meaning, model it explicitly in that relation table; derived projections must be traceable to that explicit meaning, not to "any related row".

Do not add `Uup`/`uup` prefixes to broader concepts just because the first screen is in the UUP workspace. New module names, route/API prefixes, frontend identifiers, option keys, registry keys, and public contracts use natural business naming unless the lifecycle is truly UUP-specific. Existing broader `uup*` names are transition debt for a dedicated rename pass, not a pattern to copy.

Do not recreate `src/Module/Uup` as an umbrella/platform module. Shared application contracts with multiple consumers belong in `src/SharedKernel`, while UUP-specific workflows keep their own explicit module name such as `UupAreaTransfer` only when the lifecycle is truly UUP-owned.

## MessageBus

The project uses `romanfedorskij/message-bus` v6.1.

- `QueryHandler` returns business results.
- `CommandHandler` returns `void`.
- `EventSubscriber` returns `void` or `null`.
- Use stable `#[MessageAlias]` and explicit `bindingId` for durable/async/integration flows.
- Compile the registry after MessageBus changes:

```bash
docker/compose/dev.sh exec -T app php bin/console message-bus:compile
```

## Business Scenario Tests

Prefer Testo business-scenario tests through the MessageBus pipeline for cross-module workflows, permissions, side effects, registry visibility, and state transitions. Build these tests as executable business chains with explicit actors, scenario fixtures, real capability messages, and focused assertions over database state, emitted effects, and read visibility.

For DB-backed scenario tests, extend `App\Test\Support\DatabaseScenarioTestCase`. It guards that `Datasources.test` points to a PostgreSQL test database and aliases `default` to `test` so production MessageBus handlers and SQL storages use real migrated tables without touching local/default data. Prepare the schema with `make test-migrate`; use browser/e2e data setup only for UI rendering checks.

Do not grow browser `.mjs` e2e tests into primary business-rule coverage. Keep Playwright/browser tests as thin UI coverage that verifies screens open, data is visible, forms/selects/buttons can be interacted with, routes are reachable, and important user-facing states render. Browser tests may cover one happy UI path, but business correctness belongs in Testo MessageBus scenario tests.

## Repository Invariants

- Use `make` targets or `docker/compose/dev.sh` for dev Docker operations.
- Do not add new selector/search-option endpoints through generic options APIs or form-local `Read*FormOptions`; frontend select options use explicit one-source controllers in `src/SharedKernel/UserInterface/Options/{Static,Preload,Async}`. These controllers may use direct SQL in the controller when the source is endpoint-local; do not add SQL storage/source/reader layers without real reuse.
- For frontend work, reuse components from `assets/inertia/Shared` for inputs, buttons, dialogs, layout, tables, toasts, and common UI states before adding page-local controls. Add local UI only when no shared component fits the interaction and the reason is clear in the surrounding code.
- Do not add legacy route-permission seed files or migrations for new access; use route ABAC context and existing access cases.
- Cron services must use the base Alpine/BusyBox `crond` with its default crontab spool (`/var/spool/cron/crontabs`). Generate project commands from `docker/php/cron/profiles.yaml` into per-user crontabs and run the standard foreground daemon; do not replace it with tail-only containers, custom `crond -c` paths, `CRON_LOG_PATH` overrides, or ad hoc scheduler loops.
- Do not commit local env/secrets, runtime logs, smoke/e2e reports, generated Inertia/SSR output, or release bundles.

## Code Style

When several branches depend on the same value, normalize or read that value once, make an early return/guard when it is absent or unsupported, and then branch with `switch`/`match`/`case` rather than repeating the same variable checks through multiple `if` blocks. Avoid scattering identical null/empty checks inside every branch when a single upfront guard makes the control flow clearer.
