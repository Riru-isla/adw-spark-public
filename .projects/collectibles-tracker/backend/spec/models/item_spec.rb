require 'rails_helper'

RSpec.describe Item, type: :model do
  it { is_expected.to belong_to(:collection) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:condition) }
  it { is_expected.to define_enum_for(:condition).with_values(mint: 0, near_mint: 1, good: 2, fair: 3, poor: 4) }
  it { is_expected.to validate_numericality_of(:estimated_value).is_greater_than_or_equal_to(0).allow_nil }

  it 'has many attached photos' do
    item = build(:item)
    expect(item.photos).to be_an(ActiveStorage::Attached::Many)
  end
end
