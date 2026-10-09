# External React Skills

Use this catalog when an additional specialist would materially improve a React task. Check the available-skill catalog first. If a needed skill is absent, recommend `$skill-installer`; do not install it without explicit authorization.

| Skill | Use it for | Project boundary |
| --- | --- | --- |
| `$vercel-composition-patterns` | Boolean-prop proliferation, explicit variants, compound components, reusable component APIs | Apply inside the FSD owner chosen by `$frontend-fsd-design`; do not turn every component into a Provider/compound namespace |
| `$vercel-react-best-practices` | Rendering/performance review, Effects, rerenders, client bundle and interaction efficiency | Use client-compatible rules only; ignore Next.js/RSC/server advice and preserve focused FSD public APIs |
| `$playwright` | Reproduce browser flows, inspect DOM/accessibility state, capture screenshots/traces | Project e2e files and `make e2e-admin` remain regression coverage; the skill is a diagnostic operator, not a replacement test architecture |
| `$dejank` | Flicker, remount churn, layout shift, focus loss, scroll reset, pop-in | Activate for a visible temporal defect or an explicit stability audit, not every UI change |
| `$modern-react-guidance` | React 19.2/19.3 API discovery and upgrade review | Treat as advisory; reject unconditional RSC, Suspense fetching, Actions, or mass codemods that conflict with Inertia/project contracts |
| `$react19-source-patterns` | Narrow scan for removed/changed React APIs during a migration | Verify every migration rule against current official React docs and project consumers before applying |

## Recommended installation order

1. `$vercel-composition-patterns` for day-to-day component architecture.
2. `$vercel-react-best-practices` for focused client rendering reviews.
3. `$playwright` for browser evidence and diagnosis.
4. `$dejank` when render continuity defects become a recurring class.
5. Migration-reference skills only during a React upgrade.

Do not install a broad React collection merely because it includes many skills. Prefer a small reviewed set with distinct activation triggers.

## Known exclusions

- Do not adopt a React View Transitions skill that still requires canary React outside Next.js; View Transitions are stable in React 19.3.
- Do not add Next.js, RSC, React Native, Tailwind, or Vercel-hosting skills unless the project actually adopts that stack.
- Do not let a generic code-quality skill replace the project's FSD ownership, Shared reuse, registry, or browser-test rules.
