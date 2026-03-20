class Budget < ApplicationRecord
  belongs_to :category

  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :year, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :limit_amount, presence: true, numericality: { greater_than: 0 }
  validates :month, uniqueness: { scope: [:category_id, :year] }
end
