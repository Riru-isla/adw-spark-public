FactoryBot.define do
  factory :budget do
    association :category
    month        { 1 }
    year         { 2026 }
    limit_amount { 500.00 }
  end
end
