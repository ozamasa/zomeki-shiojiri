class CustomField::Content::Doc < Cms::Content
  default_scope { where(model: ['CustomField::Doc', 'CustomField::Form']) }

  has_many :docs,  foreign_key: :content_id, class_name: 'CustomField::Doc',  dependent: :destroy
  has_many :forms, foreign_key: :content_id, class_name: 'CustomField::Form', dependent: :destroy
end