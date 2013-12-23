# encoding: utf-8
require "rexml/document"
class Bbs::Admin::ItemsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Sys::Controller::Scaffold::Recognition
  include Sys::Controller::Scaffold::Publication

  def pre_dispatch
    #return error_auth unless Core.user.has_auth?(:designer)
    return error_auth unless @content = Bbs::Content::Base.find(params[:content])
    return error_auth unless Core.user.has_priv?(:read, :item => @content.concept)
    #default_url_options[:content] = @content
    return redirect_to(request.env['PATH_INFO']) if params[:reset]

    @node = @content.thread_node
    @node_uri = File.join(Core.site.full_uri, @node.public_uri) if @node

    @admin_password = @content.setting_value(:admin_password)
  end

  def index
    unless @node
      return render(:text => "ディレクトリを作成してください。", :layout => true)
    end

    page  = (params[:page] || 1).to_i
    limit = 10

    item = Bbs::Item.new
    item.and :content_id, @content.id
    item.and :parent_id, 0
    item.page params[:page], limit
    @threads = item.find(:all, :order => 'id DESC')

    total = @threads.total_entries

    @pagination = Util::Html::SimplePagination.new
    @pagination.prev_label = "前のページ"
    @pagination.next_label = "次のページ"
    @pagination.prev_uri   = "?page=#{page-1}" if page > 1
    @pagination.next_uri   = "?page=#{page+1}" if page < (total.to_f / limit.to_f).ceil
  end

  def show
    @item = bbs_item

    return http_error(404) unless @item
  end

  def new
    @item = Bbs::Item.new((params[:item]))
    @item.content_id = @content.id
    @item.state = 'closed'
  end

  def create
    @item = Bbs::Item.new(params[:item])
    @item.content_id = @content.id
    @item.thread_id  = @item.parent_id
    @item.parent_id  = params[:item][:parent_id].to_i

    _create @item
  end

  def update
    @item = bbs_item

    if params[:commit_public].present?
      @item.update_attribute(:state, :public)
      flash[:notice] = '投稿を公開しました。'
    elsif params[:commit_closed].present?
      @item.update_attribute(:state, :closed)
      flash[:notice] = '投稿を非公開にしました。'
    else
      @item.attributes = params[:item]
      _update(@item)
      return
    end

    redirect_to action: :show
  end

  def destroy
    @item = bbs_item

    _destroy @item
  end

  def bbs_item
    @thread_id = params[:id]
    @res_id    = nil
    if params[:id] =~ /\-/
      @thread_id, @res_id = params[:id].split("-")
    end

    return Bbs::Item.find(@res_id.nil? ? @thread_id.to_i : @res_id.to_i)
  end
end
