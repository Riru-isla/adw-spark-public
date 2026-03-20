class Category < ApplicationRecord
  has_many :transactions, dependent: :destroy
  has_many :budgets, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :icon, presence: true
  validates :color, presence: true
end
