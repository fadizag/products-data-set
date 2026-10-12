# Products Dataset

A Flutter application for building a structured, reusable product dataset, starting with Palestinian products and designed to expand internationally.

## Approved MVP decisions

- **Platforms:** Android, Windows, and Web.
- **Data scope:** Palestinian products first; schema remains country-neutral for future global expansion.
- **Storage:** Local-first, with cloud synchronization added behind repository interfaces.
- **Language and UX:** Arabic-first, right-to-left (RTL), with resilient support for Arabic/Latin product names and barcodes.
- **State management:** BLoC.
- **Local persistence:** ObjectBox where supported; a platform-compatible web local store must sit behind the same repository contract. Do not claim web support until the selected adapter is validated in CI.

## Repository status

This repository is being bootstrapped. The specification and initial structure are being added before feature implementation. Build and test results must be recorded only after actually running them.

## Planned MVP

1. Browse and search products by name and barcode.
2. Filter products by hierarchical category and brand.
3. Create, edit, archive, and inspect product records.
4. Validate imports from CSV/JSON and export clean data.
5. Detect likely duplicates without relying on product name alone.
6. Work offline; prepare a versioned synchronization boundary for a later cloud phase.
7. Include unit, repository, widget, and platform smoke tests.

## Documentation

- [`docs/MVP_SPEC.md`](docs/MVP_SPEC.md) — product scope and requirements.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — proposed Flutter architecture and folder layout.
- [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) — entities and data rules.
- [`docs/TEST_PLAN.md`](docs/TEST_PLAN.md) — verification strategy.

## Development status

No claim of successful Flutter builds, generated database code, cloud connectivity, or deployment is made until those steps are executed and verified.