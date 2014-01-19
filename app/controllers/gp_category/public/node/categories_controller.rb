# encoding: utf-8
class GpCategory::Public::Node::CategoriesController < Cms::Controller::Public::Base
  include GpArticle::Controller::Feed

  def pre_dispatch
    @content = GpCategory::Content::CategoryType.find_by_id(Page.current_node.content.id)
    return http_error(404) unless @content
    @more = (params[:file] == 'more')
  end

  def show
    category_type = @content.category_types.find_by_name(params[:category_type_name])
    @category = category_type.find_category_by_path_from_root_category(params[:category_names])
    return http_error(404) unless @category.try(:public?)

    if params[:format].in?('rss', 'atom')
      docs = @category.public_docs.order('display_published_at DESC, published_at DESC')
      docs = docs.display_published_after(@content.feed_docs_period.to_i.days.ago) if @content.feed_docs_period.present?
      docs = docs.paginate(page: params[:page], per_page: @content.feed_docs_number)
      return render_feed(docs)
    end

    Page.current_item = @category
    Page.title = @category.title

    per_page = (@more ? 30 : @content.category_docs_number)

    if (template = category_type.template)
      rendered = template.body.gsub(/\[\[module\/([\w-]+)\]\]/) do |matched|
          tm = @content.template_modules.find_by_name($1)
          next unless tm

          category_ids = case tm.module_type
                         when 'docs_1'
                           [@category.id]
                         when 'docs_2'
                           @category.public_descendants.map(&:id)
                         else
                           []
                         end
          docs = find_public_docs_with_category_ids(category_ids).limit(tm.num_docs).order('display_published_at DESC, published_at DESC')

          docs = docs.where(tm.module_type_feature, true) if docs.columns.detect{|c| c.name == tm.module_type_feature }

          view_context.try(tm.module_type, category: @category, template_module: tm, docs: docs)
        end

      render text: rendered
    else
      @docs = @category.public_docs.order('display_published_at DESC, published_at DESC').paginate(page: params[:page], per_page: per_page)
      return http_error(404) if @docs.current_page > @docs.total_pages

      if Page.mobile?
        render :show_mobile
      else
        if @more
          render 'more'
        else
          if (style = @content.category_style).present?
            render style
          end
        end
      end
    end
  end

  private

  def find_public_docs_with_category_ids(category_ids)
    categorizations = GpCategory::Categorization.arel_table
    GpArticle::Doc.mobile(::Page.mobile?).public
                  .joins(:categorizations).where(categorizations[:category_id].in(category_ids))
  end
end
