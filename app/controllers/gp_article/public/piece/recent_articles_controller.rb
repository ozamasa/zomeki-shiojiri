class GpArticle::Public::Piece::RecentArticlesController < Sys::Controller::Public::Base
  def pre_dispatch
    @piece = GpArticle::Piece::RecentArticle.find_by_id(Page.current_piece.id)
    render :text => '' unless @piece
  end

  def index
    @docs = []
    ids = session[:recent_ids]
    ids.reverse.each.with_index do |id, i|
      next if i == 0
      @docs << @piece.content.public_docs.find(id)
      break if i == @piece.list_count
    end
  end
end
