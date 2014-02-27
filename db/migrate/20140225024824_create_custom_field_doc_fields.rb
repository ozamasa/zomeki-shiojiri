class CreateCustomFieldDocFields < ActiveRecord::Migration
  def change
    create_table :custom_field_doc_fields do |t|
      t.belongs_to :content
      t.belongs_to :custom_field_doc
      t.belongs_to :custom_field_form
      t.string :value

      t.timestamps
    end
  end
end
