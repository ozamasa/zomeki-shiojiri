class CustomField::Form < ActiveRecord::Base
  include Sys::Model::Base
  include Cms::Model::Auth::Content

  default_scope order(:sort_no)

  # Content
  belongs_to :content, foreign_key: :content_id, class_name: 'CustomField::Content::Doc'
  validates_presence_of :content_id, :name, :title
  validates_uniqueness_of :name, scope: :content_id

  has_many :fields, foreign_key: :custom_field_form_id, class_name: 'CustomField::DocField' #, dependent: :destroy
  has_many :docs,   foreign_key: :custom_field_doc_id,  class_name: 'CustomField::Doc', through: :fields

  STYLE_OPTIONS = [['必須','require'],['必須でない','option']]
  METHOD_OPTIONS = [['テキストフィールド','text'],['テキストエリア','text_area'],['プルダウン','select'],['ラジオボタン','radio_buttons'],['チェックボックス','check_boxs']]

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

  def input_option_array
    options = []
    input_option.each_line do |option|
      options << [option.chomp, option.chomp]
    end
    options
  end
end
