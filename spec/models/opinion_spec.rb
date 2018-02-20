require 'rspec'
require 'rails_helper'

RSpec.describe Opinion, type: :model do

  context "check validations" do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:resource_id) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  context "check associations" do
    it { is_expected.to have_many(:opinion_replies) }
    it { is_expected.to have_many(:opinion_votes) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:resource) }
  end

end
