FactoryBot.define do
  factory :collection do
    sequence(:name) { |n| "Collection #{n}" }
    category { nil }
    description { nil }
  end
end
