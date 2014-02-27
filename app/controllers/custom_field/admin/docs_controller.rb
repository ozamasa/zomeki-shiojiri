class CustomField::Admin::DocsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless @content = CustomField::Content::Doc.find(params[:content])
    return error_auth unless Core.user.has_priv?(:read, :item => @content.concept)
    @fields = CustomField::Form.where(content_id: @content.id)
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
      @item.fields.new(content_id: @content.id, custom_field_doc_id: @item.id, custom_field_form_id: field.first, value: field.last)
    end
    _create @item
  end

  def update
    @item = @content.docs.find(params[:id])
    @item.update_attributes(title: params[:item][:title], title_kana: params[:item][:title_kana])
    params[:item][:field].each do |field|
      @item.fields.find_by_content_id_and_custom_field_doc_id_and_custom_field_form_id(@content.id, @item.id, field.first).update_attributes(value: field.last) rescue nil
    end
    _update @item
  end

  def destroy
    @item = @content.docs.find(params[:id])
    _destroy @item
  end

  def article
    content_id = @content.setting_value(:gp_article)
    return if @content.setting_value(:gp_article).blank?

    @item = @content.docs.find(params[:id])
    body = @content.setting_value(:doc_style)

    @fields.each do |field|
      pattern = "@#{field.name}@"
      value   = @item.fields.find_by_content_id_and_custom_field_form_id(@content.id, field.id).value.to_s
      body.gsub!(pattern, value)
    end

    doc = nil
    unless @item.gp_article_doc_id.blank?
      doc = GpArticle::Doc.find(@item.gp_article_doc_id)
    else
      doc = GpArticle::Doc.new(content_id: content_id)
    end

    doc.title      = @item.title
    doc.title_kana = @item.title_kana
    doc.body       = body
    doc.save

    @item.update_attributes(gp_article_doc_id: doc.id)

    redirect_to :action => :index
  end

end
