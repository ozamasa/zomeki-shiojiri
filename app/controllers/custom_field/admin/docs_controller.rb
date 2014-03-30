class CustomField::Admin::DocsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include CustomField::Controller::Article

  def pre_dispatch
    return error_auth unless @content = CustomField::Content::Doc.find(params[:content])
    return error_auth unless Core.user.has_priv?(:read, :item => @content.concept)
    @fields = CustomField::Form.where(content_id: @content.id)
    @gparticle = GpArticle::Content::Doc.find(@content.setting_value(:gp_article)) unless @content.setting_value(:gp_article).blank?
  end

  def index
    @items = @content.docs.where(content_id: @content.id).order('created_at DESC').paginate(page: params[:page], per_page: 30)
    _index @items
  end

  def show
    @item = @content.docs.find(params[:id])
    @fields.each do |field|
      @item.fields.where(content_id: @content.id).where(custom_field_doc_id: @item.id).where(custom_field_form_id: field.id).first_or_create
    end
    _show @item
  end

  def new
    @item = @content.docs.new
    @fields.each do |field|
      @item.fields.build(content_id: @content.id, custom_field_doc_id: @item.id, custom_field_form_id: field.id)
    end
  end

  def create
    @item = @content.docs.new(content_id: @content.id, title: params[:item][:title], title_kana: params[:item][:title_kana])
    params[:item][:field].each do |field|
      @item.fields.build(content_id: @content.id, custom_field_doc_id: @item.id, custom_field_form_id: field.first, value: field.last)
    end
    _create @item
  end

  def update
    @item = @content.docs.find(params[:id])
    params[:item][:field].each do |field|
      @item.fields.find_by_content_id_and_custom_field_doc_id_and_custom_field_form_id(@content.id, @item.id, field.first).update_attributes(value: field.last) rescue nil
    end
    @item.update_attributes(title: params[:item][:title], title_kana: params[:item][:title_kana])
    _update @item
  end

  def destroy
    @item = @content.docs.find(params[:id])
    _destroy @item
  end

  def article
    if create_article(params[:id])
      flash[:notice] = "登録処理が完了しました。（#{I18n.l Time.now}）"
    else
      flash.now[:alert] = '登録処理に失敗しました。'
    end

    redirect_to action: :index
  end

end
