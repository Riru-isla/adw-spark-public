require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'associations' do
    it { should belong_to(:category) }
  end

  describe 'validations' do
    subject { build(:transaction) }

    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:transaction_type) }
  end

  describe 'enums' do
    it { should define_enum_for(:transaction_type).with_values(income: "income", expense: "expense").backed_by_column_of_type(:string) }
    it { should define_enum_for(:expense_kind).with_values(fixed: "fixed", variable: "variable").backed_by_column_of_type(:string) }
  end
end
