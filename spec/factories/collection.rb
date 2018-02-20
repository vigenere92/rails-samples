FactoryGirl.define do

  factory :collection do
    title 'Default collection'
    description 'Default description'
    upvote_count 10
    downvote_count 9
    created_at '2018-02-15T21:07:27.863Z'
    slug 'default-slug'
    user
  end

  trait :with_resources do
    after(:create) do |collection, evaluator|
      collection.resources = [ build( :resource, user_id: evaluator.user.id ) ]
    end
  end

end
