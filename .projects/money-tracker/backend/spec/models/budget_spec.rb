require 'rails_helper'

RSpec.describe Budget, type: :model do
  describe 'associations' do
    it { should belong_to(:category) }
  end

  describe 'validations' do
    subject { build(:budget) }

    it { should validate_presence_of(:month) }
    it { should validate_inclusion_of(:month).in_range(1..12) }
    it { should validate_presence_of(:year) }
    it { should validate_numericality_of(:year).only_integer.is_greater_than(0) }
    it { should validate_presence_of(:limit_amount) }
    it { should validate_numericality_of(:limit_amount).is_greater_than(0) }
    it { should validate_uniqueness_of(:month).scoped_to(:category_id, :year) }
  end

  describe 'unique index on [category_id, month, year]' do
    it 'rejects duplicate at the DB level' do
      budget = create(:budget)
      duplicate = build(:budget, category: budget.category, month: budget.month, year: budget.year)
      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
