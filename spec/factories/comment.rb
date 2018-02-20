FactoryGirl.define do

  factory :comment do
    content 'Default comment'
    created_at '2017-11-05T06:21:56.728Z'
    association :user
  end

end
