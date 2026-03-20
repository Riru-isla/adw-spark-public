class Transaction < ApplicationRecord
  belongs_to :category

  enum :transaction_type, { income: "income", expense: "expense" }
  enum :expense_kind, { fixed: "fixed", variable: "variable" }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validates :transaction_type, presence: true
end
