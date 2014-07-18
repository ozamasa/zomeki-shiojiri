class AddPortalGroupToGpArticle < ActiveRecord::Migration
  def change
    add_column :gp_article_docs, :portal_group_id, :integer
    add_column :gp_article_docs, :portal_group_state, :string

    GpArticle::Doc.update_all("portal_group_state = 'visible'")
  end
end
