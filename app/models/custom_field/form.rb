class CustomField::Form < ActiveRecord::Base
  include Sys::Model::Base
  include Cms::Model::Auth::Content

  default_scope order(:sort_no)

  # Content
  belongs_to :content, foreign_key: :content_id, class_name: 'CustomField::Content::Doc'
  validates_presence_of :content_id, :name, :title
  validates_uniqueness_of :name, scope: :content_id

  has_many :field, foreign_key: :custom_field_form_id,  class_name: 'CustomField::DocField' #, dependent: :destroy

  STYLE_OPTIONS = [['必須','require'],['必須でない','option']]
  METHOD_OPTIONS = [['テキストフィールド','text'],['テキストエリア','text_area'],['プルダウン','select'],['ラジオボタン','radio_buttons'],['チェックボックス','check_boxs']]

  def value(content_id, doc_id)
    docfield = CustomField::DocField.find_by_content_id_and_custom_field_doc_id_and_custom_field_form_id(content_id, doc_id, id).value rescue nil
  end

  def editable?
    true
  end

  def creatable?
    editable?
  end

  def deletable?
    editable?
  end

  def show_style
    STYLE_OPTIONS.detect{|to| to.last == self.style }.try(:first)
  end

  def show_input_method
    METHOD_OPTIONS.detect{|to| to.last == self.input_method }.try(:first)
  end
end
