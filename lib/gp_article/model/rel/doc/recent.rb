module GpArticle::Model::Rel::Doc::Recent

  def rel_gpartcle_content_doc_name
    begin
      c = GpArticle::Content::Doc.find(rel_gp_article_content_doc_id)
      "#{c.site.name}：#{c.name}"
    rescue
    end
  end

  def rel_gpartcle_content_docs
    return [] if rel_gp_article_content_doc_id.blank?

    docs = []
    begin
      c = GpArticle::Content::Doc.find(rel_gp_article_content_doc_id)
      c.public_docs.order("display_published_at DESC").limit(5).each do |doc|
        docs << doc
      end
    rescue
    end
    docs
  end

end
