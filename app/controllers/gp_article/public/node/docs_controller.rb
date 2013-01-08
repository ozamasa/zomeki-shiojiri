# encoding: utf-8

require 'will_paginate/array'

class GpArticle::Public::Node::DocsController < Cms::Controller::Public::Base
  skip_filter :render_public_layout, :only => [:file_content]

  def pre_dispatch
    @content = GpArticle::Content::Doc.find_by_id(Page.current_node.content.id)
    return http_error(404) unless @content
  end

  def index
    @docs = @content.public_docs.paginate(page: params[:page], per_page: 20)
    return http_error(404) if @docs.current_page > @docs.total_pages

    @items = @docs.inject([]) do |result, doc|
        date = doc.published_at.try(:strftime, '%Y年%-m月%-d日')

        unless result.empty?
          last_date = result.last[:doc].published_at.try(:strftime, '%Y年%-m月%-d日')
          date = nil if date == last_date
        end

        result.push(date: date, doc: doc)
      end
  end

  def show
    @doc = @content.public_docs.find_by_name(params[:name])
    return http_error(404) unless @doc

    Page.current_item = @doc
    Page.title = @doc.title
  end

  def file_content
    @doc = @content.public_docs.find_by_name(params[:name])
    if (file = Sys::File.where(parent_unid: @doc.unid, name: "#{params[:basename]}.#{params[:extname]}").first)
      send_file file.upload_path, :type => file.mime_type, :filename => file.name, :disposition => 'inline'
    else
      http_error(404)
    end
  end
end
