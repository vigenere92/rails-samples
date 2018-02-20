class ResourcesController < ApplicationController
  include UrlModule
  include ErrorsModule

  before_action :authenticate_request!, only: [:create, :spam, :user_resources, :extension_rate, :index_category]
  before_action :set_resource, only: [:show, :spam, :recommendations, :index_category]
  # check ratings are correct
  before_action :check_rating_sanity, only: [:create]
  before_action :maybe_authenticate

  # Fetch resources that have not been indexed yet
  def category_index
    page = params[ :page_id ]
    resources = Resource.left_outer_joins(:resources_streams).where('stream_id is NULL').paginate( page: page, per_page: 20 )
    resources = resources.map { |resource| ResourceCardSerializer.new( resource ) }
    render json: { resources: resources }
  end

  # Index a resource to one of the categories [ used by admin ]
  def index_category
    if ![ 'a98be6b7-57c0-4899-95dd-53f0edc5b6c9', '82a55931-96c1-498d-a9f8-9c5f0dd24947',
      '6579dcca-5e9a-4aef-abf3-0d05d4297692', 'd9f56033-a68e-421d-b8a3-b8a87a9ce829'].include? @current_user.id
      raise Exception
    end

    stream = Stream.friendly.find( params[ :streamSlug ] )
    if ResourcesStreams.create( stream_id: stream.id, resource_id: @resource.id )
      render json: { success: true }
    else
      render json: { success: false }
    end
  end


  # Fetch all resources for the user. Fetch recommendations if user is signed in
  def all
    pageId = all_params[ :page ].to_i
    filter = all_params[ :filter ]
    stream = all_params[ :stream]

    streamId =  !stream.nil? ? Stream.friendly.find(stream).id : nil

    results = nil
    if @current_user.nil? || !stream.nil?
      results = SearchService.allResources( pageId, filter, streamId )
    else
      results = SearchService.userRecommendations(@current_user, pageId, filter )
      if results[ :results ].blank?
        results = SearchService.allResources( pageId, filter, streamId )
      end
    end

    # include notifications if user is signed in
    notificationCount = @current_user.nil? ? 0 : @current_user.unread_notification_count
    render json: {
      resources: results[ :results ],
      hasMore: results[ :hasMore ],
      currentPage: results[ :currentPage ],
      notificationCount: notificationCount
    }
  end

  # Fetch all info for a resource
  def show
    info = fetch_url_info( @resource.url )
    userRating = @current_user.nil? ? nil : Rating.find_by( user_id: @current_user.id, resource_id: @resource.id )
    notificationCount = @current_user.nil? ? 0 : @current_user.unread_notification_count
    userTags = []
    userId = nil

    if !@current_user.nil?
      userTags = ResourcesTags.where( user_id: @current_user.id, resource_id: @resource.id ).joins( :tag ).pluck( :name )
    end

    render json: {
      notificationCount: notificationCount,
      resource: ResourceSerializer.new( @resource ),
      suggestedTags: info[ "suggestedTags" ],
      userRating: ( userRating.nil? ? nil : INVERSE_RATINGS[userRating.rating_type] ),
      userTags: userTags
     }
  end

  # Get recommended resources for a give resource
  # @param page_id [ String ]
  def recommendations
    userId = nil
    if !@current_user.nil?
      userId = @current_user.id
    end

    pageId = params[ :page_id ].to_i
    results = SearchService.resourceRecommendations( @resource, pageId, userId )
    render json: { recommendedResources: results[ :results ], hasMore: results[ :hasMore ] }
  end

  # Mark the resource as spam
  def spam
    userSpam = UserSpam.new( user_id: @current_user.id, spam_entity_type: SPAM_TYPE[ :resource ],
      spam_entity: { resource_id: @resource.id } )
    if userSpam.save!
      # save user activity
      save_activity :marked_resource_spam, { resource_id: @resource.id }
      render json: { spamMarked: true }
    else
      render json: { spamMarked: false }
    end
  end

  # Get all the info for a resource
  def resource_info resource, userSubmitted
    user = resource.user

    {
      slug: resource.slug,
      createdBy: user.display_name,
      createdAt: resource.created_at,
      createdByUrl: BASE_URL + user.slug,
      tags: resource.tags.pluck( :name ).uniq,
      ratings: resource.ratings.group( :rating_type ).count.map { |k,v| [ INVERSE_RATINGS[k], v ] }.to_h,
      opinions: resource.get_opinions,
      userSubmitted: userSubmitted
    }

  end


  # create a new resource
  def create_resource( newResource = false )
    url = create_params[ :url ]

    if @current_user.id == 'a98be6b7-57c0-4899-95dd-53f0edc5b6c9' || @current_user.id == 'fc8b720f-a306-4849-8bc1-38fafae7c92b'
      @current_user = User.where(email_id: "neha@neha.com")[rand(944)]
    end

    if newResource
      userSubmitted = false
    else
      # Check if user already submitted this url
      userSubmitted = @current_user.user_urls.where( url: url ).blank? ? false : true
    end

    reputationChange = 0

    if !userSubmitted
      opinion = create_params[ :opinion ] ? create_params[ :opinion ] : nil
      opinion = opinion.strip if !opinion.nil?
      tags = create_params[ :tags ]
      tags = tags.uniq if !tags.nil?
      rating = create_params[ :rating ]
      privacy = create_params[ :privacy ]

      # Check if we already have a resource with this url
      resource = Resource.find_by url: url

      ActiveRecord::Base.transaction do
        if resource.nil?
          # Fetch info for this url, it should be in cache
          urlInfo = fetch_url_info( url )
          # create a new resource
          resource = Resource.create( url: urlInfo[ "url" ], title: urlInfo[ "title" ], description: urlInfo[ "description" ],
            image_url: urlInfo[ "imageUrl" ], resource_type: check_url_type( url ),
            suggested_tags: urlInfo[ "suggestedTags" ], user_id: @current_user.id, private: privacy )
        end

        if !tags.blank?
          reputationChange += TAG_REP
          dbTags = Tag.where( name: tags )
          # Create resource, tag, user mapping
          dbTags.each do |dbTag|
            ResourcesTags.create( resource_id: resource.id, user_id: @current_user.id, tag_id: dbTag.id )
            tags.delete( dbTag.name )
          end

          # Create tags for the new tags
          tags.each do |tag|
            tag = tag.downcase.strip
            newTag = Tag.create( name: tag )
            # Create resource, tag, user mapping
            ResourcesTags.create( resource_id: resource.id, user_id: @current_user.id, tag_id: newTag.id )
          end
        end

        # Set rating
        if !rating.nil?
          reputationChange += RATE_REP
          Rating.create( resource_id: resource.id, user_id: @current_user.id, rating_type: RATINGS[ rating ] )
        end

        # Set opinion
        if !opinion.nil?
          reputationChange += OPINION_ADD_REP
          Opinion.create( resource_id: resource.id, user_id: @current_user.id, content: opinion )
        end

        UserUrl.create( user_id: @current_user.id, url: url )
        reindex_resource( resource.id )
        save_activity :added_resource, { resource_id: resource.id, reputation_change: reputationChange }

      end
    else
      resource = Resource.find_by url: url
    end

    resource
  end

  # Create a resource
  # @param url [ String ]
  # @param tags [ Array ]
  # @param rating [ String ]
  # @param opinion [ String ]
  def create
    resource = create_resource
    render json: { slug: resource.slug }
  end

  def update
  end

  def destroy
  end

  def format_resource_data( resource, info )
    userRating = @current_user.nil? ? nil : Rating.find_by( user_id: @current_user.id, resource_id: resource.id )
    resourceJson = ResourceSerializer.new( resource )

    userId = @current_user.nil? ? nil : @current_user.id
    results = SearchService.resourceRecommendations( resource, 1, userId )
    recommendedResources = results[ :results ]
    hasMoreRecommendations = results[ :hasMore ]

    userTags = []
    if !@current_user.nil?
      userTags = ResourcesTags.where( user_id: @current_user.id, resource_id: resource.id ).joins( :tag ).pluck( :name )
    end

    {
      resource: resourceJson,
      recommendedResources: recommendedResources,
      hasMoreRecommendations: hasMoreRecommendations,
      suggestedTags: info[ "suggestedTags" ],
      userRating: ( userRating.nil? ? nil : INVERSE_RATINGS[userRating.rating_type] ),
      userTags: userTags,
      present: true
    }
  end

  def extension_data
    url = extension_data_params[:url]
    info = fetch_url_info( url )
    response = nil

    resource = Resource.find_by(url: url)

    if !resource.nil?
      response = format_resource_data( resource, info )
    else
      response = {
        present: false,
        userTags: [],
        userRating: nil,
        recommendedResources: [],
        suggestedTags: info[ "suggestedTags" ],
        resource: {
          title: info[ "title" ],
          description: info [ "description" ],
          imageUrl: info[ "imageUrl" ],
          tags: [],
          ratings: {},
          opinions: [],
          resourceType: info[ "resourceType" ],
          url: info[ "url" ]
        }
      }
    end

    render json: response
  end

  def extension_create
    resource = create_resource( true )
    render json: format_resource_data( resource, fetch_url_info( create_params[ :url ] ) )
  end

  private
    def all_params
      params.permit( :page, :filter, :stream )
    end

    def index_category_params
      params.permit( :streamSlug )
    end

    def extension_data_params
      params.permit( :url )
    end

    def create_params
      params.permit( :url, :opinion, :rating, :privacy, :tags => [] )
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_params
      params.fetch(:resource, {})
    end
end
