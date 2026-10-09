# React Composition And Reuse

Use this reference when a React change involves duplication, component APIs, hooks, effects, state shape, or readability.

## Choose the smallest correct reuse boundary

| Repetition | Preferred owner | Avoid |
| --- | --- | --- |
| JSX structure with stable slots | A component in the nearest owning slice | Copying the block or creating a global component with domain props |
| Interaction/lifecycle behavior | A custom hook in the nearest owning slice | A hook that returns a large unstructured bag of unrelated state |
| Pure mapping, parsing, formatting, validation | A plain typed function | A hook with no React behavior |
| Server reads and cache keys | Entity query options or an owning feature/entity hook | Page-local fetch Effects and duplicated cache state |
| Mutation workflow | A named feature with its own pending/error/success behavior | Generic mutation helpers that hide business intent |
| Status labels, colors, icons, capabilities | One exhaustive typed record | Parallel maps or repeated `switch` statements across files |
| Reusable complete composition | Widget | Turning every large JSX fragment into a widget |
| Domain-agnostic primitive | Focused Shared package | Shared code that imports an entity, feature, widget, or page |

One use stays local. A second real use justifies an extraction at the closest common owner when the two cases have the same reason to change. Similar-looking code with different domain rules should remain separate.

## Component APIs

Prefer APIs that make valid usage obvious:

- replace mode flags such as `editable`, `compact`, `selectable`, and `withFooter` with explicit variants when the modes change behavior or structure;
- use `children` or named composition points for caller-owned content;
- use compound components only when several related parts share state and consumers genuinely need flexible composition;
- keep simple components simple: do not add a Provider, namespace, slot system, or polymorphic API for one fixed layout;
- use a discriminated union when props describe mutually exclusive variants;
- keep transport DTOs and raw response details out of generic UI props.

Good component boundaries reduce the number of valid combinations. A component with many optional fields and booleans usually exposes implementation details instead of a coherent contract.

## Hooks and state

Custom hooks share logic, not state. Each call owns its own state unless the hook deliberately reads a shared external store or Context.

A focused hook should expose a coherent concept, for example query state plus actions for one interaction. Split a hook when its callers regularly ignore unrelated return values or when independent concerns cause each other to rerender.

Prefer:

- derived values computed during render;
- lazy `useState` initialization for expensive initial computation;
- functional state updates when the next value depends on the previous value;
- one state machine/discriminated union for mutually exclusive async states;
- state at the lowest common owner that needs to coordinate it;
- Context only for a stable cross-tree dependency, not as a substitute for ordinary props or composition.

Avoid:

- mirroring props or query data into state without an edit/draft requirement;
- Effects whose only job is to set derived state;
- an Effect that reacts to a flag set by an event handler instead of performing the work in the handler;
- one giant hook that owns transport, form state, modal state, notifications, navigation, and presentation;
- multiple booleans such as `isLoading`, `isSuccess`, and `isError` when they can contradict one another.

## Duplication review

Before extracting, compare the candidate blocks:

1. Do they represent the same business or UI concept?
2. Do they change for the same reason?
3. Can the shared contract be named without `common`, `base`, `generic`, `misc`, or a long list of modes?
4. Does extraction remove branching and knowledge from callers, or merely move duplicated lines into a parameter-heavy function?
5. Is the proposed owner allowed by the FSD dependency direction?

If the answers are weak, keep the code local and make each case readable. DRY is not a reason to merge concepts that only look alike.

## Readability review

- Keep the exported component or hook first, followed by helpers in call order.
- Prefer early returns for loading, missing, forbidden, and error states.
- Name callbacks after the user action: `handleAttachIndividual`, not `handleClick`.
- Parse and validate external data at its boundary; trust the internal type afterward.
- Keep one source of truth for route/query/form state.
- Avoid inline component declarations inside a render function because their identity changes on each render.
- Use comments only for non-obvious constraints or decisions; make ordinary intent visible through names and types.

## Refactor stopping condition

Stop when the changed flow has one clear owner, callers use a small explicit API, repeated behavior has one implementation, and the relevant typecheck/lint/e2e checks pass. Do not continue general cleanup outside the requested slice.
