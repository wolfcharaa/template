---
name: frontend-quality-loop
description: Run a focused quality loop for material React/Inertia UI changes, routing work through the project FSD and React-code baselines plus Sonner, mobile/touch, visual-polish, and restrained-motion specialists. Use for requested UI polish or hardening and after substantial screen, form, card, modal, registry, or Shared-component changes; do not use for backend-only, copy-only, or pure type/API work.
metadata:
  short-description: React/Inertia frontend quality loop
---

# Frontend Quality Loop

Use this skill after or alongside `$frontend-fsd-design` and `$react-code-quality`. It is an orchestration layer, not a replacement for the project's FSD boundaries, React composition/state rules, Shared components, theme tokens, or the baseline in [the application design reference](../frontend-fsd-design/references/application-design.md). Add `$cake-development` when the frontend task changes a backend contract, route, MessageBus scenario, table-registry definition, or project architecture.

The goal is a screen that works correctly first and then feels deliberate: clear hierarchy, complete async states, reliable feedback, usable pointer/keyboard/touch behavior, and only justified motion. Do not turn a local correction into an unsolicited redesign.

## Specialist readiness

`$react-code-quality` is the default implementation-quality layer for material React changes, not an optional visual specialist. Use its composition/reuse reference when the diff changes component APIs, hooks, state/effects, or removes duplication, and its React 19 reference for framework/API changes. It routes additional React specialists without allowing their generic advice to override Inertia/FSD rules.

At the start of a quality pass, inspect the available-skill catalog for these specialists:

- `$ask-sonner` — Sonner setup, lifecycle, styling, stacking, themes, and toast troubleshooting;
- `$mobile-native` — real mobile-browser, touch, viewport, safe-area, keyboard, scrolling, and capability-query defects;
- `$emil-design-eng` — broad interaction craft and final visual polish;
- `$find-animation-opportunities` — read-only discovery of a small number of justified motion opportunities;
- `$review-animations` — strict review of motion already present in the implementation.

If a specialist required by the current task is absent, name the missing skill and recommend installing it through `$skill-installer`. Do not install it without an explicit user request. Continue with the project design baseline only when it can still produce an honest result, and state which specialist pass remains unperformed.

`$review-animations` is explicit-only. Never silently claim to have applied it. Run it only when the user names it or explicitly asks for an animation review; otherwise recommend it when a material motion diff needs that review.

## Activation matrix

Activate only the specialists whose trigger is present. Do not load the full set for an ordinary form or one-line CSS fix.

| Specialist | Activate when | Skip when | Required boundary |
| --- | --- | --- | --- |
| `$ask-sonner` | The task touches `notify`, `AppToaster`, queued/promise feedback, toast styling, duplicate/missing notifications, modal stacking, theme, position, swipe, or persistence | No toast behavior or appearance changes | Keep `@shared/AppToast` as the project API and one root toaster; do not introduce page-local Sonner wiring |
| `$mobile-native` | A compact/touch route, modal/sheet, software keyboard, viewport height, safe area, scrolling, sticky hover, tap feedback, long press, or real-device defect is in scope | The changed surface is demonstrably desktop-only and has no touch behavior | Prefer capability queries and CSS/platform primitives; identify what still requires physical-device verification |
| `$emil-design-eng` | A material screen/component is being polished, interaction feedback or visual cohesion is part of acceptance, or the user asks for a UI review | Pure transport/type/refactor work or a trivial copy correction | Preserve the product's established visual character; in review mode use a `Before | After | Why` table |
| `$find-animation-opportunities` | The user asks what should animate, asks to make a surface feel more alive, or requests a deliberate motion-discovery pass | Motion is not an objective, or existing motion merely needs correction | This phase is read-only: gate by frequency, purpose, speed, and function; report both accepted and rejected candidates and stop before implementation |
| `$review-animations` | Existing/new motion needs a dedicated quality decision and the user explicitly requested that review | There is no motion diff, or only general UI review is requested | Follow its required findings table and Block/Approve verdict; use its own standards reference for exact values |

## The loop

### 1. Establish the functional baseline

- Read the route entry, rendered components, CSS Modules, nearby domain analogs, and relevant Shared public APIs.
- State the user path being protected: entry, primary action, pending state, success/failure, recovery, and exit.
- Reproduce or identify concrete evidence before changing code. Screenshots, browser behavior, failing tests, network responses, and source inspection are evidence; taste alone is not.
- Classify findings in this order: broken behavior, inaccessible/unrecoverable state, confusing hierarchy, responsive/touch defect, visual polish, motion opportunity.

Fix higher classes before lower ones. A prettier broken flow is still broken.

### 2. Implement the smallest project-aligned change

- Follow `$frontend-fsd-design` for ownership, public APIs, Shared reuse, CSS Modules, theme tokens, and screen composition.
- Follow `$react-code-quality` for component APIs, hooks, state/effects, derived data, server-state ownership, and reuse boundaries. Confirm that a refactor removes duplication rather than replacing it with a parameter-heavy abstraction.
- Prefer repairing a genuinely generic Shared behavior over repeating local patches, but verify its current consumers before changing its contract.
- Account for loading, empty, error, pending, success, retry/recovery, disabled, focus-visible, long-content, and both-theme states that the changed interaction can reach.
- Keep one clear primary action per group and keep feedback next to the action or data it describes.

### 3. Route focused specialist passes

Evaluate the activation matrix against the actual diff and reported defect. Announce which specialist is being activated and why.

Use this default order when several apply:

1. `$ask-sonner` for notification lifecycle and feedback correctness;
2. `$mobile-native` for platform and touch correctness;
3. `$emil-design-eng` for interaction and visual cohesion;
4. `$find-animation-opportunities` only for a requested read-only discovery pass;
5. `$review-animations` last, and only under its explicit-invocation rule.

This order prevents visual polish from masking broken feedback or mobile behavior. It is not a requirement to activate every step.

### 4. Verify behavior, not only source shape

Run checks proportional to the changed layer:

```bash
cd assets/inertia
npm run typecheck
npm run lint -- <changed paths>
```

For changed user behavior, update or run the closest targeted browser e2e through `make e2e-admin`. Also inspect the actual route through Cake/nginx rather than opening Vite directly.

Check the affected states at the relevant project sizes and in both themes. Check keyboard focus/order for interactive changes. When `$mobile-native` applies, distinguish code/emulation checks from behavior that still needs a real phone or tablet; do not report physical touch, browser chrome, safe areas, or software-keyboard behavior as verified from desktop emulation.

When motion is in scope, verify reduced motion, hover capability gating, interruption, and rapid repeated activation. Do not add motion merely to make the verification phase produce work.

### 5. Close or repeat on evidence

Repeat the implementation and focused verification only when a concrete defect, failed check, or specialist finding remains. Stop when the accepted user flow works, the applicable checks pass, and no in-scope high-impact finding is open. Do not continue inventing aesthetic changes after the acceptance criteria are met.

If `$find-animation-opportunities` was activated, its report is the stopping point for that read-only pass. Motion implementation requires a separate authorized implementation pass. If `$review-animations` blocks, fix only the motion findings in scope and rerun that review before declaring completion.

## Completion report

Keep the handoff concise and include:

- the behavior and presentation that changed;
- the React composition/state/reuse decision when `$react-code-quality` applied;
- which specialist passes ran and the trigger for each;
- checks run and their results;
- any physical-device verification still required;
- any missing specialist that was recommended for installation;
- any explicit-only animation review that remains recommended.

Do not claim that every specialist ran when the routing matrix skipped it. A skipped irrelevant pass is a correct result.
