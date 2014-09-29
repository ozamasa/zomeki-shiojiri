# encoding: utf-8
class Survey::Public::Node::FormsController < Cms::Controller::Public::Base
  include SimpleCaptcha::ControllerHelpers
  before_filter :set_form, only: [:show, :confirm_answers, :send_answers, :finish]
  skip_filter :render_public_layout
  after_filter :call_render_public_layout

  def pre_dispatch
    @node = Page.current_node
    @content = Survey::Content::Form.find_by_id(@node.content.id)
    return http_error(404) unless @content

    @ssl_full_uri = Sys::Setting.use_common_ssl? ? "#{Page.site.full_ssl_uri.sub(/\/\z/, '')}" : ''
  end

  def index
    @forms = @content.public_forms
  end

  def show
    @form_answer = @form.form_answers.build(answered_url: "#{@content.site.full_uri.sub(/\/+$/, '')}#{@content.public_node.public_uri}#{@form.name}",
                                            answered_url_title: @form.title,
                                            remote_addr: request.remote_addr, user_agent: request.user_agent)
    
    render_survey_layout
  end

  def confirm_answers
    build_answer

    if @form_answer.form.confirmation?
      render_survey_layout(:show) and return unless @content.use_captcha? ? @form_answer.valid_with_captcha? : @form_answer.valid?
    else
      render_survey_layout(:show) and return unless @content.use_captcha? ? @form_answer.save_with_captcha : @form_answer.save
      send_mail_and_redirect_to_finish and return
    end

    render_survey_layout and return
  end

  def send_answers
    build_answer

    if params[:edit_answers] || !@form_answer.save
      render_survey_layout(:show)
    else
      send_mail_and_redirect_to_finish
    end
  end

  def finish
    render_survey_layout
  end

  private

  def set_form
    forms = Core.mode == 'preview' ? @content.forms : @content.public_forms
    @form = forms.find_by_name(params[:id])
    return http_error(404) unless @form
    return render(text: '') unless @form.open?

    Page.current_item = @form
    Page.title = @form.title
  end

  def call_render_public_layout
    render_public_layout unless params[:piece]
  end

  def build_answer
    @form_answer = @form.form_answers.build(answered_url: params[:current_url].try(:sub, %r!/confirm_answers$!, ''),
                                            answered_url_title: params[:current_url_title],
                                            remote_addr: request.remote_addr, user_agent: request.user_agent,
                                            captcha: params[:captcha], captcha_key: params[:captcha_key])
    @form_answer.question_answers = params[:question_answers]
  end

  def send_mail_and_redirect_to_finish
    CommonMailer.survey_receipt(form_answer: @form_answer, from: @content.mail_from, to: @content.mail_to)
                .deliver if @content.mail_from.present? && @content.mail_to.present?

    dump Core.request_uri
    if Core.request_uri =~ /^\/_ssl\/([0-9]+).*/
      redirect_to ::File.join(Page.site.full_ssl_uri, "#{@node.public_uri}#{@form_answer.form.name}/finish") #?piece=#{params[:piece]}
    else
      redirect_to "#{@node.public_uri}#{@form_answer.form.name}/finish" #?piece=#{params[:piece]}
    end
  end

  def render_survey_layout(action = action_name)
    @piece = Survey::Piece::Form.find_by_id(params[:piece])
#    return render(:text => '') unless @piece

    Page.layout = Cms::Layout.new({
      head:             @piece.try(:head_css) || '',
      mobile_head:      @piece.try(:head_css) || '',
      smart_phone_head: @piece.try(:head_css) || '',
      body:             '[[content]]',
      mobile_body:      '[[content]]',
      smart_phone_body: '[[content]]'
    })
    render action: action, layout: 'layouts/public/base'
  end
end
