class AddTitleKanaToGpArticleDocs < ActiveRecord::Migration
  def change
    add_column :gp_article_docs, :title_kana, :string
  end
end
