---
name: react-code-quality
description: Improve and review mvdcake React/Inertia code for clear component composition, reusable logic, effect and state correctness, typed APIs, and version-gated React 19 usage. Use for React component or hook design, duplication removal, frontend refactors, performance readability, and React upgrades; do not use for backend-only or purely visual styling work.
metadata:
  short-description: mvdcake React code quality
---

# React Code Quality

Use this skill for React and TypeScript implementation under `assets/inertia`. Use it with `$frontend-fsd-design`: that skill decides ownership, dependency direction, public APIs, Shared reuse, and visual conventions; this skill decides how components, hooks, state, effects, and reusable logic should be shaped inside those boundaries.

Project rules override external React skills. In particular, mvdcake is a CakePHP/Inertia application, not a Next.js or React Server Components application.

## Reference routing

- Read [composition and reuse](references/composition-and-reuse.md) when splitting components, extracting hooks/helpers, reducing repeated code, changing component APIs, or reviewing effects and state.
- Read [React 19](references/react-19.md) when upgrading React, adopting a new React API, changing refs/context/forms/concurrency, or considering React Compiler.
- Read [external skills](references/external-skills.md) when choosing or installing an additional React specialist. It records the supported role and project-specific caveats for each candidate.

Do not load all references for a narrow change.

## Working rules

1. Read the route/component and one or two nearby consumers before extracting anything.
2. Search the current slice, lower FSD layers, and focused Shared public APIs before creating a second implementation.
3. Classify the repeated concern before choosing an abstraction:
   - repeated markup or layout composition: component;
   - repeated React lifecycle or interaction behavior: custom hook;
   - repeated pure transformation or validation: plain TypeScript function;
   - repeated server-state access: entity query options or a focused feature/entity data hook;
   - repeated labels, icons, colors, permissions, or status metadata: one typed record keyed by the discriminant.
4. Keep one-off route knowledge local. Promote code only when its contract is stable and a real second consumer exists, or when an existing lower layer already owns that responsibility.
5. Prefer explicit component variants and composition over a generic component controlled by combinations of boolean props.
6. Model mutually exclusive UI states with discriminated unions instead of independent booleans that permit impossible combinations.
7. Derive values during render. Use Effects only to synchronize with an external system; keep user-triggered work in the event handler or mutation callback that caused it.
8. Keep server state in Inertia props or TanStack Query. Do not introduce `useEffect` plus local state as a second cache.
9. Optimize only from evidence. Do not add `memo`, `useMemo`, or `useCallback` as decoration, and do not remove existing memoization merely because React Compiler exists elsewhere.
10. Keep the public component near the top of the file and name extracted helpers by intent so the file reads from scenario to detail.

## Project overrides for internet guidance

- Keep focused FSD `index.ts` public APIs. Generic advice to ban barrel files does not override the project boundary contract.
- Do not introduce RSC, Server Actions, Next.js conventions, or `use(promise)` fetching merely because an external skill recommends them.
- React Hook Form, Inertia mutations, TanStack Query, Shared controls, and current CSRF/error handling remain the default application stack.
- `use()` is an additional API, not a mandatory replacement for `useContext()`.
- New React 19 components may accept `ref` as a prop, but broad `forwardRef` migrations require consumer verification and a separate scoped change.
- Use only APIs supported by the versions resolved in `package-lock.json`; a version range in `package.json` is not proof that the installed API exists.
- Treat an optional peer dependency in the lock file as absent until its package and build configuration are actually present.

## External specialist routing

Inspect the available-skill catalog only when the task needs a specialist:

- `$vercel-composition-patterns` for a focused component API or boolean-prop refactor;
- `$vercel-react-best-practices` for a focused performance/rendering review, applying only client-side rules compatible with Inertia;
- `$playwright` for interactive browser diagnosis, snapshots, and trace evidence while project e2e remains authoritative regression coverage;
- `$dejank` for visible flicker, remount, layout shift, focus loss, scroll reset, or render continuity defects;
- `$modern-react-guidance` or `$react19-source-patterns` only as version-migration references, checked against current official React documentation.

If a useful specialist is unavailable, name it and recommend installation through `$skill-installer`; do not install it implicitly. The local rules and references remain sufficient for ordinary work.

## Verification

For changed React code, run checks proportional to the diff:

```bash
cd assets/inertia
npm run typecheck
npm run lint -- <changed paths>
```

Run `npm run build` for dependency, compiler, bundler, page-resolution, or production-asset changes. For changed behavior, update or run the closest targeted browser e2e through `make e2e-admin`. Do not commit generated Inertia or SSR output.

Before finishing, confirm that the change removed rather than relocated duplication, did not create an upward FSD dependency, did not duplicate server state, and did not introduce a React API newer than the resolved runtime/types.
