require 'rspec'
require 'rails_helper'

RSpec.describe User, type: :model do

  context "check validations" do
    it { is_expected.to validate_presence_of(:first_name) }
  end

  context "check associations" do
    it { is_expected.to have_many(:resources) }
    it { is_expected.to have_many(:collections) }
    it { is_expected.to have_many(:ratings) }
    it { is_expected.to have_many(:opinions) }
    it { is_expected.to have_many(:opinion_replies) }
    it { is_expected.to have_many(:comments) }
    it { is_expected.to have_many(:opinion_votes) }
    it { is_expected.to have_many(:collection_votes) }
    it { is_expected.to have_many(:resources) }
    it { is_expected.to have_many(:user_activities) }
    it { is_expected.to have_many(:users_badges) }
    it { is_expected.to have_many(:badges).through(:users_badges) }
    it { is_expected.to have_many(:resources_tags) }
    it { is_expected.to have_many(:tags).through(:resources_tags) }
    it { is_expected.to have_many(:user_urls) }
    it { is_expected.to have_one(:user_tag_streak) }
    it { is_expected.to have_many(:user_specific_tag_streaks) }
    it { is_expected.to have_one(:user_rating_streak) }
    it { is_expected.to have_one(:user_activity_streak) }
    it { is_expected.to have_one(:user_opinion_streak) }
    it { is_expected.to have_many(:user_activities) }
  end

end
