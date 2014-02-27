# encoding: utf-8
class CustomField::Content::Setting < Cms::ContentSetting
  set_config :gp_article, name: '汎用記事コンテンツ', form_type: :select
  set_config :doc_style, name: '記事表示スタイル', form_type: :text

  def config_options
    case name
    when 'gp_article'
      return Core.site.contents.find_all_by_model('GpArticle::Doc').map{|c| [c.name, c.id.to_s]}
    end
    super
  end

  def value_name
    if !value.blank?
      case name
      when 'gp_article'
        content = Cms::Content.find_by_id(value)
        return content.name if content
      end
    end
    super
  end

end
