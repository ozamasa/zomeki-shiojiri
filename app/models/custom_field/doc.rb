class CustomField::Doc < ActiveRecord::Base
  include Sys::Model::Base
  include Cms::Model::Auth::Content

  # Content
  belongs_to :content, foreign_key: :content_id, class_name: 'CustomField::Content::Doc'
  validates_presence_of :content_id, :title

  has_many :fields, foreign_key: :custom_field_doc_id,  class_name: 'CustomField::DocField', dependent: :destroy
  has_many :forms,  foreign_key: :custom_field_form_id, class_name: 'CustomField::Form', through: :fields, order: :sort_no

  accepts_nested_attributes_for :fields #, allow_destroy: true

end
