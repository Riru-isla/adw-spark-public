require 'rails_helper'

RSpec.describe Collection, type: :model do
  it { is_expected.to have_many(:items).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:name) }
end
