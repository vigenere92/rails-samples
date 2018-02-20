class ResourceSerializer < ActiveModel::Serializer
  attributes :title, :description, :imageUrl, :createdBy, :createdBySlug, :createdByImageUrl, :slug,
  :createdAt, :tags, :ratings, :embeddable, :resourceType, :opinions, :url

  def imageUrl
    object.image_url
  end

  def createdBy
    object.user.display_name
  end

  def createdBySlug
    object.user.slug
  end

  def createdByImageUrl
    object.user.image_url
  end

  def createdAt
    object.created_at
  end

  def tags
    object.tags.pluck( :name ).uniq
  end

  def ratings
    object.ratings.group( :rating_type ).count.map { |k,v| [ INVERSE_RATINGS[k], v ] }.to_h
  end

  def resourceType
    object.resource_type
  end

  def opinions
    opinions = object.opinions.eager_load( [ :user, opinion_replies: :user ] ).order( created_at: :desc )
    opinions.map do | opinion |
      OpinionSerializer.new( opinion )
    end
  end
end
