 # MVP Specification — Products Dataset

## Goal
Build a reusable product catalog starting with products sold in Palestine, with a country-neutral schema for future international expansion. A product record describes identity and classification; it is not store inventory, price, sales, or purchasing data.

## Users
- Contributor: creates and edits records.
- Reviewer: checks quality, duplicate candidates, and imports.
- Integrating apps: consume normalized product records through a stable repository/API boundary.

## MVP scope
1. Browse products and search Arabic/Latin names or exact barcode.
2. Filter by hierarchical category, brand, country of origin, and status.
3. Create, edit, view, and archive products; avoid destructive deletion.
4. Manage categories and brands; keep brand distinct from manufacturer.
5. Import CSV/JSON through preview and validation; report row-level errors and duplicates.
6. Export normalized CSV/JSON with schema version.
7. Work offline with local persistence; keep sync metadata and repository boundaries ready for a later cloud phase.

## Data rules
- Arabic name is required for approved records in the initial catalog; other language fields are optional.
- Barcode is optional and stored as text to preserve leading zeros.
- Images, brand, manufacturer, origin, and net content may be unknown; never fabricate them.
- Product names are not unique identifiers. Never auto-merge on fuzzy name match.
- Keep provenance/source fields where available.
- Country of origin and market availability are different concepts.

## Out of scope
Store-specific prices and stock, POS, orders, accounting, automatic web scraping, public unauthenticated writes, and claims that the dataset is exhaustive.

## Acceptance criteria
- Create, edit, archive, search, and filter products while offline.
- Duplicate barcode conflicts are clearly surfaced; barcode-less products remain allowed.
- Category hierarchy rejects missing parents and cycles.
- Import preview reports row, field, and validation reason; no silent overwrite.
- Import/export round-trip preserves IDs, units, category references, and schema version.
- Arabic RTL works with Arabic, Hebrew, Latin text, and barcode values.
- Automated domain/repository/widget tests exist.
- Android, Windows, and Web are only marked supported after each target's build/smoke test and local persistence adapter are verified.

## Phases
1. Foundation, architecture, domain rules, CI.
2. Offline catalog, product editor, categories, brands.
3. CSV/JSON import preview and export.
4. Define authentication, sync versioning, and conflict policy.
5. Implement cloud synchronization after local contracts are tested.
