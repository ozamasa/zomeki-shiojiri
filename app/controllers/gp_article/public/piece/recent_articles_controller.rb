class GpArticle::Public::Piece::RecentArticlesController < Sys::Controller::Public::Base
  def pre_dispatch
    @piece = GpArticle::Piece::RecentArticle.find_by_id(Page.current_piece.id)
    render :text => '' unless @piece
  end

  def index
    @docs = []
    ids = session[:recent_ids]
    i = 0
    ids.reverse.each do |id|
      next if id == Page.current_item.id
      begin
        @docs << @piece.content.public_docs.find(id)
        i += 1
      rescue
      end
      break if i >= @piece.list_count
    end
  end
end
