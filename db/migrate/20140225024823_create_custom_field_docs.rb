class CreateCustomFieldDocs < ActiveRecord::Migration
  def change
    create_table :custom_field_docs do |t|
      t.belongs_to :content
      t.belongs_to :gp_article_doc
      t.string :title
      t.string :title_kana

      t.timestamps
    end
  end
end
