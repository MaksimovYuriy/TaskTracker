class ChangeIndexex < ActiveRecord::Migration[7.1]
  def change
    remove_index :tasks, name: "index_tasks_on_template_and_scheduled_at_unique"
    remove_index :tasks, name: "index_tasks_on_scheduled_at"
    add_index :tasks, :scheduled_at, unique: true
  end
end
