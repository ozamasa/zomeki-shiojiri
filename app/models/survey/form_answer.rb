class Survey::FormAnswer < ActiveRecord::Base
  include Sys::Model::Base

  default_scope order("#{self.table_name}.created_at DESC")

  belongs_to :form
  validates_presence_of :form_id

  has_many :answers, :dependent => :destroy

  validate :validate_base

  def question_answers=(qa)
    if qa.kind_of?(Hash)
      qa.each do |key, value|
        next unless question = form.questions.find_by_id(key)
        answers.build(question: question, content: value.kind_of?(Array) ? value.reject{|v| v.blank? }.join(',') : value)
      end
    end
    return qa
  end

  # Use before saving answers
  def detect_answer_by_question(question)
    answers.detect{|a| a.question_id == question.id }
  end

  private

  def validate_base
    errors.keys.each{|k| errors.delete(k) unless [:base, :form_id].include?(k) }
    answers.each do |answer|
      if ['text_field', 'text_area'].include?(answer.question.form_type)
        errors.add(:base, "#{answer.question.title}は#{answer.question.form_text_max_length}文字以内で入力してください。") if answer.content.size > answer.question.form_text_max_length
      end
      errors.add(:base, "#{answer.question.title}を入力してください。") if answer.question.required? && answer.content.blank?
    end
  end
end
