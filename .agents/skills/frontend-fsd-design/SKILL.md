---
name: frontend-fsd-design
description: Plan, implement, and review a CakePHP/React/Inertia frontend with Feature-Sliced Design boundaries, Shared components, theme tokens, public APIs, CSS Modules, and a registry stack. Use for screens, forms, tables, cards, modals, frontend refactors, and UI architecture; do not use for backend-only work.
metadata:
  short-description: CakePHP/Inertia FSD workflow
---

# Frontend FSD Design

Use this skill for frontend work under `assets/inertia`. Use it together with `cake-development` when a task also changes a backend contract, route, MessageBus scenario, table-registry definition, or project architecture.

This file is the executable project guide. Do not defer a layer, import, component, or styling decision to an external FSD article. Resolve it from the rules and project examples below.

## Reference routing

- For any task that changes visual composition, hierarchy, forms, cards, tables, modals, feedback, responsive/touch behavior, or motion, read [references/application-design.md](references/application-design.md) completely before editing. It is the common application-design baseline and includes the routing boundary for specialized installed design skills.
- For requested UI polish/hardening or a final quality pass after a material visual or interaction change, add `$frontend-quality-loop`; it owns the iterative specialist-routing and verification loop.
- For React component/hook/state structure, duplication removal, effect correctness, reusable APIs, or React version changes, add `$react-code-quality`; it refines implementation inside the FSD owner selected here.
- Pure type, API, query, or architecture work that does not change rendered behavior does not need the design reference.
- Do not load every installed design skill for ordinary UI work. The common applicable rules are already consolidated in the project reference; use a specialized skill only for the narrow cases listed there.

## Start with the change, not with a new slice

Before editing:

1. Read the Inertia route entry and the components it actually renders.
2. Inspect one or two nearby implementations in the same domain.
3. Read the design reference when rendered behavior changes.
4. Search `assets/inertia/Shared` and the public APIs of existing slices before creating UI or helpers.
5. Add `$react-code-quality` when the change alters component composition, hooks, state/effects, reuse boundaries, or React APIs.
6. Classify each responsibility with the ownership table below.
7. State a short architecture checkpoint in commentary for a new slice or a material boundary change.

If the user's request already authorizes the implementation, continue after the checkpoint. Ask for a decision only when two choices would materially change the public contract, reuse boundary, or task scope. A local bugfix or style correction stays local unless the current placement is the cause of the bug.

Do not migrate unrelated legacy frontend merely because it does not yet follow FSD. A visual component is not automatically a feature, and a large JSX block is not automatically a widget.

## Project layer map and ownership

Use the existing paths and casing:

```text
assets/inertia/main.tsx              application providers and page resolver
assets/inertia/Pages                 route composition
assets/inertia/widgets               reusable, complete page blocks
assets/inertia/features              user intentions and mutations
assets/inertia/entities              stable domain read models and passive domain UI
assets/inertia/Shared                domain-agnostic UI and infrastructure
```

The configured aliases are `@pages`, `@widgets`, `@features`, `@entities`, and `@shared`. There is no `@app` alias. Do not invent aliases or rename `Shared` to `shared`.

Choose ownership by what the code knows and does:

| Location | Put here | Project example | Why |
| --- | --- | --- | --- |
| `main.tsx` | Root providers, Inertia page resolution, application bootstrap | `ThemeProvider` and `QueryClientProvider` | These concerns wrap every route and do not belong to a business page. |
| `Pages` | Route props/URL state, responsive page selection, layout assignment, orchestration of lower layers | `Pages/Vehicles/compare/Index.tsx` and `shared/VehicleComparisonPage.tsx` | The route decides what complete UI to compose; it should not become a reusable business library. |
| `widgets` | A reusable, independently meaningful card/workspace/section that composes entities and several features | `widgets/vehicle-card` | `VehicleCard` combines vehicle reads, status/actions, tabs, history and resources into a complete card. |
| `features` | A named user intention, interaction, or mutation and the state needed to complete it | `features/vehicles/merge-vehicle-cards` | Merging cards is a business action, not passive vehicle presentation. |
| `entities` | Stable domain types, read API/query options, DTO mapping, pure domain helpers, passive UI, domain columns/filters | `entities/vehicle` | These contracts describe a vehicle independently of a particular route or operation. |
| `Shared` | Reusable UI/infrastructure with no business entity, route, status, or workflow knowledge | `Shared/modal`, `Shared/inputs`, `Shared/composableTable` | Shared code is reusable because it does not encode a domain scenario. |
| Page-local folder | One-route flow or presentation that has no proven reuse or stable lower-layer owner | `Pages/GunLicense/components` and route-local `views` | Keeping route-specific code local is cheaper and clearer than speculative extraction. |

## Dependency direction

Use this direction:

```text
main/bootstrap -> Pages -> widgets -> features -> entities -> Shared
```

- A layer imports only lower layers.
- `Shared` imports no entities, features, widgets, or pages.
- Entities do not import features or widgets.
- Features may use entities and Shared, but do not import widgets or pages.
- Widgets compose features, entities, and Shared, but do not own route resolution.
- Pages may compose every lower layer.
- Keep a responsibility at the highest layer that uniquely knows the required context; move it lower only when its contract is stable and reusable.

Same-layer slices must normally remain independent and be composed above them. If one entity genuinely needs a narrow contract from another entity, expose a consumer-specific cross-import through `@x`, not through internals. The existing pattern is:

```ts
// entities/individual-resource/@x/individual-profile.ts
export type { IndividualResource, IndividualResourceType } from '../model/types'

// entities/individual-profile/model/types.ts
import type {
  IndividualResource,
  IndividualResourceType,
} from '@entities/individual-resource/@x/individual-profile'
```

Name the `@x` entry after its consumer and export the smallest possible contract. Do not use `@x` to bypass a questionable dependency.

## Public APIs

Every consumed domain slice and multi-file Shared package is entered through an `index.ts`/`index.tsx` at the boundary being consumed. A standalone Shared helper file may be its own entry when no package barrel exists; current examples are `@shared/api/readJsonResponse`, `@shared/api/uploadFile`, and `@shared/api/messageBusJob`.

Good imports already used in the vehicle flow:

```ts
import { vehicleQueryOptions, type VehicleDetailsDto } from '@entities/vehicle'
import { ConsolidateVehicleCardsModal } from '@features/vehicles'
import { VehicleCard } from '@widgets/vehicle-card'
import { TextButton } from '@shared/buttons'
import { Modal } from '@shared/modal'
```

An action sub-slice may itself be the public boundary. For example, `@features/individuals/register-individual` is valid because that directory has its own `index.ts`. Importing `@features/individuals/register-individual/ui/RegisterIndividualFields` is not valid outside that sub-slice.

Rules:

- Use relative imports inside a slice.
- Import another slice only through its public entry.
- Prefer a focused entry such as `@shared/modal` over the broad `@shared` barrel.
- Import a standalone Shared helper by its exact file entry; do not use that exception to reach inside a multi-file component package.
- Export only symbols that real consumers need.
- If a symbol is missing, decide whether it is intentionally public before exporting it.
- Do not export local CSS, private helpers, component internals, or raw transport details merely to make an import compile.

Known debt is not a pattern to copy:

- `Pages/Notifications/NotificationsPage.tsx` deep-imports `@entities/notification/lib/ReportLink` and `@entities/notification/ui/NotificationPreviewModal`. New consumers must use the entity public API; repair these imports when that slice is intentionally touched.
- `Shared/ui/app-layout/AppLayout.tsx` imports the auth feature, and `AppHeader.tsx` imports the notification entity. These are existing composition-root leaks. Do not add more upward imports to `Shared`; when redesigning this area, inject/compose those domain parts from the route or application root.

## Complete project example: vehicle comparison

Use this flow as the reference for a substantial screen:

```text
Pages/Vehicles/compare/Index.tsx
  -> chooses desktop/tablet with ResponsiveInertiaPage
  -> assigns AppLayout
  -> renders Pages/Vehicles/compare/shared/VehicleComparisonPage.tsx

VehicleComparisonPage
  -> reads vehicle query contracts from @entities/vehicle
  -> renders the complete @widgets/vehicle-card
  -> opens the @features/vehicles merge action
  -> composes @shared buttons, container, list, loader and typography

widgets/vehicle-card/ui/VehicleCard.tsx
  -> combines passive vehicle data with several vehicle actions
  -> owns complete card tabs and card-level composition

features/vehicles/merge-vehicle-cards
  -> owns merge form/mutation/interaction state
  -> uses vehicle types and Shared form/modal primitives

entities/vehicle
  -> owns reads, query options, types, registry adapter, columns and passive filters
```

This split is useful because route changes do not destabilize vehicle contracts, the merge action can evolve independently, and the complete card can be reused without duplicating its feature composition.

## Slice contracts

Create only the segments a slice needs; never add empty folders to resemble a template.

### Entity

```text
entities/<entity>/
├── api/       read requests, transport DTOs, response decoding/mapping
├── model/     stable types, query keys/options, schemas, pure helpers
├── ui/        passive entity UI, cells, columns, filters
├── lib/       slice-local pure utilities that fit neither api nor model
├── @x/        exceptional, narrow contracts for another entity
└── index.ts   public API
```

- Map transport DTOs to a stable frontend model at the API boundary when shapes differ.
- Keep TanStack Query keys and reusable read-query options in the entity; pages/widgets compose rather than duplicate them.
- Passive display belongs here. If a component starts a meaningful mutation or workflow, move that operation to a feature.
- Entity-specific columns, cells, filters, and option adapters belong here; generic table/input mechanics remain in Shared.
- A request used only by one action stays in that feature even when its payload contains the entity.

### Feature

```text
features/<group>/<action>/
├── api/       action-specific request and response contracts
├── model/     mutation hooks, form state, validation and pure action rules
├── ui/        button, form, modal or panel that performs the action
└── index.ts   action public API
```

Name features as user intentions: `merge-vehicle-cards`, `toggle-vehicle-status`, `register-individual`. Avoid vague buckets such as `vehicle-utils` or `common-actions`.

The feature owns pending/error/success interaction state for its action. It does not own an entire route, a reusable full card, or generic modal/input behavior.

### Widget

A widget is justified when the block is both independently meaningful and composition-heavy: a complete entity card, comparison workspace, identity shell, or reusable page section. Existing examples are `vehicle-card`, `individual-profile-card`, `company-card`, and `identity-shell`.

Do not create a widget for a single form section used once. Keep that section in the page or feature until reuse and responsibility are real.

### Page

The route entry may:

- receive server props and parse route/URL state;
- assign `AppLayout`;
- choose desktop/tablet implementations through `ResponsiveInertiaPage`;
- compose widgets/features and route-level loading/error/empty states;
- coordinate navigation after a completed use case.

Do not put reusable entity query keys, domain schemas, generic controls, or cross-route business actions in a page.

## Reuse the actual Shared surface

Search the focused public APIs and inspect a real usage before adding a component. Start with:

| Need | Use/search first |
| --- | --- |
| Buttons and button layout | `@shared/buttons`: `TextButton`, `TextButtonLink`, `IconButton`, `NavbarButton`, `ButtonLayout` |
| Form fields | `@shared/inputs`: `FieldLayout`, `TextInput`, `TextAreaInput`, `SelectInput`, async/preload select exports, `DateInput`, `Checkbox` |
| Modal/dialog/confirmation | `@shared/modal`, `@shared/ui/action-modal`, `@shared/AppDialog`, `@shared/AppEvents` |
| Toasts | `@shared/AppToast`: `notify`, `AppToaster` |
| Page/device composition | `@shared/InertiaPage`: `ResponsiveInertiaPage`, `WorkspaceScreenSwitch` |
| Visual structure | `@shared/container`, `@shared/card`, `@shared/bubble`, `@shared/scroll` |
| Text/icons/states | `@shared/typography`, `@shared/Icons`, `@shared/list`, `@shared/preloader` |
| Tabs/simple tables/history | `@shared/ui/tabs`, `@shared/ui/base-table`, `@shared/ui/card-history` |
| Registries | `@shared/composableTable`, `@shared/TableRegistryAdapter`; preserve `@shared/universal-table` only in existing flows unless the task explicitly migrates them |
| API helpers | `@shared/api/readJsonResponse`, `uploadFile`, `messageBusJob` |

Do not create a local imitation of a Shared control. If the current API almost fits, prefer composition. Change the Shared API only when the behavior is domain-agnostic and at least one real consumer needs it; then verify existing consumers.

## Registries and tables

For a new or materially reworked backend-driven registry, use this pipeline:

```text
route-scoped PHP table-registry definition
  -> route-scoped definition endpoint
  -> TableRegistryAdapter validation/query state
  -> route-scoped rows endpoint
  -> ComposableTable rendering
```

- The backend definition owns allowed columns, search, filter, sort, pagination, and safe query semantics.
- `TableRegistryAdapter` owns frontend contract validation, URL/query state, capabilities, presets, and derived filters.
- `ComposableTable` owns generic rendering only. It must not know domain routes, ABAC, toasts, modals, or backend endpoints.
- The page/feature owns toolbar actions, row actions, custom domain cells, breadcrumbs, permissions, and dialogs.
- Use the `workspaceV2` composition for new/reworked registries: filters/search left, domain actions right, pagination in page flow, and selection toggled from the actions-column header.
- Do not put actions or layout metadata into the PHP definition, leak SQL to the browser, or add an NSI/generic fallback endpoint.
- Keep an existing `UniversalTable` flow intact for a scoped fix. Do not choose it for a new registry without an explicit migration/compatibility reason.

## Design baseline

The detailed project rules for hierarchy, surfaces, typography, actions, forms, modal/toast feedback, responsive/touch behavior, motion, accessibility, and review live in [references/application-design.md](references/application-design.md). Apply that reference rather than copying visual values from a nearby page without understanding their role.

Keep the architectural invariant here: page/slice CSS uses CSS Modules and existing theme tokens; Shared owns reusable visual behavior; domain slices own only their composition and domain-specific presentation.

## Architecture checkpoint format

For a substantial frontend change, state only the decisions that affect implementation:

```text
Page: route props, URL state and responsive composition remain in ...
Widget: reuse/create ... because it combines ... and is independently meaningful.
Feature: ... owns the user action and mutation.
Entity: ... owns read contracts/types/passive UI.
Shared: reuse ...; no new primitive (or explain the required generic extension).
Public APIs: consume ... through .../index.ts.
Design: use ... composition and Shared controls; list only intentional deviations from the project reference.
Legacy boundary: keep/migrate ... and why.
Verification: typecheck + targeted e2e ...
```

Do not produce this ceremony for a one-line local correction; say that the fix stays in the existing owner and proceed.

## Verification

Match checks to the change:

```bash
cd assets/inertia
npm run typecheck
npm run lint -- <changed paths>
```

Run `npm run build` when changing bundling, page resolution, lazy imports, theme entry points, or when browser verification needs a fresh production bundle. Do not commit `webroot/js/inertia` or `bootstrap/inertia-ssr`.

For changed user behavior, update/run the closest module e2e through the project target, for example:

```bash
E2E_PASSWORD=... E2E_TEST_PATH=tests/e2e/modules/<module>/<flow>.spec.mjs make e2e-admin
```

Also run `git diff --check`. Before finishing, confirm:

- every cross-slice import follows the dependency direction and enters a public API;
- no new Shared import points upward into a domain layer;
- no new component duplicates an existing Shared control;
- the applicable checklist in `references/application-design.md` is satisfied for visual changes;
- targeted browser coverage exercises the real route and API contract for user-visible behavior.
