---
name: docker-deployment
description: Build or adapt reusable Docker development, stage, production, Makefile, and offline-release workflows from this repository's templates. Use for Compose wrappers, Docker project bootstrapping, release packaging, deployment switching, or rollback; do not use for ordinary application-only changes.
metadata:
  short-description: Reusable Docker deployment workflow
---

# Docker Deployment

Use the global `deploy` skill for release and offline-transport work. This skill
adds the local template map and adoption rules.

## Pick the smallest template

- For Spiral/RoadRunner PHP projects, start with
  `templates/docker/spiral` and its `Makefile.fragment`.
- For CakePHP or another multi-service PHP application, start with
  `templates/make/cakephp-application.Makefile` and reuse only the Compose
  wrappers needed from `templates/docker/spiral/compose`.
- Source-project Codex skills live under `templates/skills`; install a profile
  only when the new project shares its stack and boundaries.

Copy assets into a new branch or clean worktree, then adapt before running them.
Do not overlay a non-empty `docker/` directory without reviewing every
collision.

## Required adaptations

Resolve these values explicitly:

- Compose project name, service names, profiles, ports, and paths;
- application env file versus optional Compose/operator env file;
- image registry prefix, exact production image names, and platform;
- persistent data boundaries and services that deployment may recreate;
- application commands, migrations, health checks, and smoke checks;
- release branch/tag policy and supported connected or offline delivery modes.

Keep direct `docker compose -f ...` commands usable. Make is a stable operator
interface, not the only source of truth.

## Safety invariants

- Development wrappers must reject root/sudo when host UID/GID ownership is
  expected.
- `down` should stop by default; destructive volume removal requires a separate
  explicit operation. Reject `-v` and `--volumes` in shared wrappers.
- Ordinary `up` and release switching use `--no-build`; image build and pull
  are explicit actions.
- Keep secrets and endpoints in an untracked application env file. Do not use
  `.env` as the production release-version selector.
- Production Compose uses exact image references. Recreate only the intended
  application scope and preserve databases, indexes, volumes, and unrelated
  services.
- Keep Docker archives, manifests, Git bundles, dumps, and release transport
  archives out of Git.

## Release contract

For offline delivery, keep source identity, runtime payload, and transport
package separate. A release normally has an annotated tag/Git bundle, exact
Docker images plus a checksummed manifest, and one flat transport archive with
`RELEASE.md` and `DEPLOY.md`.

`change-release` should use exact local images immediately. Only when an image
is absent should it validate and load the local archive. It must deploy with
`--no-build` and without an implicit pull.

## Verification

Run, as applicable:

```shell
make templates-check
sh -n docker/compose/dev.sh docker/compose/run.sh
docker compose -f docker/compose/dev/compose.yaml config
docker compose -f docker/compose/prod/compose.yaml config
make doctor
```

For release changes also validate image platforms, manifest checksums, Git
bundle refs, exact tar members, and a non-production smoke deployment. Report
which artifacts were actually built; syntax checks do not prove a release
archive works.
