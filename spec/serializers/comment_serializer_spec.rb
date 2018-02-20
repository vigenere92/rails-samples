require 'rspec'
require 'rails_helper'

RSpec.describe CommentSerializer, type: :serializer do

    let (:user) { create(:user) }
    let (:collection) { create(:collection, user_id: user.id) }
    let (:comment) { create(:comment, user_id: user.id, collection_id: collection.id) }

    it 'check comment serialization without replies' do
        serialized = JSON.parse( CommentSerializer.new(comment).to_json )
        expect(serialized).to match({
            "id"=>comment.id,
            "content"=>comment.content,
            "createdBy"=>user.display_name,
            "createdAt"=>comment.created_at,
            "createdBySlug"=>user.slug,
            "createdByImageUrl"=>user.image_url,
            "replies"=>[]
        })
    end
end
