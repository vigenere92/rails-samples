class Resource < ApplicationRecord
  acts_as_paranoid
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  validates :url, :description, :title, :user_id, :presence => true

  belongs_to :user
  has_many :resources_tags
  has_many :resources_collections
  has_many :collections, through: :resources_collections
  has_many :tags, through: :resources_tags
  has_many :ratings
  has_many :opinions
  has_many :resources_streams
  belongs_to :stream

  after_create :check_embeddable


  def check_embeddable
    response = RestClient.get self.url
    if response.headers[:x_frame_options].nil? && !(self.url.include? 'http:')
      self.embeddable = true
      self.save!
    end
  end

  def slug_candidates
    [
      :title,
      :url
    ]
  end
end
