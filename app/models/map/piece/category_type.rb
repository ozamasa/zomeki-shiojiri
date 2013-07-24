# encoding: utf-8
class Map::Piece::CategoryType < Cms::Piece
  default_scope where(model: 'Map::CategoryType')

  def content
    Map::Content::Marker.find(super)
  end

  def category_types
    content.category_types
  end

  def category_types_for_option
    category_types.map {|ct| [ct.title, ct.id] }
  end

  def visible_category_type_ids
    return [] unless setting_value(:category_type_ids).is_a?(String)
    category_type_ids = YAML.load(setting_value(:category_type_ids))
    category_type_ids.is_a?(Array) ? category_type_ids : []
  end

  def visible_category_types
    category_types.where(id: visible_category_type_ids)
  end
end
