class CustomField::Form < ActiveRecord::Base
  include Sys::Model::Base
  include Cms::Model::Auth::Content

  default_scope order(:sort_no)

  # Content
  belongs_to :content, foreign_key: :content_id, class_name: 'CustomField::Content::Doc'
  validates_presence_of :content_id, :name, :title
  validates_uniqueness_of :name, scope: :content_id

  has_one :field, foreign_key: :custom_field_form_id,  class_name: 'CustomField::DocField', dependent: :destroy

end
