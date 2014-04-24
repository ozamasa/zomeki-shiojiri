class Rank::Total < ActiveRecord::Base
  include Sys::Model::Base

  # Content
  belongs_to :content, foreign_key: :content_id, class_name: 'Rank::Content::Rank'
  validates_presence_of :content_id

  def page_title
    self[:page_title].gsub(' | ' + content.site.name, '')
  end

  def image_url
    url = ''
    Cms::Node.where(state: 'public', model: 'GpArticle::Doc').each do |node|
      doc = node.content.public_docs.find_by_name(page_path.split('/')[-1])
      if doc
        unless (img_tags = Nokogiri::HTML.parse(doc.body).css('img[src^="file_contents/"]')).empty?
          filename = ::File.basename(img_tags.first.attributes['src'].value) rescue nil
          url = "#{doc.public_uri(without_filename: true)}file_contents/#{filename}" unless filename.blank?
        end
        break unless url.blank?
      end
    end
    return url
  end
end
