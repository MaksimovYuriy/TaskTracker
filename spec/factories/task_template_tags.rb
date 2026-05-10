# frozen_string_literal: true

FactoryBot.define do
  factory :task_template_tag do
    task_template
    tag
  end
end
