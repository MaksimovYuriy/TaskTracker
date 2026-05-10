# frozen_string_literal: true

class AddUserIdToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :user_id, :bigint
    add_column :task_templates, :user_id, :bigint

    remove_index :tasks, name: 'index_tasks_on_scheduled_at'
    add_index :tasks, %i[user_id scheduled_at], unique: true
    add_index :tasks, :scheduled_at
  end
end
