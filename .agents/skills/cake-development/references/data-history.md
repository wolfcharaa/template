# Data History, Snapshots, And Audit

Use this reference when a change touches historical data, journals, status history, immutable document/workflow data, source snapshots, or read access to past state.

## First Decision

Before adding storage or UI, classify the data:

- **Current state**: the mutable source of truth used by business decisions now.
- **Append-only history**: facts about mutations, status changes, links/unlinks, imports, retries, or integration outcomes.
- **Immutable snapshot**: values copied at a business moment because future source changes must not rewrite what the user saw, submitted, published, or printed.
- **Read projection**: denormalized data for registry/card convenience that can be rebuilt or traced to explicit source facts.

Do not mix these roles in one generic table or JSON payload when they change for different reasons.

## Source Of Truth

- The owning workflow/relation stores the business fact. A root entity does not receive context-specific columns just because another module needs a shortcut.
- Relation history belongs to the relation workflow: create, update, archive/delete, restore, terminate, attach/detach, link/unlink, and status transitions are separate historical facts when they mean different things.
- A projection may denormalize small display values, but it must be traceable to a concrete root/relation/source record and version.
- Do not implement a generic polymorphic history/relation manager when different links have different meaning, payload, lifecycle, or access scope.

## Append-only History

History tables and event logs are append-only by default:

- no update/delete API for historical events;
- corrections are represented by a new event;
- store actor id/display snapshot, source (`User`, import, integration, system), operation, timestamp, and changed fields or typed event payload;
- write history in the same capability/transaction boundary as the mutation when consistency matters;
- keep technical retries/outcomes separate from business history unless the outcome is itself a business fact.

For imports/backfills, do not trigger normal business events, notifications, renderers, or history side effects unless the workflow explicitly requires it. Prefer technical outcome logs and idempotent no-op behavior for already-correct rows.

## Immutable Snapshots

Use a snapshot when a later change in a source entity must not rewrite past documents, workflow forms, decisions, publications, or printed output.

Good snapshot payloads include:

- source UUID/id and optional source version/status/version kind;
- display values needed by the historical view or document;
- actor/source/timestamp/correlation id;
- formatter/template version for generated documents;
- immutable media/file relation snapshot for published document revisions.

Do not auto-refresh form/document snapshots from current source data after the workflow starts. If source drift must be handled, make it explicit: block publication, continue with the old snapshot under a workflow policy, or record an accepted source-change event with actor/reason.

## Read Scope And Deep Links

Historical reads use the same or stricter ABAC/area/resource scope as the owning current record:

- a user who cannot read the current scoped record should not read its history by direct URL;
- impossible/out-of-scope conditions should return not found or an empty scoped result, not leaked partial history;
- registry rows, card history, exports, and document downloads must apply the same scope logic.

When history is assembled from multiple streams, keep storage sources typed and separate; merge only in a presenter/read service that preserves source, ordering, and permissions.

## Testing Expectations

For a history-related mutation or read:

- handler/capability test proves that the mutation writes the expected history/snapshot or intentionally does not;
- SQL/storage contract proves ordering, actor/source payload, changed fields, relation joins, and out-of-scope behavior;
- controller/e2e coverage proves that the card or registry exposes history links/actions only where the user can access them;
- for MessageBus changes, compile the registry.

Useful project search terms: `ChangeJournal`, `History`, `ChangeLog`, `statusHistory`, `snapshot`, `source_version`, `changedAt`, `actorDisplayName`.
