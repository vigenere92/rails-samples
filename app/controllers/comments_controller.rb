class CommentsController < ApplicationController
  before_action :set_collection, only: [:create, :reply, :destroy]
  before_action :authenticate_request!
  before_action :set_comment, only: [:update, :reply, :destroy, :spam]

  # Mark the comment as spam
  def spam
    userSpam = UserSpam.new( user_id: @current_user.id, spam_entity_type: SPAM_TYPE[ :comment ],
      spam_entity: { comment_id: @comment.id } )
    if userSpam.save!
      # save user activity
      save_activity :marked_collection_comment_spam, { comment_id: @comment.id }
      render json: { spamMarked: true }
    else
      render json: { spamMarked: false }
    end
  end

  # Delete the comment
  def destroy
    raise UnAuthorizedAccessError.new if @comment.user_id != @current_user.id

    ids = [ @comment.id ]
    parentIds = Comment.where( parent_id: @comment.id ).pluck( :id )
    while !parentIds.blank?
      ids = ids + parentIds
      parentIds = Comment.where( parent_id: parentIds )
    end

    if Comment.where( id: ids ).delete_all
      # save user activity
      save_activity :deleted_collection_comment, { collection_id: @collection.id }
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  # Create a comment on the collection
  # @param content [ String ]
  def create
    content = create_params[ :content ]
    comment = Comment.create( content: content, user_id: @current_user.id, collection_id: @collection.id )

    # save user activity
    save_activity :commented_on_collection, { comment_id: comment.id, collection_id: @collection.id }
    render json: comment
  end

  # Update the comment
  # @param content [ String ]
  def update
    raise UnAuthorizedAccessError.new if @comment.user_id != @current_user.id

    @comment.update( content: update_params[ :content] )

    # save user activity
    save_activity :updated_comment_on_collection, { comment_id: @comment.id }
    render json: @comment
  end

  def reply
    commentReply = Comment.create( user_id: @current_user.id, collection_id: @collection.id, parent_id: @comment.id,
      content: reply_params[ :content] )

    # save user activity
    save_activity :commented_on_collection_comment, { comment_reply_id: commentReply.id, collection_id: @collection.id,
    comment_id: @comment.id }
    render json: commentReply
  end

  private

  def reply_params
    raise InvalidParamsError.new( 'reply content cannot be empty' ) if params[ :content ].strip == ""
    params.permit( :content )
  end

  def update_params
    raise InvalidParamsError.new( 'reply content cannot be empty' ) if params[ :content ].strip == ""
    params.permit( :content )
  end

  def create_params
    raise InvalidParamsError.new( 'reply content cannot be empty' ) if params[ :content ].strip == ""
    params.permit( :content )
  end

  def set_comment
    @comment = Comment.find params[:comment_id]
  end

  def set_collection
    @collection = Collection.friendly.find params[:collection_slug]
  end

end
