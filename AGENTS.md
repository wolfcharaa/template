# Template Repository Guidance

Use the global `development` skill for normal code changes, checks, and commits.

For changes to the reusable catalog, read
`skills/shared/project-template-maintenance/SKILL.md`. For Docker, Compose,
Makefile, release, or offline-deployment templates, also read
`skills/shared/docker-deployment/SKILL.md`.

## Invariants

- Keep the root PHP package scaffold runnable; reusable application assets live
  under `templates/` and are opt-in.
- Treat `templates/skills/mvdcake` and
  `templates/skills/phpfiasgeocoder` as source-project profiles. Do not make
  them generic in place; add reusable guidance under `skills/shared` instead.
- Never add real `.env` files, credentials, private keys, runtime data, Docker
  archives, Git bundles, database dumps, or internal registry/server values.
- Keep Make targets as stable public entrypoints over readable scripts and
  Compose files.
- Run `make templates-check` after changing templates, installers, or skills.
