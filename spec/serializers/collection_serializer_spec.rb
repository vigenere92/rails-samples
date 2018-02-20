require 'rspec'
require 'rails_helper'

RSpec.describe CollectionSerializer, type: :serializer do

    let (:user) { create(:user) }
    let (:collection) { create(:collection, :with_resources, user: user, user_id: user.id) }

    it 'check collection serialization with resources' do
        serialized = JSON.parse( CollectionSerializer.new(collection).to_json )
        resource = collection.resources.first
        expect(serialized).to match({
            "slug"=> collection.slug,
            "createdByImageUrl"=> user.image_url,
            "createdBy"=> user.display_name,
            "createdBySlug"=> user.slug,
            "downvoteCount"=> collection.downvote_count,
            "upvoteCount"=> collection.upvote_count,
            "createdAt"=> collection.created_at,
            "tags"=> [],
            "description"=> collection.description,
            "title"=> collection.title,
            "comments"=> [],
            "resources"=> [
                {
                    "title"=> resource.title,
                    "description"=> resource.description,
                    "url"=> resource.url,
                    "slug"=> resource.slug,
                    "resourceType"=> nil,
                    "imageUrl"=> nil
                }
            ]
        })
    end
end
