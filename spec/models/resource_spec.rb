require 'rspec'
require 'rails_helper'

RSpec.describe Resource, type: :model do

  context "check validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  context "check associations" do
    it { is_expected.to have_many(:resources_tags) }
    it { is_expected.to have_many(:resources_collections) }
    it { is_expected.to have_many(:collections).through(:resources_collections) }
    it { is_expected.to have_many(:tags).through(:resources_tags) }
    it { is_expected.to have_many(:ratings) }
    it { is_expected.to have_many(:opinions) }
  end
end
