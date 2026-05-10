class AddIndexToTasksOnTemplate < ActiveRecord::Migration[7.1]
  def change
    add_index :tasks,
              %i[task_template_id scheduled_at],
              unique: true,
              where: "task_template_id IS NOT NULL",
              name: "index_tasks_on_template_and_scheduled_at_unique"
  end
end
