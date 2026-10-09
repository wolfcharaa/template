---
name: project-template-maintenance
description: Maintain this reusable project template, including framework assets, local Codex skills, documentation, and validation without leaking runtime state or private infrastructure into reusable files.
metadata:
  short-description: Maintain reusable project templates
---

# Project Template Maintenance

Use this skill when adding or updating reusable assets in this repository.

## Catalog boundaries

- Keep the root PHP package scaffold operational.
- Keep discoverable Codex skills directly under `.agents/skills/<skill-name>`.
- Name framework-specific material by technology or purpose, such as `cake`,
  `spiral`, `docker`, or `frontend`, rather than by a source repository.
- When a project-specific pattern proves reusable, create a separate sanitized
  asset. Replace service names, registry hosts, IP addresses, credentials,
  domain tables, and private paths with explicit configuration or examples.

## Workflow

1. Inspect the source file and its callers, nearby docs, ignore rules, and
   verification commands.
2. Decide whether the asset belongs in the active project shape or under an
   opt-in framework template.
3. Remove source-project names and private infrastructure assumptions.
4. Keep public Make targets small and stable; move substantial behavior into
   scripts.
5. Update the root README and catalog README when discoverability changes.
6. Run `make templates-check`, then the root checks affected by the change.

Do not copy runtime data, generated images, release payloads, real env files,
secrets, logs, database dumps, or internal infrastructure coordinates.
