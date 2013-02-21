# encoding: utf-8
class GpArticle::Admin::Content::SettingsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:designer)
    return error_auth unless @content = GpArticle::Content::Doc.find(params[:content])
    return error_auth unless @content.editable?
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    @items = GpArticle::Content::Setting.configs(@content)
    _index @items
  end

  def show
    @item = GpArticle::Content::Setting.config(@content, params[:id])
    _show @item
  end

  def edit
    @item = GpArticle::Content::Setting.config(@content, params[:id])
    @item.value = YAML.load(@item.value.presence || '[]') if @item.form_type == :check_boxes
  end

  def update
    @item = GpArticle::Content::Setting.config(@content, params[:id])
    @item.value = params[:item][:value]
    @item.value = YAML.dump(@item.value.is_a?(Hash) ? @item.value.keys : []) if @item.form_type == :check_boxes

    if @item.name == 'gp_category_content_category_type_id'
      extra_values = @item.extra_values

      extra_values[:category_type_ids] = (params[:category_types] || []).map {|ct| ct.to_i }
      extra_values[:visible_category_type_ids] = (params[:visible_category_types] || []).map {|ct| ct.to_i }
      extra_values[:default_category_type_id] = params[:default_category_type].to_i
      extra_values[:default_category_id] = params[:default_category].to_i

      @item.extra_values = extra_values
    end

    _update @item
  end
end
