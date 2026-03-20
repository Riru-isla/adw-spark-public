# Story 1: Database schema and models for collections and items

## What was built
Two core Active Record models (`Collection` and `Item`) with their database migrations. Active Storage is configured on `Item` for photo attachments, and a 5-tier condition enum is defined as an integer column. Associations and validations are in place on both models.

## Key files
- `backend/app/models/collection.rb` — `has_many :items, dependent: :destroy`; validates `name` presence
- `backend/app/models/item.rb` — `belongs_to :collection`, `has_many_attached :photos`, integer-backed condition enum (mint/near_mint/good/fair/poor), validates name/condition presence and estimated_value ≥ 0
- `backend/db/migrate/20260320143248_create_collections.rb` — creates `collections` table
- `backend/db/migrate/20260320143251_create_items.rb` — creates `items` table with FK to collections
- `backend/db/schema.rb` — current schema snapshot (version `2026_03_20_143251`)
- `backend/spec/factories/collections.rb` — FactoryBot factory; name is sequenced, category/description default nil
- `backend/spec/factories/items.rb` — FactoryBot factory; condition defaults to `:good`, associates a collection

## Database changes
- **collections**: `name:string NOT NULL`, `category:string`, `description:text`, timestamps
- **items**: `name:string NOT NULL`, `condition:integer NOT NULL`, `estimated_value:decimal(10,2)`, `acquisition_date:date`, `notes:text`, `collection_id:bigint NOT NULL` (FK + index), timestamps
- Active Storage system tables are assumed present from Rails scaffold (not added in these migrations)

## API endpoints
None — this story is data layer only.

## Patterns & conventions
- Condition enum stored as integer column, accessed via symbol keys (`:mint`, `:near_mint`, etc.)
- `estimated_value` is nullable — items with unknown value are allowed
- `dependent: :destroy` on `Collection#items` — deleting a collection cascades to its items
- Factories use `sequence` for names to avoid uniqueness collisions in tests; optional fields default to `nil`

## Dependencies
No new gems — Active Storage is part of Rails 8 and assumed enabled in the scaffold.

## Notes
- `condition` column is an integer (not a string enum); use the symbol interface (`:mint`) or integer (0) when seeding/testing — do not insert raw strings
- `estimated_value` allows nil; treat nil as "unknown" rather than zero in display logic
- Active Storage requires `active_storage_blobs`/`active_storage_attachments` tables; these must exist (from `rails active_storage:install`) before attaching photos