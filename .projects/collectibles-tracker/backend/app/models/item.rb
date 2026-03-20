class Item < ApplicationRecord
  belongs_to :collection
  has_many_attached :photos

  enum :condition, { mint: 0, near_mint: 1, good: 2, fair: 3, poor: 4 }

  validates :name, presence: true
  validates :condition, presence: true
  validates :estimated_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :search, ->(query: nil, collection_id: nil, condition: nil, value_min: nil, value_max: nil) {
    scope = all
    if query.present?
      scope = scope.where("items.name ILIKE :q OR items.notes ILIKE :q", q: "%#{query}%")
    end
    scope = scope.where(collection_id: collection_id) if collection_id.present?
    scope = scope.where(condition: condition) if condition.present?
    scope = scope.where("items.estimated_value >= ?", value_min.to_f) if value_min.present?
    scope = scope.where("items.estimated_value <= ?", value_max.to_f) if value_max.present?
    scope
  }
end
