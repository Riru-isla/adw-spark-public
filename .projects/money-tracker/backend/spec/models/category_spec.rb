require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'associations' do
    it { should have_many(:transactions).dependent(:destroy) }
    it { should have_many(:budgets).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:category) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:icon) }
    it { should validate_presence_of(:color) }
  end
end
