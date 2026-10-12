# Architecture — Products Dataset

## Principles
- Feature-first structure with domain/data/presentation boundaries.
- BLoC for state management.
- Repository interfaces separate app logic from persistence.
- Local-first writes; no network required for core catalog operations.
- Arabic-first RTL; names may include Arabic, Hebrew, or Latin characters.
- Product catalog remains separate from retailer-specific stock and prices.

## Proposed structure
- lib/main.dart — entry point
- lib/app/ — app shell, routing, theme
- lib/core/ — errors, validation, utilities, result types
- lib/features/products/domain/ — entities, repository contracts, use cases
- lib/features/products/data/ — DTOs, mappers, repositories, local/remote adapters
- lib/features/products/presentation/ — BLoC, pages, widgets
- lib/features/categories/ — category domain/data/presentation
- lib/features/brands/ — brand domain/data/presentation
- lib/features/import_export/ — parsing, validation, preview, export
- lib/bootstrap/ — dependency injection
- test/ — unit, repository, BLoC, widget tests
- integration_test/ — platform smoke tests
- docs/ — specifications and decisions

## Data flow
Widget -> BLoC -> use case -> repository interface -> local data source. UI must not call databases or remote APIs directly.

## Persistence
The prior product CRUD preference was BLoC plus ObjectBox. Use ObjectBox on Android/Windows only after confirming package support and generated code in CI. Web is also an approved target, so it needs a verified web-compatible local adapter (such as IndexedDB) behind the same repository contract. Do not claim ObjectBox web support without verification. Before implementing persistence, compare the split-adapter approach with a single cross-platform option such as Drift.

## Future synchronization
Records need stable UUIDs, createdAt, updatedAt, archive/deletion state, and schema version. Define server revisions, idempotent retries, and conflict handling before enabling multi-device writes. Do not silently apply last-write-wins to core identity fields.

## Quality gates
Format, analyze, unit test, repository contract test each adapter, widget test RTL/loading/empty/error states, and run Android/Windows/Web smoke checks on suitable CI runners.
