# Test Plan — Products Dataset

## Static checks
- dart format --set-exit-if-changed .
- flutter analyze
- flutter test
- Generate and validate database model code when persistence is added.

## Unit tests
- Required and optional product fields.
- Barcode normalization preserves leading zeros and validates known symbologies appropriately.
- Net content must be positive when present.
- Category validation rejects missing parents and hierarchy cycles.
- Arabic normalization/search handles whitespace and diacritics without mutating original labels.
- Duplicate detection prioritizes exact barcode and never auto-merges fuzzy matches.
- Import parser reports row, field, and reason for invalid data.

## Repository contract tests
Run against every local adapter: create/read/update/archive; Arabic/Latin search; exact barcode lookup; category/brand filters; persistence after restart; offline writes; deterministic duplicate conflicts; import batch validation; import/export round-trip preserving IDs, units, category references, and schema version.

## BLoC tests
Loading/success/empty/error states; search and filters; validation errors preserve form values; stale concurrent search results are ignored; archive confirmation flow.

## Widget tests
Arabic RTL layout; loading/empty/error/populated lists; search and filters; form validation; long Arabic/Latin names and barcode overflow; keyboard navigation and accessible labels on Windows/Web.

## Platform smoke tests
- Android: launch, local write/read, restart persistence.
- Windows: launch, local write/read, restart persistence.
- Web: launch, local write/read, refresh persistence.
- Verify each target's actual storage adapter.
- Cloud sync tests wait until remote backend and conflict policy exist.

## CI/release gates
Pin Flutter/Dart version; run formatting, analyzer, unit/widget tests on PRs; add Windows/Web builds and Android build on a configured Android runner. Do not call a target supported based only on analyzer/tests. Record actual command output; never report green checks without running them.
