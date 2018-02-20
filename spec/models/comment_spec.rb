require 'rspec'
require 'rails_helper'

RSpec.describe Comment, type: :model do

  context "check validations" do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:collection_id) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  context "check associations" do
    it { is_expected.to have_many(:replies) }
    it { is_expected.to belong_to(:collection) }
    it { is_expected.to belong_to(:user) }
  end

end
