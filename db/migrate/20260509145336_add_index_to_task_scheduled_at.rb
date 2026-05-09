class AddIndexToTaskScheduledAt < ActiveRecord::Migration[7.1]
  def change
    add_index :tasks, :scheduled_at
  end
end
