# frozen_string_literal: true

module Tasks
  class RecurrenceCanceller < ApplicationService
    def initialize(task_id)
      @task_id = task_id
    end

    def call
      task = Task.find(@task_id)
      return if task.task_template_id.nil?

      template = task.task_template

      ApplicationRecord.transaction do
        template.cancel! if template.active?
        template.tasks
                .where("scheduled_at > ?", Time.current)
                .where(status: :pending)
                .destroy_all
      end
    end
  end
end
