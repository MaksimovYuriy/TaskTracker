class CreateTaskTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :task_templates do |t|
      t.string :title, null: false, limit: 255
      t.text :description, null: false
      t.integer :recurrence_type, null: false
      t.integer :interval
      t.integer :day_of_month
      t.date :specific_dates, array: true, default: []
      t.time :time_of_day, null: false
      t.date :ends_at
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
