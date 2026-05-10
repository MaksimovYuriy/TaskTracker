# frozen_string_literal: true

class ChangeScheduledAtNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :tasks, :scheduled_at, false
  end
end
