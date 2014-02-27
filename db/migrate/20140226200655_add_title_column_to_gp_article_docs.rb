class AddTitleColumnToGpArticleDocs < ActiveRecord::Migration
  def change
    add_column :gp_article_docs, :title_column, :string
  end
end
