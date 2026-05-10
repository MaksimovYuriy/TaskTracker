# frozen_string_literal: true

class TaskTemplateTag < ApplicationRecord
  belongs_to :task_template
  belongs_to :tag

  validates :task_template_id, uniqueness: { scope: :tag_id }
end
