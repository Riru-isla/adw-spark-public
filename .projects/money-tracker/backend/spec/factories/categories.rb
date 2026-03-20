FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    icon  { "🏠" }
    color { "#EF4444" }
  end
end
