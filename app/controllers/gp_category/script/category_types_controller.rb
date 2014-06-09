# encoding: utf-8
class GpCategory::Script::CategoryTypesController < Cms::Controller::Script::Publication
  def publish
    uri  = "#{@node.public_uri}"
    path = "#{@node.public_path}"
    publish_more(@node, :uri => uri, :path => path, :first => 2, :dependent => :more)

    category_types = if (id = params[:target_id]).present?
                       @node.content.public_category_types.where(id: id)
                     else
                       @node.content.public_category_types
                     end

    category_types.each do |category_type|
      uri  = "#{@node.public_uri}#{category_type.name}/"
      path = "#{@node.public_path}#{category_type.name}/"
      publish_page(category_type, :uri => "#{uri}index.rss", :path => "#{path}index.rss", :dependent => "#{category_type.name}/rss")
      publish_page(category_type, :uri => "#{uri}index.atom", :path => "#{path}index.atom", :dependent => "#{category_type.name}/atom")
      publish_more(category_type, :uri => uri, :path => path, :dependent =>"#{category_type.name}/more")

      if (child_id = params[:target_child_id]).present?
        category_type.public_categories.where(id: child_id).each do |category|
          publish_category(category, follow_children: false)
        end
      else
        category_type.public_root_categories.each do |category|
          publish_category(category)
        end
      end
    end

    render :text => "OK"
  end

  private

  def category_feed_pieces(item)
    layout = item.layout || @node.layout
    return nil unless layout
    
    feed_piece_ids = layout.pieces.select{|piece| piece.model == 'GpCategory::Feed'}.map(&:id)
    GpCategory::Piece::Feed.where(:id => feed_piece_ids).all
  end

  def publish_category(cat, follow_children: true)
    cat_path = "#{cat.category_type.name}/#{cat.path_from_root_category}/"
    uri = "#{@node.public_uri}#{cat_path}"
    path = "#{@node.public_path}#{cat_path}"
    smart_phone_path = "#{@node.public_smart_phone_path}#{cat_path}"

    publish_page(cat.category_type, :uri => "#{uri}index.rss", :path => "#{path}index.rss", :dependent => "#{cat_path}rss")
    publish_page(cat.category_type, :uri => "#{uri}index.atom", :path => "#{path}index.atom", :dependent => "#{cat_path}atom")
    publish_more(cat.category_type, :uri => uri, :path => path, :dependent => "#{cat_path}more")
    publish_more(cat.category_type, :uri => uri, :path => smart_phone_path, :dependent => "#{cat_path}more_smart_phone", :smart_phone => true)
    publish_more(cat.category_type, :uri => uri, :path => path, :file => 'more', :dependent => "#{cat_path}more_docs")
    publish_more(cat.category_type, :uri => uri, :path => smart_phone_path, :file => 'more', :dependent => "#{cat_path}more_docs_smart_phone", :smart_phone => true)

    if feed_pieces = category_feed_pieces(cat)
      feed_pieces.each do |piece|
        rss = piece.public_feed_uri('rss')
        atom = piece.public_feed_uri('atom')
        publish_page(cat.category_type, :uri => "#{uri}#{rss}", :path => "#{path}#{rss}", :dependent => "#{cat_path}#{rss}")
        publish_page(cat.category_type, :uri => "#{uri}#{atom}", :path => "#{path}#{atom}", :dependent => "#{cat_path}#{atom}")
      end
    end

    info_log %Q!OK: Published to "#{path}"!

    return unless follow_children

    cat.public_children.each do |c|
      publish_category(c)
    end
  end
end
