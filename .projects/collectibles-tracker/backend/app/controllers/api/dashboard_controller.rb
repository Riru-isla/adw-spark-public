module Api
  class DashboardController < ApplicationController
    def show
      total_collections = Collection.count
      total_items = Item.count
      total_estimated_value = Item.sum(:estimated_value).to_f

      recently_added_items = Item
        .includes(photos_attachments: :blob, :collection => [])
        .order(created_at: :desc)
        .limit(10)

      value_by_condition = build_value_by_condition(Item.all)

      render json: {
        total_collections: total_collections,
        total_items: total_items,
        total_estimated_value: total_estimated_value,
        value_by_condition: value_by_condition,
        recently_added_items: recently_added_items.map { |item| serialize_item(item) }
      }
    end

    private

    def build_value_by_condition(items_scope)
      condition_map = Item.conditions
      raw = items_scope.group(:condition).sum(:estimated_value)
      condition_map.keys.each_with_object({}) do |name, h|
        h[name] = (raw[name] || raw[condition_map[name]] || 0).to_f
      end
    end

    def serialize_item(item)
      {
        id: item.id,
        collection_id: item.collection_id,
        collection_name: item.collection.name,
        name: item.name,
        condition: item.condition,
        estimated_value: item.estimated_value&.to_f,
        acquisition_date: item.acquisition_date,
        notes: item.notes,
        created_at: item.created_at,
        photos: item.photos.map do |attachment|
          {
            id: attachment.blob_id,
            url: rails_blob_url(attachment, host: request.base_url),
            filename: attachment.filename.to_s,
            content_type: attachment.content_type
          }
        end
      }
    end
  end
end
