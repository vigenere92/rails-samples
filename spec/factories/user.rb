FactoryGirl.define do

  factory :user do
    first_name 'Zen'
    email_id { Faker::Internet.email }
    slug 'zen'
    display_name 'zen1'
    image_url 'https://opynyn-images.s3.us-east-2.amazonaws.com/6579dcca-5e9a-4aef-abf3-0d05d4297692_profile_pic161'
  end

end
