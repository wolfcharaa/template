# Project Guidance

Use the global `development` skill for ordinary code changes, checks, and
commits. Repository-local skills are stored under `.agents/skills` and refine
that workflow when their technology or task matches.

## Skill Routing

- `cake-development` — CakePHP backend, MessageBus, table-registry, modular
  architecture, and project Git conventions.
- `spiral-hexagonal` — Spiral services and pragmatic hexagonal boundaries.
- `frontend-fsd-design` — React/Inertia ownership, FSD boundaries, and UI
  composition.
- `react-code-quality` — React components, hooks, state, effects, and version
  changes.
- `frontend-quality-loop` — requested UI polish and hardening after material
  interaction changes.
- `docker-deployment` — Compose, Makefile, release, deployment, and rollback.
- `project-template-maintenance` — changes to this reusable template itself.

Remove skills that do not match the project after choosing its stack. Keep
project-specific commands and invariants in this file or a focused local skill.

## Invariants

- Keep the root PHP package scaffold runnable; opt-in framework assets live
  under `templates/`.
- Name reusable files by technology or purpose, not by a source repository.
- Never add real `.env` files, credentials, private keys, runtime data, Docker
  archives, Git bundles, database dumps, or internal registry/server values.
- Keep Make targets as stable public entrypoints over readable scripts and
  Compose files.
- Run `make templates-check` after changing templates or local skills.
