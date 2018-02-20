require 'rails_helper'
include AuthModule
include Requests::JsonHelpers

RSpec.describe CollectionsController, type: :controller do

  describe "test controller create, upvote, downvote" do

    before :all do
      # create user for authentication
      user = create(:user, slug: "cherokee", display_name: "Cherokee" )
      token = encode( { user_id: user.id } )
      @headers = { "Authorization" => "Bearer #{token}" }
    end

    context "collection create" do

      let(:params) do
        {
          :resources => [ "https://vimeo.com/240741677", "https://zerodha.com/varsity/chapter/support-resistance/" ],
          :title => "Sample collection",
          :description => "Sample description",
          :tags => [ "tag1", "tag2" ]
        }
      end

      it "POST #create" do
        request.headers.merge! @headers
        post :create, params: params
        expect(Collection.count).to eq(1)
      end

    end

    context "collection upvote, downvote" do

      let (:user) { create(:user) }
      let (:collection) { create(:collection, user: user, user_id: user.id) }

      it "collection upvote" do
        request.headers.merge! @headers
        post :vote, params: { collection_slug: collection.slug, type: "upvote" }
        upvotes = response_json[ "upvoteCount" ]
        expect(upvotes).to eql(collection.upvote_count + 1)
      end

      it "collection downvote" do
        request.headers.merge! @headers
        post :vote, params: { collection_slug: collection.slug, type: "downvote" }
        downvotes = response_json[ "downvoteCount" ]
        expect(downvotes).to eql(collection.downvote_count + 1)
      end

    end

  end


end

