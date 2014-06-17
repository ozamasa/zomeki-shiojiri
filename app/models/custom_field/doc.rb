class CustomField::Doc < ActiveRecord::Base
  include Sys::Model::Base
  include Cms::Model::Auth::Content

  # Content
  belongs_to :content, foreign_key: :content_id, class_name: 'CustomField::Content::Doc'
  validates_presence_of :content_id, :title, :title_kana
  validate :validate_fields

  has_many :fields, foreign_key: :custom_field_doc_id,  class_name: 'CustomField::DocField', dependent: :destroy
  has_many :forms,  foreign_key: :custom_field_form_id, class_name: 'CustomField::Form', through: :fields, order: :sort_no

  accepts_nested_attributes_for :fields #, allow_destroy: true

  attr_accessor :validate_field_errors

  def gp_article_doc(gparticle)
    if gparticle && gp_article_doc_id.presence
      gparticle.docs.find(gp_article_doc_id) rescue nil
    end
  end

  def validate_fields
    @validate_field_errors = []
    self.fields.each do |field|
      if field.form.style == 'require' && field.value.blank?
        errors.add :base, "#{field.form.title}を入力してください。"
        @validate_field_errors << field.form.id
      end
    end
  end
end
