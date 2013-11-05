# encoding: utf-8

require 'csv'

class Survey::Admin::FormsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless @content = Survey::Content::Form.find_by_id(params[:content])
    return error_auth unless Core.user.has_priv?(:read, :item => @content.concept)
    @item = @content.forms.find(params[:id]) if params[:id].present?
  end

  def index
    @items = @content.forms.paginate(page: params[:page], per_page: 30)
    _index @items
  end

  def show
    _show @item
  end

  def new
    @item = @content.forms.build
  end

  def create
    new_state = params.keys.detect{|k| k =~ /^commit_/ }.try(:sub, /^commit_/, '')

    @item = @content.forms.build(params[:item])

    @item.state = new_state if new_state.present? && @item.class::STATE_OPTIONS.any?{|v| v.last == new_state }

    validate_approval_requests if @item.state_approvable?
    return render(:action => :new) unless @item.errors.empty?

    location = url_for(action: 'edit') if @item.state_draft?
    _create(@item, location: location) do
      @item.approval_requests.destroy_all if @item.state_approvable?
      set_approval_requests
      @item.send_approval_request_mail if @item.state_approvable?
    end
  end

  def update
    new_state = params.keys.detect{|k| k =~ /^commit_/ }.try(:sub, /^commit_/, '')

    @item.attributes = params[:item]

    @item.state = new_state if new_state.present? && @item.class::STATE_OPTIONS.any?{|v| v.last == new_state }

    validate_approval_requests if @item.state_approvable?
    return render(:action => :edit) unless @item.errors.empty?

    location = url_for(action: 'edit') if @item.state_draft?
    _update(@item, location: location) do
      @item.approval_requests.destroy_all if @item.state_approvable?
      set_approval_requests
      @item.send_approval_request_mail if @item.state_approvable?
    end
  end

  def destroy
    _destroy @item
  end

  def download_form_answers
    csv_string = CSV.generate do |csv|
      header = [Survey::FormAnswer.human_attribute_name(:created_at),
                "#{Survey::FormAnswer.human_attribute_name(:answered_url)}URL",
                "#{Survey::FormAnswer.human_attribute_name(:answered_url)}タイトル",
                Survey::FormAnswer.human_attribute_name(:remote_addr),
                Survey::FormAnswer.human_attribute_name(:user_agent)]

      @item.questions.each{|q| header << q.title }

      csv << header

      @item.form_answers.each do |form_answer|
        line = [I18n.l(form_answer.created_at),
                form_answer.answered_url,
                form_answer.answered_url_title,
                form_answer.remote_addr,
                form_answer.user_agent]

        @item.questions.each{|q| line << form_answer.answers.find_by_question_id(q.id).try(:content) }

        csv << line
      end
    end

    send_data csv_string.encode(Encoding::WINDOWS_31J, :invalid => :replace, :undef => :replace),
              type: Rack::Mime.mime_type('.csv'), filename: 'answers.csv'
  end

  def approve
    @item.approve(Core.user) if @item.state_approvable? && @item.approvers.include?(Core.user)
    redirect_to url_for(:action => :show), notice: '承認処理が完了しました。'
  end

  def publish
    @item.publish if @item.state_approved? && @item.approval_participators.include?(Core.user)
    redirect_to url_for(:action => :show), notice: '公開処理が完了しました。'
  end

  private

  def set_approval_requests
    approval_flow_ids = if params[:approval_flows].is_a?(Array)
                          params[:approval_flows].map{|a| a.to_i if a.present? }.compact.uniq
                        else
                          []
                        end

    approval_flow_ids.each do |approval_flow_id|
      next if @item.approval_requests.find_by_approval_flow_id(approval_flow_id)
      @item.approval_requests.create(user_id: Core.user.id, approval_flow_id: approval_flow_id)
    end

    @item.approval_requests.each do |approval_request|
      approval_request.destroy unless approval_flow_ids.include?(approval_request.approval_flow_id)
    end
  end

  def validate_approval_requests
    approval_flow_ids = if params[:approval_flows].is_a?(Array)
                          params[:approval_flows].map{|a| a.to_i if a.present? }.compact.uniq
                        else
                          []
                        end

    @item.errors.add(:base, '承認フローを選択してください。') if approval_flow_ids.empty?
  end
end
