class GpCategory::Public::Node::BaseController < Cms::Controller::Public::Base
  include GpArticle::Controller::Feed

  def pre_dispatch
    @content = GpCategory::Content::CategoryType.find_by_id(Page.current_node.content.id)
    return http_error(404) unless @content
    @file = params[:file] unless params[:file] == 'index'
    @more = (@file =~ /^more($|_)/)
    @more_suffix = @file.split('_', 2)[1] if @more
  end

  private

  def find_public_docs_with_category_id(category_id)
    GpArticle::Doc.all_with_content_and_criteria(nil, category_id: category_id).except(:order).mobile(::Page.mobile?).public
  end
end
