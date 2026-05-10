# frozen_string_literal: true

class CreateTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.string :title, null: false, limit: 32

      t.timestamps
    end
  end
end
