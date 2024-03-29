# encoding: utf-8
module GpArticle::Controller::Feed
  def render_feed(docs)
    if ['rss', 'atom', 'json'].index(params[:format])
      @site_uri    = Page.site.full_uri
      @node_uri    = @site_uri.gsub(/\/$/, '') + Page.current_node.public_uri
      @req_uri     = @site_uri.gsub(/\/$/, '') + Page.uri
      @feed_name   = "#{Page.title} | #{Page.site.name}"

      data = eval("to_#{params[:format]}(docs)")
      if params[:format].in?('json')
        return render text: JSON.generate(data)
      else
        return render xml: unescape(data), layout: false
      end
    end
    return false
  end

  def unescape(xml)
    xml = xml.to_s
    #xml = CGI.unescapeHTML(xml)
    #xml = xml.gsub(/&amp;/, '&')
    xml.gsub(/&#(?:(\d*?)|(?:[xX]([0-9a-fA-F]{4})));/) { [$1.nil? ? $2.to_i(16) : $1.to_i].pack('U') }
  end

  def strimwidth(str, size, options = {})
    suffix = options[:suffix] || '..'
    str    = str.sub!(/<[^<>]*>/,"") while /<[^<>]*>/ =~ str
    chars  = str.split(//u)
    return chars.size <= size ? str : chars.slice(0, size).join('') + suffix
  end

  def to_json(docs)
    item = []
    docs.each do |doc|
      next unless doc.display_published_at
      hash = {}
      hash[:id]           = doc.id
      hash[:title]        = doc.title
      hash[:link]         = doc.public_full_uri
      hash[:description]  = strimwidth(doc.body, 500)
      hash[:pubDate]      = doc.display_published_at.rfc822

      if doc.content.custom_field_content
        doc.content.custom_field_content.forms.each do |custom_field_form|
          hash[custom_field_form.name] = doc.try(custom_field_form.name).to_s
        end
      end

      if doc.content.setting_value(:rel_gp_article_doc_id)
        pdoc = GpArticle::Doc.find(doc.content.setting_value(:rel_gp_article_doc_id))
        hash[:parent_id]    = pdoc.id
        hash[:parent_title] = pdoc.title
        hash[:parent_link]  = pdoc.public_full_uri
      end

      file = Sys::File.where(parent_unid: doc.unid).first
      image = "#{doc.public_full_uri}file_contents/#{file.name}" if file
      hash[:image] = image || ""

      hashma = []
      doc.maps.each do |map|
        map.markers.each do |m|
          hashm = {}
          hashm[:id]   = m.id
          hashm[:name] = m.name
          hashm[:lat]  = m.lat
          hashm[:lng]  = m.lng
          hashma << hashm
        end
      end
      hash[:map] = hashma

      hashmd = []
      doc.rel_docs.each do |d|
        hashd = {}
        hashd[:id]    = d.id
        hashd[:title] = d.title
        hashd[:link]  = d.public_full_uri
        hashmd << hashd
      end
      hash[:rel] = hashmd

      hashmc = []
      doc.categories.each do |c|
        hashc = {}
        hashc[:id]     = c.id
        hashc[:term]   = c.name
        hashc[:title]  = c.title
        hashc[:scheme] = c.public_full_uri
        hashc[:label]  = "カテゴリ/#{c.category_type.try(:title)}/#{c.ancestors.map(&:title).join('/')}"
        hashmc << hashc
      end
      hash[:category] = hashmc

      hashmr = []
      doc.rel_gpartcle_content_docs.each do |r|
        hashr = {}
        hashr[:id]    = r.id
        hashr[:title] = r.title
        hashr[:link]  = r.public_full_uri
        hashr[:description]  = strimwidth(r.body, 500)
        hashr[:pubDate]      = r.display_published_at.rfc822
        hashmr << hashr
      end
      hash[:recent] = hashmr

      item << hash
    end
    item
  end

  def to_rss(docs)
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!
    xml.rss('version' => '2.0') do

      xml.channel do
        xml.title       @feed_name
        xml.link        @req_uri
        xml.language    "ja"
        xml.description Page.title

        docs.each do |doc|
          next unless doc.display_published_at
          xml.item do
            xml.title        doc.title
            xml.link         doc.public_full_uri
            xml.description  strimwidth(doc.body, 500)
            xml.pubDate      doc.display_published_at.rfc822
            doc.categories.each do |category|
              xml.category   category.title
            end
          end
        end #docs

      end #channel
    end #xml
  end

  def to_atom(docs)
    _feed_updated = lambda do |entries, updated_at|
      entry = entries.max_by {|entry| eval("entry.#{updated_at}.to_i") }
      eval("entry.#{updated_at}") rescue Time.now
    end

    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct! :xml, :version => 1.0, :encoding => 'UTF-8'
    xml.feed 'xmlns' => 'http://www.w3.org/2005/Atom' do

      xml.id      "tag:#{Page.site.domain},#{Page.site.created_at.strftime('%Y')}:#{Page.current_node.public_uri}"
      xml.title   @feed_name
      xml.updated _feed_updated.call(docs, :display_published_at).strftime('%Y-%m-%dT%H:%M:%S%z').sub(/([0-9][0-9])$/, ':\1')
      xml.link    :rel => 'alternate', :href => @node_uri
      xml.link    :rel => 'self', :href => @req_uri, :type => 'application/atom+xml', :title => @feed_name

      docs.each do |doc|
        next unless doc.display_published_at

        xml.entry do
          xml.id      "tag:#{Page.site.domain},#{doc.created_at.strftime('%Y')}:#{doc.public_uri}"
          xml.title   doc.title
          xml.updated doc.display_published_at.strftime('%Y-%m-%dT%H:%M:%S%z').sub(/([0-9][0-9])$/, ':\1') #.rfc822
          xml.summary(:type => 'html') do |p|
            p.cdata! strimwidth(doc.body, 500)
          end
          xml.link    :rel => 'alternate', :href => doc.public_full_uri

          doc.categories.each do |c|
            xml.category :term => c.name, :scheme => c.public_full_uri,
              :label => "カテゴリ/#{c.category_type.try(:title)}/#{c.ancestors.map(&:title).join('/')}"
          end

          if doc.event_state == 'visible' && doc.event_started_on && node = doc.content.try(:gp_calendar_content_event).try(:public_node)
            xml.category :term => 'event', :scheme => node.public_full_uri,
              :label => "イベント/#{doc.event_started_on.strftime('%Y-%m-%dT%H:%M:%S%z').sub(/([0-9][0-9])$/, ':\1')}"
          end

          doc.inquiries.each do |inquiry|
            if inquiry.group.present? || inquiry.email.present?
              xml.author do |auth|
                name  = inquiry.group.try(:full_name) || ''
                name += "　#{inquiry.charge}" if inquiry.charge.present?
                auth.name  "#{name}" if name.present?
                auth.email "#{inquiry.email}" if inquiry.email.present?
              end
            end
          end

          if node = doc.content.try(:tag_content_tag).try(:tag_node)
            doc.tags.each do |t|
              xml.link :rel => 'tag', :href => "#{node.public_full_uri}#{CGI::escape(t.word)}", :type => 'text/xhtml'
            end
          end

          doc.rel_docs.each do |d|
            xml.link :rel => 'related', :href => "#{d.public_full_uri}", :type => 'text/xhtml'
          end

        end #entry
      end #docs
    end #feed
  end
end