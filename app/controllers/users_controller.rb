class UsersController < ApplicationController
  before_action :set_slug_user, only: [:show]
  before_action :authenticate_request!, only: [:set_username, :tagline, :bio, :notifications_read,
    :notifications, :image_upload]
  before_action :maybe_authenticate

  # Fetch logged in user's notifications
  def notifications
    render json: @current_user.notifications
  end

  # Mark all notifications as read
  def notifications_read
    user = User.find_by( slug: params[:user_slug] )
    if user.id == @current_user.id
      UserNotification.where( notifier_id: @current_user.id, read: false ).update( read: true )
    end
    render json: {}
  end

  def username_check
    user = User.find_by display_name: username_check_params[ :username ]
    if user.nil?
      render json: { available: true }
    else
      render json: { available: false }
    end
  end

  def set_username
    username = set_username_params[:username]
    user = User.find_by display_name: username
    success = nil
    if user.nil?
      @current_user.slug = nil
      @current_user.display_name = username
      userImage = Identicon.data_url_for username
      @current_user.image_url = userImage
      @current_user.save!
      render json: { success: true, slug: @current_user.slug, imageUrl: @current_user.image_url }
    else
      render json: { success: false }
    end
  end

  # Updates user's tagline
  # @param content [String]
  # @return [Boolean] for success or failure
  def tagline
    if @current_user.update( tagline: tagline_params[ :content ] )
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  # Updates user's bio
  # @param content [String]
  # @return [Boolean] for success or failure
  def bio
    if @current_user.update( bio: bio_params[ :content ] )
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  # Show's the user
  # @param user_slug [String]
  # @return [Hash] user and notification count ( for the logged in user )
  def show
    notificationCount = @current_user.nil? ? 0 : @current_user.unread_notification_count
    render json: { user: @user.formatted(@current_user), notificationCount: notificationCount }
  end

  # Fetch user's resources
  # @return [ Hash ] user's resources
  def resources
    user = User.find_by( slug: params[:user_slug] )
    allResources = Resource.where( url: user.user_urls.pluck(:url) )
    allResources = allResources.map do |resource|
      myUri = URI.parse( resource.url )
      {
        title: resource.title,
        resourceType: resource.resource_type,
        slug: resource.slug,
        opinionsCount: resource.opinions_count,
        ratingsCount: resource.ratings_count,
        url: resource.url,
        tags: resource.tags.pluck(:name).uniq,
        imageUrl: resource.image_url,
        description: resource.description
      }
    end
    render json: allResources
  end

  # Fetch user's resources for the specified rating
  # @param [ String ] rating
  # @return [ Array ] resources with the given rating
  def ratings
    user = User.find_by( slug: params[:user_slug] )
    rating = RATINGS[ ratings_params[ :rating ] ]
    ratings = Rating.preload(:resource).where( user_id: user.id, rating_type: rating )
    resourcesJson = []
    ratings.each do |rating|
      resourcesJson.append( JSON.parse(ResourceCardSerializer.new( rating.resource ).to_json) )
    end

    render json: resourcesJson
  end

  # Fetch user's opinions
  # @return [ Array ] opinions of the user
  def opinions
    user = User.find_by( slug: params[:user_slug] )
    opinions = user.opinions.preload(:resource).order( created_at: :desc )
    opinionJson = []
    opinions.each do |opinion|
      url = '/pieces/' + opinion.resource.slug + '?refCode=1&refMainId=' + opinion.id
      opinionJson.append( {
        opinionContent: opinion.content[0..500],
        resource: ResourceOpinionSerializer.new( opinion.resource ),
        url: url
      } )
    end

    render json: opinionJson
  end

  # Fetch user's collections
  # @return [ Array ] collections of the user
  def collections
    user = User.find_by( slug: params[:user_slug] )
    allCollections = user.collections
    collections = []
    allCollections.each do |collection|
      collections.append( CollectionCardSerializer.new( collection ).as_json )
    end
    render json: collections
  end

  # Fetch user's badges
  # @return [ Array ] badges of the user
  def badges
    user = User.find_by( slug: params[:user_slug] )
    badges = user.badges
    badgeJson = {}
    badges.each do |badge|
      if badgeJson[badge.badge_type].nil?
        badgeJson[badge.badge_type] = []
      end

      badgeJson[badge.badge_type].append(badge.description)
    end
    render json: badgeJson
  end

  # Change user's profile image
  def image_upload
    s3 = Aws::S3::Resource.new

    fileName = @current_user.id + '_profile_pic' + rand(1..10000).to_s
    obj = s3.bucket('opynyn-images').object(fileName)
    obj.upload_file(image_upload_params[:image_file].tempfile, acl: 'public-read')

    if @current_user.update( :image_url => obj.public_url )
      render json: { success: true, imageUrl: obj.public_url }
    else
      render json: { success: false }
    end
  end

  # Follow a user
  # @param [ String ] slug of user to follow
  def follow
    userSlug = follow_params[ :user_slug ]
    user = User.find_by slug: userSlug
    if !user.nil?
      ActiveRecord::Base.transaction do
        userFollowers = user.followers.clone
        if !userFollowers.include? @current_user.id
          userFollowers.append( @current_user.id )
          user.followers = userFollowers
          user.save!
        end

        userFollowing = @current_user.following.clone
        if !userFollowing.include? user.id
          userFollowing.append( user.id )
          @current_user.following = userFollowing
          @current_user.save!
        end
      end
      render json: { success: true, followersCount: user.followers.count, followingCount: user.following.count }
    else
      render json: {success: false}
    end
  end

  # Unfollow a user
  # @param [ String ] slug of user to unfollow
  def unfollow
    userSlug = unfollow_params[ :user_slug ]
    user = User.find_by slug: userSlug
    if !user.nil?
      ActiveRecord::Base.transaction do
        userFollowers = user.followers.clone
        userFollowers.delete( @current_user.id )
        user.followers = userFollowers
        user.save!

        userFollowing = @current_user.following.clone
        userFollowing.delete( user.id )
        @current_user.following = userFollowing
        @current_user.save!
      end
      render json: { success: true, followersCount: user.followers.count, followingCount: user.following.count }
    else
      render json: {success: false}
    end
  end

  # Format each user to include slug, username, tagline and if this user is being followed or not
  # @param users
  # @return [ Array ]
  def format_follow_data(followUsers)
    followerJson = {}

    if !@current_user.nil?
      followingIds = @current_user.following
    else
      followingIds = []
    end

    followUsers.each do |user|
      userSlug = user.slug
      userName = user.first_name + ' ' + user.last_name
      userTagline = ( user.tagline == "" || user.tagline.nil? ) ? '' : user.tagline

      if followingIds.include? user.id
        isFollowing = true
      else
        isFollowing = false
      end

      followerJson[ user.slug ] = {
        slug: userSlug,
        userName: userName,
        tagline: userTagline,
        imageUrl: user.image_url,
        isFollowing: isFollowing
      }
    end
    followerJson
  end

  # Fetch followers of the user
  def followers
    user = User.find_by(slug: params[:user_slug])
    followerIds = user.followers
    followerUsers = User.where( id: followerIds )
    render json: format_follow_data( followerUsers )
  end

  # Fetch users followed by the user
  def following
    user = User.find_by(slug: params[:user_slug])
    followingIds = user.following
    followingUsers = User.where( id: followingIds )
    render json: format_follow_data( followingUsers )
  end

  # Fetch resources for the specified tag
  # @param [ String ] tag for which the resources are to be fetched
  def tag_resources
    tag = tag_resources_params[ :tag ]
    user = User.find_by( slug: params[:user_slug])
    resourcesJson = []
    if !user.nil?
      rts = ResourcesTags.preload(:resource).joins(:tag).where("resources_tags.user_id='#{user.id}' AND tags.name='#{tag}'")
      rts.each do |rt|
        resourcesJson.append( ResourceCardSerializer.new( rt.resource ).as_json )
      end
    end
    render json: resourcesJson
  end

  private

  def ratings_params
    params.permit( :rating )
  end

  def tag_resources_params
    params.permit( :tag )
  end

  def follow_params
    params.permit( :user_slug )
  end

  def unfollow_params
    params.permit( :user_slug )
  end

  def image_upload_params
    params.permit( :image_file)
  end

  def set_slug_user
    @user = User.friendly.find params[ :user_slug ]
  end

  def set_username_params
    params.permit( :username )
  end

  def username_check_params
    params.permit( :username )
  end

  def bio_params
    params.permit( :content )
  end

  def tagline_params
    params.permit( :content )
  end

end
