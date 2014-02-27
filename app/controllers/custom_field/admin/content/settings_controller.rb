# encoding: utf-8
class CustomField::Admin::Content::SettingsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:designer)
    return error_auth unless @content = CustomField::Content::Doc.find(params[:content])
    return error_auth unless @content.editable?
  end

  def index
    @items = CustomField::Content::Setting.configs(@content)
    _index @items
  end

  def show
    @item = CustomField::Content::Setting.config(@content, params[:id])

    if @item.name == 'doc_style'
      lower_text = ''
      CustomField::Form.where(content_id: @content.id).each do |field|
        lower_text += "<p><strong>#{field.title}</strong>: @#{field.name}@ "
      end
      @item.config[:lower_text] = lower_text.html_safe
    end

    _show @item
  end

  def update
    @item = CustomField::Content::Setting.config(@content, params[:id])
    @item.value = params[:item][:value]
    _update @item
  end
end
