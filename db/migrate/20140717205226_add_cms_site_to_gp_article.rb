class AddCmsSiteToGpArticle < ActiveRecord::Migration
  def change
    add_column :gp_article_docs, :rel_gp_article_content_doc_id, :integer
  end
end
