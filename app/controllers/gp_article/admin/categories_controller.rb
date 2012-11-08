# encoding: utf-8
class GpArticle::Admin::CategoriesController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless @content = GpArticle::Content::Doc.find_by_id(params[:content])
    return error_auth unless Core.user.has_priv?(:read, :item => @content.concept)
    return redirect_to(request.env['PATH_INFO']) if params[:reset]

    return error_auth unless @category_type = GpArticle::CategoryType.find_by_id(params[:category_type_id])
    @parent_category = @category_type.categories.find_by_id(params[:category_id])
  end

  def index
    if @parent_category
      @items = @parent_category.children.paginate(page: params[:page], per_page: 20)
    else
      @items = @category_type.categories.where(content_id: @content.id, parent_id: nil).paginate(page: params[:page], per_page: 20)
    end
  end

  def show
    @item = @category_type.categories.find(params[:id])
    _show @item
  end

  def new
    @item = @category_type.categories.build(state: 'public', sort_no: 1)
  end

  def create
    @item = @category_type.categories.build(params[:item])
    @item.content = @content
    @item.parent = @parent_category
    @item.level_no = @parent_category.try(:level_no).to_i + 1
    _create @item
  end

  def edit
    @item = @category_type.categories.find(params[:id])
  end

  def update
    @item = @category_type.categories.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def destroy
    @item = @category_type.categories.find(params[:id])
    _destroy @item
  end
end
