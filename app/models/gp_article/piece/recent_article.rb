class GpArticle::Piece::RecentArticle < Cms::Piece

  after_initialize :set_default_settings

  validate :validate_settings

  def validate_settings
    if (lc = in_settings['list_count']).present?
      errors.add(:base, "#{self.class.human_attribute_name :list_count} #{errors.generate_message(:base, :not_a_number)}") unless lc =~ /^[0-9]+$/
    end
  end

  def list_count
    (setting_value(:list_count).presence || 5).to_i
  end

  def list_style
    setting_value(:list_style).to_s
  end

  def date_style
    setting_value(:date_style).to_s
  end

  def more_label
    setting_value(:more_label).to_s
  end

  private

  def set_default_settings
    settings = self.in_settings
    settings[:list_count] = 5 if setting_value(:list_count).nil?
    settings[:list_style] = '@title(@date @group)' if setting_value(:list_style).nil?
    settings[:date_style] = '%Y年%m月%d日 %H時%M分' if setting_value(:date_style).nil?
    settings[:more_label] = '' if setting_value(:list_count).nil?
    self.in_settings = settings
  end
end
