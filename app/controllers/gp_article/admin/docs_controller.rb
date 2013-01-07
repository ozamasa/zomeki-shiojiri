# encoding: utf-8
class GpArticle::Admin::DocsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless @content = GpArticle::Content::Doc.find_by_id(params[:content])
    return error_auth unless Core.user.has_priv?(:read, :item => @content.concept)
    return redirect_to(request.env['PATH_INFO']) if params[:reset]

    @category_types = @content.category_types
  end

  def index
    @items = @content.docs.paginate(page: nil, per_page: 30)
    _index @items
  end

  def show
    @item = @content.docs.find(params[:id])
    _show @item
  end

  def new
    @item = @content.docs.build(target: GpArticle::Doc::TARGET_OPTIONS.first.last)
    @item.in_inquiry = @item.default_inquiry
  end

  def create
    @item = @content.docs.build(params[:item])
    @item.concept = @content.concept

    if params[:categories].is_a?(Hash)
      @item.category_ids =  params[:categories].values.flatten.reject{|c| c.blank? }.uniq
    end

    _create(@item) do
      @item.fix_tmp_files(params[:_tmp])
    end
  end

  def edit
    @item = @content.docs.find(params[:id])
  end

  def update
    @item = @content.docs.find(params[:id])
    @item.attributes = params[:item]
    if params[:categories].is_a?(Hash)
      @item.category_ids =  params[:categories].values.flatten.reject{|c| c.blank? }.uniq
    end
    _update @item
  end

  def destroy
    @item = @content.docs.find(params[:id])
    _destroy @item
  end
end
