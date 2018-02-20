require 'rspec'
require 'rails_helper'

RSpec.describe Collection, type: :model do

  context "check validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  context "check associations" do
    it { is_expected.to have_many(:comments) }
    it { is_expected.to have_many(:resources).through(:resources_collections) }
    it { is_expected.to have_many(:collections_tags) }
    it { is_expected.to have_many(:tags).through(:collections_tags) }
    it { is_expected.to have_many(:collection_votes) }
    it { is_expected.to have_many(:resources_collections) }
  end

end
