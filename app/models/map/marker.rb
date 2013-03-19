# encoding: utf-8
class Map::Marker < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Rel::Unid
  include Sys::Model::Auth::Free

  STATE_OPTIONS = [['公開', 'public'], ['非公開', 'closed']]

  # Content
  belongs_to :content, :foreign_key => :content_id, :class_name => 'Tag::Content::Tag'
  validates_presence_of :content_id

  # Proper
  belongs_to :status, :foreign_key => :state, :class_name => 'Sys::Base::Status'

  validates :title, :presence => true
  validates :latitude, :presence => true
  validates :longitude, :presence => true

  after_initialize :set_defaults

  private

  def set_defaults
    self.state ||= 'public' if self.has_attribute?(:state)
  end
end
