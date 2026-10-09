---
name: project-template-maintenance
description: Maintain this reusable project-template catalog, including template profiles, copied project skills, installers, documentation, and validation without leaking project-specific runtime state into shared assets.
metadata:
  short-description: Maintain reusable project templates
---

# Project Template Maintenance

Use this skill when adding or updating reusable assets in this repository.

## Catalog boundaries

- Keep the root PHP package scaffold operational.
- Put immediately reusable, project-neutral assets under `skills/shared` or a
  clearly named shared template directory.
- Put exact or nearly exact source-project material under
  `templates/skills/<profile>` or another named profile. Preserve its local
  assumptions there instead of pretending they are universal.
- When a project-specific pattern proves reusable, create a separate sanitized
  asset. Replace service names, registry hosts, IP addresses, credentials,
  domain tables, and private paths with explicit configuration or examples.

## Workflow

1. Inspect the source file and its callers, nearby docs, ignore rules, and
   verification commands.
2. Decide whether the asset is a source snapshot, a reusable template, or both.
3. Preserve provenance in the catalog documentation.
4. Keep public Make targets small and stable; move substantial behavior into
   scripts.
5. Update the root README and catalog README when discoverability changes.
6. Run `make templates-check`, then the root checks affected by the change.

Do not copy runtime data, generated images, release payloads, real env files,
secrets, logs, database dumps, or internal infrastructure coordinates.
