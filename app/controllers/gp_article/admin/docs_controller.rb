# encoding: utf-8
class GpArticle::Admin::DocsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Sys::Controller::Scaffold::Recognition
  include Sys::Controller::Scaffold::Publication

  def pre_dispatch
    return error_auth unless @content = GpArticle::Content::Doc.find_by_id(params[:content])
    return error_auth unless Core.user.has_priv?(:read, :item => @content.concept)
    return redirect_to(request.env['PATH_INFO']) if params[:reset]

    @category_types = @content.category_types
    @recognition_type = @content.setting_value(:recognition_type)
  end

  def index
    @items = @content.docs.paginate(page: params[:page], per_page: 30)
    _index @items
  end

  def show
    @item = @content.docs.find(params[:id])
    @item.recognition.try(:change_type, @recognition_type)
    _show @item
  end

  def new
    @item = @content.docs.build(target: GpArticle::Doc::TARGET_OPTIONS.first.last)
    @item.in_inquiry = @item.default_inquiry
  end

  def create
    @item = @content.docs.build(params[:item])
    @item.concept = @content.concept
    commit_state = params.keys.detect {|k| k =~ /^commit_/ }
    @item.change_state_by_commit(commit_state)

    if params[:categories].is_a?(Hash)
      @item.category_ids =  params[:categories].values.flatten.reject{|c| c.blank? }.uniq
    end

    _create(@item) do
      @item.fix_tmp_files(params[:_tmp])
      send_recognition_request_mail(@item) if @item.state_recognize?
      publish_by_update(@item) if @item.state_public?
    end
  end

  def update
    @item = @content.docs.find(params[:id])
    @item.attributes = params[:item]
    commit_state = params.keys.detect {|k| k =~ /^commit_/ }
    @item.change_state_by_commit(commit_state)

    if params[:categories].is_a?(Hash)
      @item.category_ids =  params[:categories].values.flatten.reject{|c| c.blank? }.uniq
    end

    _update(@item) do
      send_recognition_request_mail(@item) if @item.state_recognize?
      publish_by_update(@item) if @item.state_public?
      @item.close unless @item.public? # Don't use "state_public?"
    end
  end

  def destroy
    @item = @content.docs.find(params[:id])
    _destroy @item
  end

  def recognize(item)
    _recognize(item) do
      if @item.state == 'recognized'
        send_recognition_success_mail(@item)
      elsif @recognition_type == 'with_admin'
        if item.recognition.recognized_all?(false)
          users = Sys::User.find_managers
          send_recognition_request_mail(@item, users)
        end
      end
    end
  end

  def publish_ruby(item)
    uri = item.public_uri
    uri = (uri =~ /\?/) ? uri.gsub(/\?/, 'index.html.r?') : "#{uri}index.html.r"
    path = "#{item.public_path}.r"
    item.publish_page(render_public_as_string(uri, :site => item.content.site), :path => path, :dependent => :ruby)
  end

  def publish(item)
    item.public_uri = "#{item.public_uri}?doc_id=#{item.id}"
    _publish(item) { publish_ruby(item) }
  end

  def publish_by_update(item)
    item.public_uri = "#{item.public_uri}?doc_id=#{item.id}"
    if item.publish(render_public_as_string(item.public_uri))
      publish_ruby(item)
      flash[:notice] = '公開処理が完了しました。'
    else
      flash[:alert] = '公開処理に失敗しました。'
    end
  end

  protected

  def send_recognition_request_mail(item, users=nil)
    users ||= item.recognizers

    mail_from = Core.user.email

    subject = "#{item.content.name}（#{item.content.site.name}）：承認依頼メール"
    body = <<-EOT
#{Core.user.name}さんより「#{item.title}」についての承認依頼が届きました。
  次の手順により，承認作業を行ってください。

  １．PC用記事のプレビューにより文書を確認
    #{item.preview_uri}
  ２．次のリンクから承認を実施
    #{gp_article_doc_url(content: @content, id: item.id)}
    EOT

    users.each {|user| send_mail(mail_from, user.email, subject, body) }
  end

  def send_recognition_success_mail(item)
    return true unless item.recognition
    return true unless item.recognition.user
    return true if item.recognition.user.email.blank?

    mail_from = Core.user.email
    mail_to = item.recognition.user.email

    subject = "#{item.content.name}（#{item.content.site.name}）：最終承認完了メール"
    body = <<-EOT
「#{item.title}」についての承認が完了しました。
  次のＵＲＬをクリックして公開処理を行ってください。
  #{gp_article_doc_url(content: @content, id: item.id)}
    EOT

    send_mail(mail_from, mail_to, subject, body)
  end
end
