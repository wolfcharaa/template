# Git Conventions For mvdcake

## History And Authority

`main` and `stage` are shared history and must not be rewritten: no force-push, unsanctioned squash, or hidden loss of commits. A personal branch may be rewritten while it does not affect shared history.

In an approved feature branch, make an atomic intermediate commit after each completed and verified task. Push, merge, rebase, and MR creation happen only when requested. Before committing, inspect branch/status, full diff, and staged diff.

## Branches

Format: `<type>/<name>`.

Allowed types: `feature`, `bugfix`, `refactor`, `docs`, `test`; any other type requires team agreement.

`name` describes the area and goal with lowercase latin words and single hyphens only. Do not use `_`, camelCase, uppercase, double hyphens, or tracker IDs.

Examples: `feature/api-regular-search`, `bugfix/change-const-import-fias`.

Merge direction follows the branch origin:

```text
main → stage → feature → stage → main
```

Before feature → stage, sync stage back into feature through MR. Main hotfixes are tech-lead exceptions; then propagate main → stage and stage → active branches.

## Commit Message

```text
TYPE(scope): Результат изменения на русском

Kaiten: #0000001
```

- Use Conventional Commits; type is preferably uppercase: `FEAT`, `FIX`, `REFACTOR`, `DOCS`, `TEST`, `CHORE`.
- Scope is a short area such as `parser`, `registry`, or `message-bus`, not the task number.
- Description is Russian, short, concrete, and impersonal.
- Use result form: `Добавлен`, `Исправлена`, `Обновлено`, `Интегрирован`; not `Добавил` or `Добавилось`.
- One commit has exactly one reason. A long subject is a signal to re-check atomicity.
- Add `Kaiten` footer only when the number is known; do not invent it.

Examples:

```text
FEAT(message-bus): Добавлена асинхронная обработка отчёта

Kaiten: #1234567
```

```text
FIX(registry): Исправлена сериализация множественного фильтра
```

## Before Commit

1. Check branch and status.
2. Read the diff for one reason of change.
3. Exclude unrelated/user changes.
4. Run relevant checks.
5. Stage only intended paths.
6. Check `git diff --cached`.

Do not put an adjacent problem into the same commit merely because it is nearby. Split it into another reason, diff, check set, and commit.

## Release Artifacts

Do not commit release artifacts: archives and manifests from `docker/data/release/**` and portable `release-*.bundle` files remain local artifacts of a release tag.

A release commit fixes source/config/version state only. If a release artifact becomes staged or tracked, remove it from the index before commit/tag.

## MR

MR title reflects all included commits, not only the last subject. Description includes context, unusual decisions, and Kaiten when known. Reviewer is selected by area. Discussion stays in the MR. New commits require repeat review. Merge only after review/approve, resolved comments, and no commits after approval.

Reviewers do not edit the author's branch without an explicit recorded request.

Architecture review checks mutation pipeline, database/normal forms, SQL injection, N+1/performance, resilience, and invalid boundaries.
