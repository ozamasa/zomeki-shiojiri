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
    @thread_id = params[:id]
    @res_id    = nil
    if params[:id] =~ /\-/
      @thread_id, @res_id = params[:id].split("-")
    end

    @item = bbs_item

    return http_error(404) unless @item
  end

  def new
    return error_auth
  end

  def create
    return error_auth
  end

  def update
    @item = bbs_item
    @item.update_attribute(:state, :public) if params[:commit_public].present?
    @item.update_attribute(:state, :closed) if params[:commit_closed].present?

    render :action => :show
  end

  def destroy
    id = params[:id] =~ /\-/ ? params[:id].gsub(/.*\-/, "") : params[:id]

    uri = "#{@node_uri}delete.xml"
    body = {:_method => "DELETE", :no => id, :password => @admin_password}
    res = Util::Http::Request.post(uri, body)

    if res && res.code == "200"
      flash[:notice] = '削除処理が完了しました。'
      redirect_to url_for(:action => :index)
    else
      flash.now[:notice] = '削除処理に失敗しました。'
      show
      render :action => :show
    end
  end

  def bbs_item
    @thread_id = params[:id]
    @res_id    = nil
    if params[:id] =~ /\-/
      @thread_id, @res_id = params[:id].split("-")
    end

    item = Bbs::Item.new
    item.and :content_id, @content.id
    item.and :parent_id, 0
    item.and :thread_id, @thread_id
    thread = item.find(:first, :order => 'id DESC')

    if @res_id == nil
      return thread
    else
      thread.all_responses.each do |res|
        if @res_id.to_i == res["id"].to_i
          return res
        end
      end
    end
  end
end
