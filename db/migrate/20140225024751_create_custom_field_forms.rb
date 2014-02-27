class CreateCustomFieldForms < ActiveRecord::Migration
  def change
    create_table :custom_field_forms do |t|
      t.belongs_to :content
      t.string :name
      t.string :title
      t.string :type
      t.string :style
      t.integer :sort_no

      t.timestamps
    end
  end
end
