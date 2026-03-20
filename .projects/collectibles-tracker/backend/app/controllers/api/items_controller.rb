module Api
  class ItemsController < ApplicationController
    before_action :set_item, only: [ :show, :update, :destroy ]

    def index
      collection = Collection.find(params[:collection_id])
      items = collection.items.includes(photos_attachments: :blob)
      render json: items.map { |i| serialize_item(i) }
    end

    def search
      items = Item.includes(photos_attachments: :blob)
                  .search(
                    query: params[:query],
                    collection_id: params[:collection_id],
                    condition: params[:condition],
                    value_min: params[:value_min],
                    value_max: params[:value_max]
                  )
      if params[:category].present?
        items = items.joins(:collection).where("collections.category ILIKE ?", "%#{params[:category]}%")
      end
      render json: items.map { |i| serialize_item(i) }
    end

    def show
      render json: serialize_item(@item)
    end

    def create
      collection = Collection.find(params[:collection_id])
      item = collection.items.build(item_params)
      if item.save
        render json: serialize_item(item), status: :created
      else
        render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if params[:remove_photo_ids].present?
        Array(params[:remove_photo_ids]).each do |blob_id|
          attachment = @item.photos.find { |a| a.blob_id.to_s == blob_id.to_s }
          attachment&.purge
        end
      end

      if @item.update(item_params)
        render json: serialize_item(@item.reload)
      else
        render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @item.destroy
      head :no_content
    end

    private

    def set_item
      @item = Item.find(params[:id])
    end

    def item_params
      params.permit(:name, :condition, :estimated_value, :acquisition_date, :notes, photos: [])
    end

    def serialize_item(item)
      {
        id: item.id,
        collection_id: item.collection_id,
        name: item.name,
        condition: item.condition,
        estimated_value: item.estimated_value&.to_f,
        acquisition_date: item.acquisition_date,
        notes: item.notes,
        created_at: item.created_at,
        updated_at: item.updated_at,
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
