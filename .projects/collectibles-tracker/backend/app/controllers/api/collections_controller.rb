module Api
  class CollectionsController < ApplicationController
    before_action :set_collection, only: [ :show, :update, :destroy ]

    def index
      collections = Collection
        .left_joins(:items)
        .group(:id)
        .select("collections.*, COUNT(items.id) AS item_count, COALESCE(SUM(items.estimated_value), 0) AS total_value")
      render json: collections.map { |c| serialize_collection(c) }
    end

    def show
      value_by_condition = build_value_by_condition(@collection.items)
      render json: serialize_collection(@collection).merge(value_by_condition: value_by_condition)
    end

    def create
      collection = Collection.new(collection_params)
      if collection.save
        render json: serialize_collection(with_aggregates(collection)), status: :created
      else
        render json: { errors: collection.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @collection.update(collection_params)
        render json: serialize_collection(with_aggregates(@collection))
      else
        render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @collection.destroy
      head :no_content
    end

    private

    def set_collection
      @collection = Collection
        .left_joins(:items)
        .group(:id)
        .select("collections.*, COUNT(items.id) AS item_count, COALESCE(SUM(items.estimated_value), 0) AS total_value")
        .find(params[:id])
    end

    def collection_params
      params.require(:collection).permit(:name, :category, :description)
    end

    def with_aggregates(collection)
      Collection
        .left_joins(:items)
        .group(:id)
        .select("collections.*, COUNT(items.id) AS item_count, COALESCE(SUM(items.estimated_value), 0) AS total_value")
        .find(collection.id)
    end

    def build_value_by_condition(items_scope)
      condition_map = Item.conditions  # {"mint" => 0, "near_mint" => 1, ...}
      raw = items_scope.group(:condition).sum(:estimated_value)
      condition_map.keys.each_with_object({}) do |name, h|
        h[name] = (raw[name] || raw[condition_map[name]] || 0).to_f
      end
    end

    def serialize_collection(collection)
      {
        id: collection.id,
        name: collection.name,
        category: collection.category,
        description: collection.description,
        created_at: collection.created_at,
        updated_at: collection.updated_at,
        item_count: collection.item_count.to_i,
        total_value: collection.total_value.to_f
      }
    end
  end
end
