# Story 3: Items API endpoints with photo uploads

## What was built
RESTful CRUD API for items within collections, with multi-photo support via Active Storage. The controller handles nested routing (items under collections for index/create) and top-level routing (for show/update/destroy), and includes selective photo removal on update via `remove_photo_ids`.

## Key files
- `backend/app/controllers/api/items_controller.rb` — full CRUD with inline `serialize_item` helper that includes Active Storage photo URLs
- `backend/app/controllers/application_controller.rb` — includes `Rails.application.routes.url_helpers` (added for `rails_blob_url` access in controllers)
- `backend/config/routes.rb` — nested `resources :items` under `:collections` for index/create; top-level `resources :items` for show/update/destroy
- `backend/app/models/item.rb` — `has_many_attached :photos` (established in Story 1, used here)
- `backend/spec/requests/api/items_spec.rb` — 10 request specs covering all endpoints including photo attach/remove
- `backend/spec/factories/items.rb` — FactoryBot factory for items

## Database changes
- No new migrations — `items` table and Active Storage tables were created in Story 1
- Active Storage blobs/attachments tables power the photo storage

## API endpoints
- `GET /api/collections/:collection_id/items` — list items in a collection with photo URLs
- `POST /api/collections/:collection_id/items` — create item, accepts `photos: []` multipart array
- `GET /api/items/:id` — single item with full details and photo URLs
- `PUT /api/items/:id` — update item fields; pass `remove_photo_ids` array to purge specific photos; pass `photos` to add new ones
- `DELETE /api/items/:id` — destroy item and all attached photos (purged via `dependent: :purge_later` on the attachment)

## Patterns & conventions
- No dedicated serializer class — inline `serialize_item` private method on the controller
- Photo URLs generated with `rails_blob_url(attachment, host: request.base_url)` — requires `url_helpers` in `ApplicationController`
- Photo removal by `blob_id` (not attachment id) passed as `remove_photo_ids` param
- `includes(photos_attachments: :blob)` on index query to avoid N+1 on photo serialization
- `estimated_value` serialized as `.to_f` (decimal → float)

## Dependencies
- No new gems — Active Storage is part of Rails and was enabled in the initial scaffold

## Notes
- Photo upload requires `multipart/form-data` requests; JSON-only clients cannot attach files directly
- `remove_photo_ids` expects blob IDs (the `blob_id` field on the attachment), not attachment record IDs — the next story's frontend must track `photo.id` from the serialized response (which is `blob_id`)
- `condition` is an integer enum: `mint: 0, near_mint: 1, good: 2, fair: 3, poor: 4` — send string values, Rails maps them