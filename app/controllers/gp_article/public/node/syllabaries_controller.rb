class GpArticle::Public::Node::SyllabariesController < Cms::Controller::Public::Base

  def pre_dispatch
    @content = GpArticle::Content::Doc.find_by_id(Page.current_node.content.id)
    return http_error(404) unless @content
  end

  def index
    @docs = @content.public_docs.order(:title_column, :title_kana)
  end

end
