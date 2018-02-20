class CommentSerializer < ActiveModel::Serializer
  attributes :id, :content, :createdBy, :createdAt, :createdBySlug, :createdByImageUrl, :replies

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

  def replies
    object.replies.map { |reply| CommentSerializer.new( reply ) }
  end

end
