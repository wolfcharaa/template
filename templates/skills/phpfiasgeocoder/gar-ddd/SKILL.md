---
name: gar-ddd
description: Use for phpfiasgeocoder GAR service architecture, pragmatic hexagonal boundaries, and explicit service design without extra ceremony. Load the global hexagonal skill first, then follow docs/architecture.md as the project source of truth.
metadata:
  short-description: GAR hexagonal service pointer
---

# GAR Hexagonal Service Pointer

Use the global `hexagonal` skill for reusable pragmatic hexagonal architecture rules before acting.

For this repository, `docs/architecture.md` is the source of truth for the flat service structure, directory ownership, Feature placement, OpenSearch/Nominatim/Data.Mos/OSM boundaries, Spiral filter usage, capability errors, MessageBus flows, and verification rules.

Treat the whole repository as one GAR/FIAS geocoder service. Do not introduce or expand `app/src/Gar`, generic buckets, or supporting classes just to satisfy an architecture pattern.

Default target shape:

- `UserInterface` for HTTP controllers, CLI commands, filters, presenters, and transport middleware.
- `Capability` for explicit executable scenarios, MessageBus contracts, handlers, ports, results, typed read contracts, and expected scenario/port exceptions.
- `Infrastructure` for PostgreSQL/GAR/XML/files/cache/search adapters and technical runners.
- `Feature` only for optional or replaceable extensions such as OpenSearch, Nominatim, Data.Mos, OSM aliases, external enrichment, decorators, or feature-owned workflows.
- `Bootstrap` only for composition: DI bindings, decorators, replacements, feature activation, and options.

When making the service more explicit, prefer small vertical improvements:

- make scenario and port names describe their use-case contract;
- keep raw SQL/OpenSearch/HTTP arrays inside adapters;
- convert expected business failures to `ScenarioException`;
- convert expected outbound dependency failures to `PortException`;
- let `CapabilityExceptionMiddleware` shape HTTP errors;
- document or test the changed contract near the owning layer.

Do not duplicate project-specific architecture rules in `AGENTS.md`. The repository must not contain `app/AGENTS.md`.
