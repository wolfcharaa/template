# Application Design Rules

Read this reference before changing visual composition, hierarchy, forms, cards, registries, modals, feedback, responsive behavior, touch behavior, or motion under `assets/inertia`. Pure type/API/refactoring work that does not alter rendered behavior does not need it.

This is the project design baseline. It distills the useful parts of the installed design skills into the project's existing administrative interface. Do not replace the current visual language with a generic Apple clone, a new component library, or decorative motion.

## Intended experience

The application should feel:

- calm and predictable during long operational workflows;
- dense enough for professional data work without becoming visually noisy;
- explicit about current object, status, available action, progress, and failure;
- consistent between light and dark themes;
- responsive to pointer, keyboard, and touch without pretending every device is mobile;
- polished through alignment, typography, feedback, and stable layout rather than decoration.

Use four questions to judge every screen:

1. Where am I? Breadcrumb, page title, current card identity, or registry title answers this.
2. What am I looking at? Grouping and labels distinguish object data, relations, history, and actions.
3. What can I do next? Primary and secondary actions are specific and placed near what they affect.
4. How do I leave or recover? Back/cancel, close, retry, undo/confirmation, and preserved state prevent traps.

## Choose an established screen composition

Do not invent a new shell when an existing one matches the information architecture.

### Object/card workflow

Use `@shared/ui/card-sidebar-shell` for a record with stable identity and several meaningful sections. Reference implementations:

- `Pages/Territory/PassportObject/View.tsx`;
- `Pages/Territory/Premise/View.tsx`;
- `Pages/WorkCalendar/EventCard.tsx`;
- `Pages/GunLicense/views/GunLicenseCardShell.tsx`.

Use its parts deliberately:

- `identity` is the persistent read-only answer to “which record is this?”;
- `summary` contains only high-signal state such as status, owner, deadline, or count;
- `sections` navigate coherent information groups, not individual commands;
- `CardSectionHeader` names the current group and may host actions that affect only that group;
- `CardFieldGrid` renders read-only facts as facts, not disabled inputs;
- `footer` contains card-level navigation and mutations.

Do not turn the sidebar into a long list of tiny actions. If an item changes the active body content, it is a section. If it performs an operation, place it in the relevant section header, page header, or footer. Keep related object navigation explicit: “Карточка объекта”, “Карточка лицензии”, not an unlabeled icon or hidden click target.

### Registry/workspace

Use `ComposableTable` with `TableRegistryAdapter` and the `workspaceV2` composition for new or materially reworked registries. The screen should read in this order:

1. title/breadcrumb and registry context;
2. search and promoted filters;
3. domain actions;
4. table/card results;
5. pagination and result count.

Keep selection in the actions-column header. Show checkboxes only while selection is active or rows are selected. Do not add a second unrelated toolbar merely to host “Выбор”.

### Focused form

For create/edit flows with several semantic groups, use a page/card shell and sections. Use a modal only when the task is short, contextual, and the user benefits from retaining the background screen. A modal is not a replacement for a large multi-step screen.

### Responsive route

Use `ResponsiveInertiaPage` when desktop and compact layouts require different structure. Use `WorkspaceScreenSwitch` when one logical workspace has several URL-addressable screens. Keep the business state above the device-specific view when both variants perform the same scenario.

## Visual hierarchy and grouping

Prefer one obvious hierarchy over many equally loud panels.

- Page title identifies the workflow; section title identifies the current task; field label identifies a value.
- Use proximity and shared surface to communicate relationship. Do not add a border around every pair of elements.
- Put the most common path first. Put advanced or uncommon actions one level deeper.
- Keep a control near the content it changes. A section-specific button belongs in `CardSectionHeader`, not in a distant global toolbar.
- Use whitespace from `--spacing-*`; avoid arbitrary gaps. Start with `--spacing-2`, `--spacing-3`, `--spacing-4`, and increase only when hierarchy needs it.
- In flex/grid scroll layouts set `min-width: 0` and `min-height: 0` on shrinking/scrolling children. This prevents overflow that appears only with long Russian labels or small viewports.
- Prefer stable layout while loading. Do not let button labels, errors, or async results move the primary controls unpredictably.

For labels and copy:

- use direct domain language: “Создать карточку ФЛ”, “Связать с лицензией”, “Открыть объект”;
- label actions by their result, not “ОК”, “Далее”, or “Действие” when a precise phrase fits;
- keep section subtitles short and useful; do not restate the title;
- use `—` or an established `valueOrDash` helper for absent read-only data;
- state empty results specifically: “Связанные организации не указаны”, not “Нет данных”.

## Surfaces, color, and depth

The application already has a restrained translucent shell and solid content surfaces.

- `AppLayout` and `Bubble` provide the top-level translucent frame. Do not wrap every nested block in another glass layer.
- `CardSidebarShell`, `CardPanel`, Shared cards, modal surfaces, and table shells provide the next level of hierarchy.
- Use shadow, border, background, and blur together only through an established Shared surface. Local feature CSS should not invent a competing material.
- A modal uses a dimming overlay because it temporarily blocks the underlying task. A non-blocking side panel should remain spatially separate without dimming the whole application.

Use semantic theme variables first:

```css
color: var(--primary-contrastText);
color: var(--primary-muted);
background: var(--input-control-background);
border-color: var(--input-control-border);
outline-color: var(--focus);
```

Use base RGB tokens such as `rgb(var(--color-red))` or `rgb(var(--color-green))` when the meaning is already established and no semantic variable fits. Do not hard-code a light-only background or text color. Every new visual rule must be checked under both `[data-theme="light"]` and `[data-theme="dark"]`.

Color communicates meaning but never carries it alone. Pair warning/error/success color with text, icon, or status label. Keep the blue gradient for primary commands; do not use it for passive panels that would then look clickable.

## Typography

Use `@shared/typography` rather than reimplementing the type scale:

| Variant | Use |
| --- | --- |
| `h6` | Page or major card heading when the shell does not already render one |
| `subtitle1` | Strong section/field-group heading |
| `subtitle2` | Compact labels and small emphasized metadata |
| `body1` | Main readable content and ordinary form text |
| `body2` | Dense supporting content in cards/tables |
| `caption` | Secondary metadata, hints, timestamps |
| `code` | Identifiers or machine-oriented values where monospace aids reading |

- Preserve semantic heading order even when the visual variant differs.
- Use weight and spacing before inventing a new font size.
- Use `color="muted"` for context, not for required data or actionable text.
- Use `noWrap` only when the full value remains available by another accessible mechanism; critical names and errors should wrap.
- Keep body line-height readable. Dense registries may be compact, but descriptive text must not inherit table density.
- Use `rem` and project tokens so the layout follows the adaptive root size.

## Actions and buttons

Reuse `TextButton`, `TextButtonLink`, `IconButton`, `NavbarButton`, and `ButtonLayout` from `@shared/buttons`.

Action hierarchy:

- default `TextButton`: the primary commit in a local group (`Создать`, `Сохранить`, `Связать`);
- `ghost`: secondary navigation or a lower-emphasis alternative;
- `compact`: dense card footer, registry toolbar, or inline record operation;
- `warning`: destructive or dangerous action only.

Keep one visually primary action per action group. A row of identical blue buttons makes priority unreadable. Separate destructive actions from the default commit and confirm irreversible mutations with the Shared dialog/action-modal contract.

Some existing pages use `warning` for “Отмена”. Treat that as legacy inconsistency, not a template: cancellation is secondary, while warning styling communicates danger.

Use the existing `touchEffect` and `howerEffect` API when the chosen Shared button expects it; the misspelled `howerEffect` is an existing compatibility name, not a naming pattern for new APIs. Do not recreate local hover/press transforms around a Shared button.

Icon-only controls require an accessible name and a familiar icon. If the action is domain-specific or destructive, prefer icon plus text. Disabled controls must explain why through adjacent context or `title`/hint when the reason is not obvious.

## Forms

Use `FieldLayout` with Shared inputs. For new forms prefer an explicit top label so the result does not depend on backward-compatible defaults:

```tsx
<FieldLayout
  label={{value: 'Номер лицензии', position: 'top'}}
  requiredMark
  errorMessage={errors.number}
>
  <TextInput value={values.number} isError={Boolean(errors.number)} />
</FieldLayout>
```

- Order fields by the operator's task, not by database column order.
- On wide screens use at most two ordinary input columns unless the data is naturally tabular. Long names, addresses, descriptions, and errors span the full width.
- On compact screens reduce to one column without changing the logical tab order.
- Required state appears at the label before submission. Validation appears beside the affected field; a toast may summarize failure but never replaces inline errors.
- Preserve entered values after a failed request.
- Use the correct input semantics (`type`, `inputMode`, autocomplete attributes) instead of parsing everything from a generic text field.
- Do not reduce control text below `1rem` on touch layouts; the current Shared inputs already use this baseline.
- Read-only information uses `CardFieldGrid`, typography, or a purpose-built display component, not a disabled form.

For mutations, disable duplicate submission, show an in-place pending label (`Сохранение...`), and keep close/cancel behavior explicit. If a queued operation can continue in the background, acknowledge acceptance with a toast, close only after the request was accepted, then surface eventual success or failure from job polling.

## Modals, dialogs, and toasts

Use `ActionModal` for a titled task with description and action footer. Use low-level `Modal` only when the feature needs a custom body contract. It already provides portal placement, modal stacking, outside click, Escape handling, and a floating host for selects.

- Keep the modal focused on one task.
- Use `preventClose` while a non-repeatable commit is in flight.
- Constrain tall content with `100dvh` and one intentional inner scroll area; do not allow the page behind the modal to scroll.
- Put cancel/secondary action before the primary commit in the footer.
- Center modal motion; trigger-origin motion belongs to popovers, not dialogs.

Use `notify` for transient acknowledgement, completion, warning, and failure. The message names the object and outcome: “Карточка ФЛ создана”, not “Успешно”. Do not show a success toast before the operation actually succeeds; queued work gets a separate accepted message and final result.

Toast, inline state, and modal error are not interchangeable:

- field error: user can fix one value;
- inline section/page error: content failed to load or an operation affects the current workspace;
- toast: transient cross-screen acknowledgement;
- confirmation dialog: user must consciously approve a destructive, hard-to-reverse action.

## Loading, empty, error, and completion states

Every async surface must account for:

- initial loading;
- empty result;
- recoverable error with retry or next step;
- pending mutation and duplicate-submit prevention;
- successful completion;
- stale/background refresh when applicable.

Use `Preloader` for short blocking loads. Keep existing content visible during a background refresh when it is still valid. Error text must say what failed and preserve enough context to act; do not dump raw SQL/stack traces into user-facing copy.

When an action changes navigation or relations, make the next state obvious: select the newly created option, refresh the affected query, navigate to the new card, or show an explicit link. Do not leave the operator guessing whether data changed.

## Responsive and touch behavior

The project provider writes `data-size="sm|md|lg"` and `data-touch` on `<html>`. Project breakpoints are supplied from `Shared/config/viewport.ts` (`md: 1334`, `lg: 1700`); do not assume common framework breakpoints.

- Use `ResponsiveInertiaPage` or `useViewport` for structural changes.
- Use CSS media/container constraints for intrinsic wrapping and available height.
- Use `(hover: hover) and (pointer: fine)` for hover-only effects. Touch and mouse can coexist; do not infer capability from viewport width or user-agent strings.
- Shared controls already provide larger `--control-min-height` and radius for `sm/md`. Do not shrink touch targets locally to match desktop density.
- Use `100svh` for the stable application shell and `100dvh` for modal/sheet constraints that must follow visible browser chrome.
- Use `overscroll-behavior: contain` on intentional inner scrollers. Do not block scrolling with global `touchmove` handlers.
- Apply `user-select: none` only to controls/drag handles, never to readable content.
- Use `touch-action: manipulation` for custom pressable controls and axis-specific values only on real gesture surfaces.
- Never disable browser zoom. Root viewport/safe-area changes belong in the Cake layout and require checking both `SPA.ctp` and `default.ctp`; do not patch them from a page component.

Device emulation verifies layout, not physical touch feel, keyboard behavior, safe areas, sticky hover, or overscroll. If a task specifically targets phones/tablets, state which behavior still needs a real device check.

## Motion

Motion should feel fast, restrained, and operational. Its valid purposes are press feedback, spatial continuity, state change, and avoiding jarring appearance. Do not add motion only to make a dense administrative screen “more lively”.

Use the existing rhythm as the default:

| Interaction | Existing project timing |
| --- | --- |
| Button press/route content | `140–160ms` |
| Floating surface | about `180ms` |
| Modal overlay/content | `220–240ms` |

Use `var(--ease-out-strong, cubic-bezier(0.23, 1, 0.32, 1))` for entrances and direct response where the owning Shared component does not already provide motion.

Rules:

- Animate only when the purpose is clear; repeated table scanning, keyboard actions, and ordinary pagination should feel immediate.
- Prefer `transform` and `opacity`; avoid animating layout dimensions in large data surfaces.
- Specify properties; never use `transition: all`.
- Do not use `ease-in` for an interactive entrance because it delays visible response.
- Entrances start near the final state (`scale(0.95–0.98)` plus opacity), never at `scale(0)`.
- Popovers originate from their trigger; modals remain centered.
- Rapidly retargeted UI uses transitions or an interruptible mechanism, not a keyframe that restarts.
- Add no spring/motion dependency for ordinary screen polish. Springs are justified only for a real drag/swipe interaction that must preserve velocity and interruption.
- Respect `prefers-reduced-motion`: replace movement with a short opacity/color transition and remove bounce/parallax.
- Hover motion is gated by hover/pointer capability and every pressable control still has immediate active feedback.

If motion or gesture physics is the main task, use the specialized installed motion skill in addition to this baseline. Ordinary form/card/registry work should not load a motion framework.

## Accessibility and resilience

- Use semantic headings, lists, tables, buttons, and links before adding ARIA.
- Every field has an associated label; every icon-only button has an accessible name.
- Preserve visible `:focus-visible` styling and keyboard order.
- Do not encode status by color alone.
- Keep destructive confirmation specific about the object and consequence.
- Ensure text and controls remain usable at larger root font sizes and with long Russian content.
- Avoid focus traps outside the Shared modal stack.
- Keep content selectable, especially identifiers, addresses, errors, and document numbers.
- Check contrast in both themes and in disabled/pending states.
- A failed network request must not erase user input or strand the screen behind an unclosable overlay.

## Review format and checklist

For a requested design/UI review, report findings as a table:

| Before | After | Why |
| --- | --- | --- |
| Current concrete behavior/code | Proposed project-aligned behavior/code | User or system consequence |

Prioritize functional hierarchy and accessibility before cosmetic polish. Before finishing a visual change, verify:

- the screen uses the correct established composition;
- identity, summary, sections, and actions have distinct roles;
- there is one clear primary action per group;
- all async states are represented;
- labels and errors remain readable with long content;
- light/dark themes use semantic variables;
- compact and desktop structures were checked;
- hover, active, focus-visible, disabled, and reduced-motion states work;
- no local CSS duplicates a Shared component's appearance;
- the implementation looks like the same application rather than a newly introduced design system.

## When another installed skill is actually needed

This reference covers ordinary application design. Add a specialized skill only for its narrow purpose:

| Task | Additional skill |
| --- | --- |
| Build a new non-trivial animation or transition | `animate` |
| Review one implementation's motion quality | `review-animations` |
| Audit motion across the application | `improve-animations` |
| Find places where motion may help without implementing it | `find-animation-opportunities` |
| Name an animation effect described in informal language | `animation-vocabulary` |
| Implement gesture physics, spring interruption, momentum, or a sheet | `apple-design` |
| Diagnose a real mobile browser/touch/platform defect | `mobile-native` |
| Diagnose or redesign Sonner toast behavior | `ask-sonner` |
| Produce several selectable UI alternatives | `prototype` (only when explicitly invoked) |
| Select a new third-party UI library | `pick-ui-library` (only when explicitly invoked) |
| Conduct a broad interaction-polish review | `emil-design-eng` |

Do not invoke all of them for an ordinary form or card change. Their generally applicable rules are already incorporated above.

`imagegen` is for bitmap assets, not for designing repository-native screens or replacing CSS/React composition. `sites` targets Sites-managed websites and does not apply to repository-native implementation.
