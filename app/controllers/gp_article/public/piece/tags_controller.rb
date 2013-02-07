# encoding: utf-8
class GpArticle::Public::Piece::TagsController < Sys::Controller::Public::Base
  def pre_dispatch
    @piece = GpArticle::Piece::Tag.find_by_id(Page.current_piece.id)
    render :text => '' unless @piece
  end

  def index
    @tags = @piece.content.tags
    render :text => '' if @tags.empty?
  end
end
