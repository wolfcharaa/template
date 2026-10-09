# React 19 In React/Inertia Applications

Use this reference for React upgrades and when adopting APIs introduced or materially changed in React 19.

## Establish the actual baseline

Read both the manifest and resolved lock entry before choosing an API:

```bash
cd assets/inertia
npm pkg get dependencies.react dependencies.react-dom devDependencies."@types/react" devDependencies."@types/react-dom"
npm ls react react-dom @types/react @types/react-dom --depth=0
```

Check `vite.config.mts` and installed dependencies before assuming React Compiler is enabled. An optional peer entry nested under `@vitejs/plugin-react` is not an installation or configuration.

Use the current official React documentation as the source of truth for release status and API contracts. External skills are routing/checklist aids, not version authorities.

## Project-compatible React 19 rules

### Refs

React 19 permits `ref` as a normal component prop. Prefer that shape for new components when a ref is genuinely part of the public contract. Do not mechanically rewrite existing `forwardRef` components: confirm compatibility with React Bootstrap, Radix, imperative handles, generic typing, and all consumers first.

### Context and `use`

Direct context providers and `use(context)` are available, but existing `Context.Provider` and `useContext` code remains understandable and supported. Use `use()` when its conditional reading or promise integration solves a concrete problem; do not migrate for novelty.

### Effects

Use Effects to synchronize React with an external system. Keep derived data in render and event-specific work in handlers or mutation callbacks. `useEffectEvent` is appropriate only for non-reactive logic invoked from an Effect; it is not a way to silence dependency linting.

### Async data and forms

React Actions, `useActionState`, `useOptimistic`, Suspense, and `use(promise)` are tools, not mandatory replacements for the project's established stack. Keep Inertia, TanStack Query, React Hook Form, Shared error handling, and backend contracts unless a scoped migration proves a better integration.

### Activity and transitions

Use `<Activity>` when a hidden subtree must preserve state while its effects are inactive. Use `startTransition` or `useDeferredValue` for non-urgent rendering where responsiveness is measurably improved.

React 19.3 stabilizes `<ViewTransition>` and Fragment refs. Adopt them only after runtime and type packages resolve to at least 19.3, and only for a concrete continuity, focus, measurement, or transition requirement. Motion still follows `$frontend-quality-loop` and its reduced-motion rules.

## React Compiler

React Compiler is a separate adoption decision.

1. Confirm `babel-plugin-react-compiler` is a direct dependency and the Vite/Babel integration is active.
2. Start with an incremental pilot on a representative slice.
3. Run typecheck, lint, production build, and targeted e2e before broadening the scope.
4. Keep components pure and follow the Rules of React; the compiler does not repair invalid component behavior.
5. Do not add manual memoization by default after the compiler is enabled, but retain existing memoization until a scoped cleanup proves it unnecessary.
6. Use profiling evidence for remaining manual `memo`, `useMemo`, and `useCallback` decisions.

Do not combine the runtime upgrade, compiler rollout, and a large component refactor into one unverifiable change.

## Upgrade checklist

1. Read the official release and upgrade notes for the target version.
2. Update `react`, `react-dom`, `@types/react`, and `@types/react-dom` together when compatible versions exist.
3. Inspect the lock diff for unrelated dependency churn.
4. Run `npm ls` and reject invalid or duplicated React roots.
5. Run typecheck, lint, and a production build.
6. Run targeted browser e2e for bootstrap, layouts, modals/portals, forms, and other ref-sensitive UI when the upgrade affects them.
7. Do not commit `webroot/js/inertia` or `bootstrap/inertia-ssr`.

## Official sources

- React 19.3: <https://react.dev/blog/2026/09/09/react-19-3>
- React Compiler: <https://react.dev/learn/react-compiler>
- You Might Not Need an Effect: <https://react.dev/learn/you-might-not-need-an-effect>
- Reusing Logic with Custom Hooks: <https://react.dev/learn/reusing-logic-with-custom-hooks>
- `use`: <https://react.dev/reference/react/use>
- `forwardRef`: <https://react.dev/reference/react/forwardRef>
