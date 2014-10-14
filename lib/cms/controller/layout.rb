# encoding: utf-8
module Cms::Controller::Layout
  @no_cache    = nil

  def render_public_as_string(path, options = {})
    Core.publish = true unless options[:preview]
    mode = Core.set_mode('preview')

    qp = {}
    if path =~ /\?/
      qp   = Rack::Utils.parse_query(path.gsub(/.*\?/, ''))
      path = path.gsub(/\?.*/, '')
    end

    Page.initialize
    Page.site   = options[:site] || Core.site
    Page.uri    = path
    Page.mobile = options[:mobile]

    begin
      node = Core.search_node(path)
      env  = {}
      opt  = _routes.recognize_path(node, env)
      opt  = qp.merge(opt)
      ctl  = opt[:controller]
      act  = opt[:action]

      opt[:authenticity_token] = params[:authenticity_token] if params[:authenticity_token]
      body = render_component_into_view :controller => ctl, :action => act, :params => opt,
                                        :jpmobile => options[:jpmobile]

      error_log(body) if Page.error
    rescue => e
      error_log(e.message)
      Page.error = 404
    end

    error = Page.error
    Page.initialize
    Page.site = options[:site] || Core.site
    Page.uri  = path

    Core.set_mode(mode)

    return error ? nil : body
  end

  def render_public_layout
    if Rails.env.to_s == 'production' && !@no_cache
      # enable cache
      headers.delete("Cache-Control")
      # no cache
      #response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      #response.headers["Pragma"] = "no-cache"
      #response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end

    Page.current_item = Page.current_node unless Page.current_item

    return true if @performed_redirect
    return true if params[:format] && params[:format] != 'html'
    return true if Page.error

    ## content
    Page.content = response.body
    self.response_body = nil

    ## concept
    concepts = Cms::Lib::Layout.inhertited_concepts

    ## layout
    if Core.set_mode('preview') && params[:layout_id]
      Page.layout = Cms::Layout.find(params[:layout_id])
    elsif layout = Cms::Lib::Layout.inhertited_layout
      Page.layout    = layout.clone
      Page.layout.id = layout.id
    else
      Page.layout = Cms::Layout.new({
        :body             => '[[content]]',
        :mobile_body      => '[[content]]',
        :smart_phone_body => '[[content]]'
      })
    end

    if params[:filename_base] =~ /^more($|_)/i &&
       Page.current_item.respond_to?(:more_layout) && Page.current_item.more_layout
      Page.layout = Page.current_item.more_layout
    end

    body = Page.layout.body_tag(request).clone.to_s

    ## render the piece
    Cms::Lib::Layout.find_design_pieces(body, concepts).each do |name, item|
      Page.current_piece = item
      begin
        next if item.content_id && !item.content
        mnames= item.model.underscore.pluralize.split('/')

        data = render_component_into_view :params => params,
          :controller => mnames[0] + '/public/piece/' + mnames[1], :action => 'index'
        if data =~ /^<html/ && Rails.env.to_s == 'production'
          # component error
        else
          body.gsub!("[[piece/#{name}]]", piece_container_html(item, data))
        end
      rescue => e
        error_log(e.message)
      end
    end

    ## render the content
    body.gsub!("[[content]]", Page.content)

    body.gsub!("[[title]]",         Page.current_item.title) rescue nil
    body.gsub!("[[body]]",          Page.current_item.body) rescue nil
    body.gsub!("[[created_at]]",    Page.current_item.created_at.strftime(Page.current_item.content.setting_value(:date_style))) rescue nil
    body.gsub!("[[published_at]]",  Page.current_item.published_at.strftime(Page.current_item.content.setting_value(:date_style))) rescue nil

    begin
      Page.current_item.content.custom_field_content.forms.each do |custom_field_form|
        cf_st = "[[#{custom_field_form.name}=>]]"
        cf_ed = "[[<=#{custom_field_form.name}]]"
        id_st = body.index(cf_st) || 0
        id_ed = body.index(cf_ed) || 0

        if id_st > 0 && id_ed > 0
          if Page.current_item.try(custom_field_form.name).blank?
            body[id_st..(id_ed + cf_ed.length + 1)] = '' rescue nil
          end
        end

        body.gsub!("#{cf_st}", '')
        body.gsub!("#{cf_ed}", '')
        body.gsub!("[[#{custom_field_form.name}]]", "#{Page.current_item.try(custom_field_form.name)}")
      end
    rescue
    end

    begin
      category = ''
      Page.current_item.categories.each do |c|
        category += "<span class='category-#{c.name}'>"
        category += ActionController::Base.helpers.link_to("#{c.category_type.try(:title)}/#{c.ancestors.map(&:title).join('/')}", c.public_uri)
        category += "</span>\n"
      end
      body.gsub!("[[category]]", category) rescue nil
    rescue
    end

    begin
      view = ActionView::Base.new(Rails.configuration.paths['app/views'])
      maps = view.render(partial: 'cms/public/_partial/maps/view', locals: {item: Page.current_item})
      body.gsub!("[[map]]", maps) rescue nil
    rescue
    end

    begin
      rel_docs = ''
      Page.current_item.rel_docs.each do |d|
        rel_docs += "<li><span class='title'>"
        rel_docs += ActionController::Base.helpers.link_to(d.title, d.public_uri)
        rel_docs += "</span></li>\n"
      end
      rel_doc_tag = ''
      rel_doc_tag = "\n<div class='rels'>\n<h2>関連記事</h2>\n<ul>\n#{rel_docs}</ul>\n</div>\n" unless rel_docs.blank?
      body.gsub!("[[rel_doc]]", rel_doc_tag) rescue nil
    rescue
    end

    begin
      image = ''
      file  = Sys::File.where(parent_unid: Page.current_item.try(:unid)).first
      image = "<img src='file_contents/#{file.name}' alt='#{file.title}' title='#{file.title}'/>" if file
      body.gsub!("[[image]]", image)
    rescue
    end

    ## render the data/text
    Cms::Lib::Layout.find_data_texts(body, concepts).each do |name, item|
      data = item.body
      body.gsub!("[[text/#{name}]]", data)
    end

    ## render the data/file
    Cms::Lib::Layout.find_data_files(body, concepts).each do |name, item|
      data = ''
      if item.image_file?
        data = '<img src="' + item.public_uri + '" alt="' + item.title + '" title="' + item.title + '" />'
      else
        data = '<a href="' + item.public_uri + '" class="' + item.css_class + '" target="_blank">' + item.united_name + '</a>'
      end
      body.gsub!("[[file/#{name}]]", data)
    end

    ## render the emoji
    require 'jpmobile' #v0.0.4
    body.gsub!(/\[\[emoji\/([0-9a-zA-Z\._-]+)\]\]/) do |m|
      name = m.gsub(/\[\[emoji\/([0-9a-zA-Z\._-]+)\]\]/, '\1')
      Cms::Lib::Mobile::Emoji.convert(name, request.mobile)
    end

    ## removes the unknown components
    body.gsub!(/\[\[[a-z]+\/[^\]]+\]\]/, '') #if Core.mode.to_s != 'preview'

    ## mobile
    if request.mobile?
      begin
        require 'tamtam'
        body = TamTam.inline(
          :css  => Page.layout.tamtam_css(request),
          :body => body
        )
      rescue => e #InvalidStyleException
        error_log(e.message)
      end

      case request.mobile
      when Jpmobile::Mobile::Docomo
        # for docomo
        headers["Content-Type"] = "application/xhtml+xml; charset=utf-8"
      when Jpmobile::Mobile::Au
        # for au
      when Jpmobile::Mobile::Softbank
        # for SoftBank
      when Jpmobile::Mobile::Willcom
        # for Willcom
      else
        # for PC
      end
    end

    ## ruby(kana)
    if Page.ruby
      body = Cms::Lib::Navi::Kana.convert(body, Page.site.id)
    end

#    ## for preview
#    if Core.mode.to_s == 'preview'
#      body.gsub!(/<a .*?href="\/[^_].*?>/i) do |m|
#        prefix = "/_preview/#{format('%08d', Page.site.id)}"
#        m.gsub(/(<a .*?href=")(\/[^_].*?>)/i, '\1' + prefix + '\2')
#      end
#    end

    body = convert_ssl_uri(body)

    body = last_convert_body(body)

    ## render the true layout
    render :text => (body ? body.force_encoding('UTF-8') : ''), :layout => 'layouts/public/base'
  end

  def convert_ssl_uri(body)
    return body if Core.request_uri =~ /^\/_preview\//
    return body unless Sys::Setting.use_common_ssl?

    # フォームへのリンクをhttpsに、その他はhttpに変換
    form_nodes = Cms::Node.where(model: 'Survey::Form', site_id: Page.site.id)
    form_nodes = form_nodes.select {|f| Survey::Content::Form.find_by_id(f.content.id).use_common_ssl? }
    form_nodes = form_nodes.map{|f| f.public_uri }
    unless form_nodes.blank?
      body_doc = Nokogiri::HTML.fragment(body)
      ssl_uri = Page.site.full_ssl_uri.sub(/\/\z/, '')
      body_doc.css(*form_nodes.map{|n| %Q!a[href^="#{n}"]! }).each do |a_tag|
        a_tag.set_attribute('href', "#{ssl_uri}#{a_tag.attribute('href')}")
      end
      body_doc.css(*form_nodes.map{|n| %Q!form[action^="#{n}"]! }).each do |form_tag|
        form_tag.set_attribute('action', "#{ssl_uri}#{form_tag.attribute('action')}")
      end

      site_full_uri = Page.site.full_uri.sub(/\/\z/, '')
      if Page.current_node.model == 'Survey::Form'
        body_doc.css('a[href^="/"]').each do |a_tag|
          href = a_tag.attribute('href').to_s
          a_tag.set_attribute('href', "#{site_full_uri}#{href}") unless href =~ Regexp.new("\\A#{form_nodes.join('|')}")
        end
        body_doc.css('link[href^="/"]').each do |link_tag|
          href = link_tag.attribute('href').to_s
          link_tag.set_attribute('href', "#{ssl_uri}#{href}") if href =~ /^\/_(layouts|themes|file|emfiles)/
        end
        body_doc.css('img[src^="/"]').each do |src_tag|
          src = src_tag.attribute('src').to_s
          src_tag.set_attribute('src', "#{ssl_uri}#{src}") if src =~ /^\/_(layouts|themes|file|emfiles)/
        end
      end
      body = body_doc.to_s
    end

    return body
  end

  def last_convert_body(body)
    body
  end

  def piece_container_html(piece, body)
    return "" if body.blank?

    title = piece.view_title
    return body if piece.model == 'Cms::Free' && title.blank?

    html  = %Q(<div#{piece.css_attributes}>\n)
    html += %Q(<div class="pieceContainer">\n)
    html += %Q(<div class="pieceHeader"><h2>#{title}</h2></div>\n) if !title.blank?
    html += %Q(<div class="pieceBody">#{body}</div>\n)
    html += %Q(</div>\n)
    html += %Q(<!-- end .piece --></div>\n)
    html
  end
end
