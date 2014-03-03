module CustomField::Controller::Article

  def create_article(id)
    return true unless @gparticle

    @item = @content.docs.find(id)
    body = @content.setting_value(:doc_style)

    @fields.each do |field|
      pattern = "@#{field.name}@"
      value   = @item.fields.find_by_content_id_and_custom_field_form_id(@content.id, field.id).value.to_s
      body.gsub!(pattern, value)
    end

    @doc = @gparticle.docs.find(@item.gp_article_doc_id) rescue nil
    @doc = @gparticle.docs.build(content_id: @gparticle.id) unless @doc
    id = nil
    if @doc
      @doc.title        = @item.title
      @doc.title_kana   = @item.title_kana
      @doc.body         = body
      @doc.mobile_title = ''
      @doc.mobile_body  = ''
      @doc.state        = 'draft'

      rtn = @doc.save
      id  = @doc.id
    end
    @item.update_attributes(gp_article_doc_id: id)

    return rtn || true
  end

end
