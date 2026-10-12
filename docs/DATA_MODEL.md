# Data Model — Products Dataset

## Product
- id: stable UUID string.
- nameAr: required for approved initial-catalog records.
- nameEn: optional.
- normalizedName: derived search/deduplication field; never replaces the displayed name.
- description: optional.
- brandId: optional Brand reference.
- manufacturerId: optional Manufacturer reference.
- primaryCategoryId: required for approved records; drafts may be uncategorized.
- barcode: optional string, not integer; preserve leading zeros.
- barcodeType: optional EAN-13, EAN-8, UPC-A, UPC-E, GTIN-14, QR, other, or unknown.
- netContentValue: optional positive decimal.
- netContentUnit: optional g, kg, ml, l, unit, or other.
- countryOfOrigin: optional ISO 3166-1 alpha-2 code.
- imageUrl: optional URI; track attribution/source when applicable.
- sourceName/sourceUrl: optional provenance.
- status: draft, review, approved, archived.
- createdAt/updatedAt: required UTC timestamps.
- schemaVersion: integer for import/export compatibility.

## Category
id, nameAr, optional nameEn, stable slug, nullable parentId, sortOrder, active/archived status. Reject self-parenting, missing parents, and cycles.

## Brand
id, name and optional localized names, country, website, and status. A brand is not necessarily the manufacturer.

## Manufacturer
id, name and optional localized names, country, website, and status.

## Barcode alias (recommended separate entity)
id, productId, value, symbology, isPrimary, source, createdAt. Enforce uniqueness for normalized barcode values where trusted; ambiguous cases go to review rather than automatic merge.

## Quality rules
- Product names are not globally unique.
- Store barcodes as text.
- Exact barcode match is the strongest duplicate signal; fuzzy name matching only suggests review.
- Keep market availability separate from country of origin.
- Prices and stock belong to separate offer/inventory models, never Product.
- Prefer archive/soft-delete so references and future sync tombstones remain valid.
