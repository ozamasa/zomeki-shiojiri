# encoding: utf-8
class GpArticle::Piece::Doc < Cms::Piece
  DOCS_ORDER_OPTIONS = [['公開日（降順）', 'published_at_desc'], ['公開日（昇順）', 'published_at_asc'], ['ランダム', 'random']]

  default_scope where(model: 'GpArticle::Doc')

  after_initialize :set_default_settings

  validate :validate_settings

  def validate_settings
    if (lc = in_settings['docs_number']).present?
      errors.add(:base, "#{self.class.human_attribute_name :docs_number} #{errors.generate_message(:base, :not_a_number)}") unless lc =~ /^[0-9]+$/
    end
  end

  def docs_number
    (setting_value(:docs_number).presence || 1000).to_i
  end

  def docs_order
    setting_value(:docs_order).to_s
  end

  def doc_style
    setting_value(:doc_style).to_s
  end

  def date_style
    setting_value(:date_style).to_s
  end

  private

  def set_default_settings
    settings = self.in_settings

    settings['date_style'] = '%Y年%m月%d日 %H時%M分' if setting_value(:date_style).nil?
    settings['docs_order'] = DOCS_ORDER_OPTIONS.first.last if setting_value(:docs_order).nil?

    self.in_settings = settings
  end
end
