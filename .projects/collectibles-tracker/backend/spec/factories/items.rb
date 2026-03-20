FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "Item #{n}" }
    condition { :good }
    estimated_value { nil }
    acquisition_date { nil }
    notes { nil }
    association :collection
  end
end
