---
name: spiral-hexagonal
description: Develop and review Spiral PHP services with pragmatic hexagonal boundaries, explicit capabilities, ports, adapters, MessageBus flows, and optional integrations. Use for Spiral architecture and service-structure work; do not use for CakePHP-specific application changes.
metadata:
  short-description: Spiral hexagonal service workflow
---

# Spiral Hexagonal Service

Use the global `hexagonal` skill for reusable architecture rules. Treat the
repository's `docs/architecture.md` as the source of truth when it exists.

Treat a small repository as one service unless its business boundaries justify
separate modules. Do not introduce generic buckets or supporting classes only
to satisfy an architecture diagram.

Default target shape:

- `UserInterface` for HTTP controllers, CLI commands, filters, presenters, and
  transport middleware;
- `Capability` for executable scenarios, MessageBus contracts, handlers,
  ports, results, typed read contracts, and expected scenario/port errors;
- `Infrastructure` for PostgreSQL, files, cache, search, and external-service
  adapters;
- `Feature` for optional or replaceable integrations, decorators, and
  feature-owned workflows;
- `Bootstrap` only for DI bindings, replacements, feature activation, and
  configuration options.

Prefer small vertical improvements:

- make scenario and port names describe their use-case contract;
- keep raw SQL, search payloads, and HTTP arrays inside adapters;
- convert expected business failures to `ScenarioException`;
- convert expected outbound dependency failures to `PortException`;
- let project middleware shape transport errors;
- document or test the changed contract near its owning layer.

Keep project-specific services, datasets, endpoints, and verification commands
in repository documentation or a narrower skill instead of adding them here.
