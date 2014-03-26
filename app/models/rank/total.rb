class Rank::Total < ActiveRecord::Base
  include Sys::Model::Base

  # Content
  belongs_to :content, foreign_key: :content_id, class_name: 'Rank::Content::Rank'
  validates_presence_of :content_id

  def page_title
    self[:page_title].gsub(' | ' + Core.site.name, '')
  end

  def image_tag
    Cms::Node.where(state: 'public', model: 'GpArticle::Doc').each do |node|
      doc = node.content.public_docs.find_by_name(page_path.split('/')[-1])
      if doc
        tag = ''
        image_file = doc.image_files.detect{|f| f.name == doc.list_image } || doc.image_files.first if doc.list_image.present?
        doc_image = if image_file
                      tag = ActionController::Base.helpers.image_tag("#{doc.public_uri(without_filename: true)}file_contents/#{image_file.name}")
                    else
                      unless (img_tags = Nokogiri::HTML.parse(doc.body).css('img[src^="file_contents/"]')).empty?
                        filename = File.basename(img_tags.first.attributes['src'].value)
                        tag = ActionController::Base.helpers.image_tag("#{doc.public_uri(without_filename: true)}file_contents/#{filename}")
                      end
                    end
        return tag
      end
    end
  end
end
