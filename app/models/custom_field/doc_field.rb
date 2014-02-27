class CustomField::DocField < ActiveRecord::Base
  include Sys::Model::Base
  include Cms::Model::Auth::Content

  belongs_to :doc,  foreign_key: :custom_field_doc_id,  class_name: 'CustomField::Doc'
  belongs_to :form, foreign_key: :custom_field_form_id, class_name: 'CustomField::Form'

end
