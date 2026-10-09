# Legacy Feature Architecture Reference

This reference preserves the old mvdcake feature-slice vocabulary. Use it only when touching existing `src/Feature/*` code, reading older decisions, or translating legacy placement into the current `src/Module/<Module>/{UserInterface,Capability,Infrastructure,Feature}` target from `docs/architecture.md`.

For new module work, prefer the target architecture in the main skill and `docs/architecture.md`.

## Legacy Unit Of Change

Older backend code is organized by vertical slices:

```text
src/Feature/<Domain>/<UseCase>/
├── Aggregation/
├── Orchestration/
├── Outbounding/
└── UserInterface/
```

`Domain` is a business area or bounded context such as `Auth`, `Fis`, `Nsi`, `Notification`, or `Settings`. `UseCase` is an operation and a reason to change, such as `SaveSettingValue` or `ImportNsiRows`.

Do not add a new operation to a generic service/controller when it is an independent use case. Create role directories only when the slice actually needs them.

## Legacy Roles

### Aggregation

Domain model without HTTP, CLI, or a concrete database: entities, value objects, enums, invariants, calculations, definitions, and catalogs. Declarative `TableRegistryDefinition` can live here in legacy slices. It must not contain controllers, SQL execution, transport responses, or external dependency orchestration.

### Orchestration

Application scenario: `<UseCase>Message`, `<UseCase>Action`, `<UseCase>Result`, domain sequencing, and calls to ports. An Action accepts a prepared Message, coordinates domain/outbound ports, and returns a Result. It does not parse HTTP requests and does not create Responses.

### Outbounding

Outgoing ports and adapters: storage/provider/client/notifier interfaces, DirectSql/ORM/API/filesystem implementations, read gateways. Name the interface in use-case language, not as an ORM mirror. The Action depends on the interface; the container injects the implementation.

Feature-specific DI belongs in a focused imported file such as `config/di/<feature>.yaml` or `config/di/<domain>.yaml`. Avoid growing shared service config with long local alias/autowire lists. If an explicit service definition overlaps a broad autowired resource, exclude the class from that resource so autoconfiguration does not override the explicit definition.

### UserInterface

Input adapters: HTTP controller/CLI command, route/query/body/files, transport validation, Message creation/dispatch, and Result/exception presentation. Do not place business branching, SQL, or domain rules here.

## CCP

- Keep code that changes for one business operation in one use case.
- Give each new use case its own folder.
- Move shared domain elements only when there is real reuse and joint change pressure.
- `src/Feature/Shared` is for stable project-wide primitives, not dumping ground code.
- Before adding a local primitive VO for string, number, boolean, float, UUID, DateTime, or JSON fields, check existing shared primitives.
- Similar code is not enough reason for `Shared`.
- If similar scenarios change for different reasons, keep them local instead of forcing an abstraction.

## Dependency Direction

```text
UserInterface → Orchestration → Aggregation
                          ↘ Outbounding interface → adapter
```

Transport calls the use case, but the use case does not know transport. Domain does not depend on UI or infrastructure. Cross-feature calls use public orchestration/shared contracts, not another use case's internal adapter.

## Placement Questions

Before creating a file, decide:

1. What business reason will make this code change?
2. Is it a model/rule, scenario, outbound port, or input transport?
3. Is it needed by one use case, several use cases in one domain, or the whole project?
4. Is there a real current consumer for a shared abstraction?

Legacy examples: `Settings/SaveSettingValue` as a command use case; `Home/ResolveAllowedHome/Outbounding` as a port/adapter; `Nsi` as a bounded context; `Fis/Registry/NextQueue` as a registry slice.
