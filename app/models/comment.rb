class Comment < ApplicationRecord
  acts_as_paranoid
  belongs_to :user
  belongs_to :collection
  has_many :replies, :class_name => 'Comment', :foreign_key => 'parent_id'

  validates :content, :user_id, :collection_id, :presence => true
  validates :collection, :presence => true

end
