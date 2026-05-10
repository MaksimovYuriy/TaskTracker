# frozen_string_literal: true

class AddTaskTemplateIdToTasks < ActiveRecord::Migration[7.1]
  def change
    add_reference :tasks, :task_template, foreign_key: true
  end
end
