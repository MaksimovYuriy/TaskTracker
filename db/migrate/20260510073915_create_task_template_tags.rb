# frozen_string_literal: true

class CreateTaskTemplateTags < ActiveRecord::Migration[7.1]
  def change
    create_table :task_template_tags do |t|
      t.references :task_template, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
