# table-registry + TableRegistryAdapter + composableTable

## Layers

1. PHP `romanfedorskij/table-registry` (`Wolfcharaa\TableRegistry`) describes the read model, allowed query, and safe SQL compilation.
2. `assets/inertia/Shared/TableRegistryAdapter` validates the backend contract and builds the frontend view-model/query.
3. `assets/inertia/Shared/composableTable` renders rows, columns, layout, and UI primitives.

Feature pages own routes, permissions, toolbars, row actions, modals, custom cells, and the domain view. Do not push those concerns into PHP definitions or table render-core.

## Backend Definition

In a module feature/read overlay, create a local provider with a stable `REGISTRY_KEY` and `definition(): TableRegistryDefinition`. Define source/count source, primary key, columns/select/value objects, search/filter/sort, payload-only or auxiliary hydration, and default sort/query.

Declare filters in the definition: text, date range, static/async select, or a specialized definition. User values go through `RegistrySqlQueryInput` and the compiler; do not concatenate them into SQL expressions.

## Endpoints

- `.../definition` returns the definition.
- `.../rows` builds `RegistrySqlQueryInput::fromArray`, compiles with `PostgresRegistrySqlCompiler`, executes SQL with params, counts total, and applies `RegistryRowsProjector`.

Rows response shape: `rows`, `total`, `page`, `per_page`.

Frontend definition contract: `schemaVersion`, `registryKey`, `title`, `primaryKey`, `columns`, `query.search`, `query.pagination`, optional `query.defaultSort`. Source and raw SQL details must not leave the backend.

## New Inertia Registry Screen

1. Create feature-local `TableRegistryDefinition` and separate `definition`/`rows` controllers.
2. Register UI and API routes with the same ABAC contour. Check route cache when routes are not visible.
3. Inertia controller passes minimal props: registry key/title, CSRF, and explicit feature `apiBaseUrl`. Do not rely on NSI fallback.
4. Frontend loads route-scoped `definition`, then route-scoped `rows`. Unknown registry keys must not silently fall back to `/api/nsi/registry/...`.
5. Feature page explicitly defines read-only/capabilities, toolbar, row actions, and breadcrumbs. Read-only screens must not show NSI create/import/print actions.
6. If the browser uses `webroot/js/inertia`, build assets before browser verification. Typecheck does not prove the browser received the current bundle.

## Registry v2 Layout

For new or reworked registries, the main contract is full-width `workspaceV2` over `ComposableTable`: search and promoted filters on the left, domain actions on the right, pagination in normal page flow, and no desktop sticky-bottom panel.

The table header can accept a control slot near the `Действия` column. Core `composableTable` renders only `rowActions.headerControl`; the feature decides whether it is a button, dropdown, popover, or modal trigger.

Row selection mode in `workspaceV2` is toggled by this header control in the `Действия` column, not by a separate toolbar `Выбор` button. The checkbox column is visible only when selection mode is enabled or rows are selected.

## Adapter And Query

Adapter owns `apiBaseUrl`, routes, capabilities, metadata, default layout, derived filters/sortable keys, URL sync, and presets.

```text
Inertia context → route-scoped definition → validation/normalization
→ initial query → route-scoped rows → ComposableTable
```

Initial query priority: page defaults → backend `defaultQuery` → backend `defaultSort` → `initialQuery` → URL. After manual changes, defaults are not re-applied. Sort belongs in `defaultSort`. Do not duplicate `registryKey` as `registry_id`.

Serialization: scalar `filter_status=formed`; array `filter_status[]=formed`; sort `sort_col=createdAt&sort_dir=desc`. Presets override defaults; incompatible presets should be reset through a `table_option` migration.

## composableTable

Core knows rows, columns, optional layout/selection/render primitives. It does not know API, Inertia, ABAC, toasts, modals, toolbars, pagination, filters, presets, or theme.

- `ComposableTable` is the low-level core.
- `ComposableTableFacade` is the ordinary table with decorators/defaults.
- `createComposableTableTemplate<Row>()` defines typed columns/actions/custom cells.
- `ComposableTablePageShell` provides layout and slots.
- `ComposableTablePageTemplate` provides toolbar/search/reload/pagination.
- `RegistryTableFilterSettings` renders filters from definition.
- `createRegistryDefinitionTableTemplate` is for simple read-only registries with URL sync, presets, rows/export, and preview.

NSI is the reference for a fully explicit assembly. Domain rules do not move into Shared. Custom cells receive minimal props through `mapRowToProps`.

## Registry Slice Tests

- PHPUnit is required for backend definition, SQL compilation/query semantics, access/domain rules, and response projection according to change risk.
- If frontend behavior changes, add or update `tests/e2e/admin-ui.spec.mjs` or the relevant module e2e. Go through real auth/navigation and check real `definition`/`rows` URLs, HTTP status, key UI, and browser/runtime errors.
- Do not mock authorization when ABAC changes. Rows may be locally mocked, but route contract and access must remain real.
- Minimum checks: PHP syntax/targeted PHPUnit, frontend typecheck or known baseline note, `git diff --check`, and targeted e2e for user-visible behavior.

## Do Not

- Put actions/capabilities/layout or `metadata.actions` in PHP definition.
- Leak SQL/source details into frontend contract.
- Use legacy fallback `/api/registry/{registryKey}`.
- Load API/query inside composableTable core.
- Move domain rules into Shared.
- Repeat columns inside rows.
- Rename backend query keys on the frontend.

Check registry key, primary key, types, allowed filters/search/sort, endpoint separation, parameterized compiler, schema validation, URL/reset/presets/pagination, and loading/error states.
