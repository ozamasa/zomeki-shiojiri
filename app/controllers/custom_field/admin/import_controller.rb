# encoding: utf-8
class CustomField::Admin::ImportController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless @content = CustomField::Content::Doc.find(params[:content])
    return error_auth unless Core.user.has_priv?(:read, :item => @content.concept)
  end

  def index
  end

  def import
    if !params[:item] || !params[:item][:file]
      return redirect_to(:action => :index)
    end

    @results = [0, 0, 0]

    require 'csv'
    require 'nkf'
    csv = NKF.nkf('-w', params[:item][:file].read)

    ActiveRecord::Base.transaction do
      CSV.parse(csv, headers: true, header_converters: :symbol) do |data|

        no         = data[0]
        title      = data[1]
        title_kana = data[2]

        next if title.blank?

        doc = CustomField::Doc.find_by_title(title) || CustomField::Doc.new(content_id: @content.id, title: title, title_kana: title_kana)
        status = doc.new_record? ? 0 : 1
        status = 2 unless doc.save

        CustomField::Form.where(content_id: @content.id).each_with_index do |form, i|
          field = doc.fields.where(content_id: @content.id).where(custom_field_doc_id: doc.id).where(custom_field_form_id: form.id).first_or_create
          field.value = data[3 + i]
          field.save
        end

        @results[status] += 1
      end
    end

    Core.messages << "インポート： "
    Core.messages << "-- 追加 #{@results[0]}件"
    Core.messages << "-- 更新 #{@results[1]}件"
    Core.messages << "-- 失敗 #{@results[2]}件"

    flash[:notice] = "インポートが終了しました。<br />#{Core.messages.join('<br />')}".html_safe
    return redirect_to(:action => :index)
  end

end
