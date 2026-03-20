FactoryBot.define do
  factory :transaction do
    association :category
    amount           { 50.00 }
    date             { Date.today }
    notes            { "Test note" }
    transaction_type { "expense" }
    expense_kind     { "variable" }
  end
end
