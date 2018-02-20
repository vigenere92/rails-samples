class CollectionSerializer < ActiveModel::Serializer
  attributes :slug, :createdByImageUrl, :createdBy, :createdBySlug, :downvoteCount, :upvoteCount, :createdAt,
  :tags, :description, :title, :comments, :resources

  def createdBy
    object.user.display_name
  end

  def createdAt
    object.created_at
  end

  def createdBySlug
    object.user.slug
  end

  def createdByImageUrl
    object.user.image_url
  end

  def downvoteCount
    object.downvote_count
  end

  def upvoteCount
    object.upvote_count
  end

  def tags
    object.tags.pluck( :name ).uniq
  end

  def comments
    object.comments.eager_load( :replies ).map { |comment| CommentSerializer.new( comment ) }
  end

  def resources
    object.resources.map { |resource| ResourceCollectionSerializer.new( resource ) }
  end
end
