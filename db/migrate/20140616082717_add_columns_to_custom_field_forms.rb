class AddColumnsToCustomFieldForms < ActiveRecord::Migration
  def change
    add_column :custom_field_forms, :input_method, :string
    add_column :custom_field_forms, :input_option, :text
  end
end
