# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_05_10_074144) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "tags", force: :cascade do |t|
    t.string "title", limit: 32, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "task_tags", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_task_tags_on_tag_id"
    t.index ["task_id"], name: "index_task_tags_on_task_id"
  end

  create_table "task_template_tags", force: :cascade do |t|
    t.bigint "task_template_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_task_template_tags_on_tag_id"
    t.index ["task_template_id"], name: "index_task_template_tags_on_task_template_id"
  end

  create_table "task_templates", force: :cascade do |t|
    t.string "title", limit: 255, null: false
    t.text "description", null: false
    t.integer "recurrence_type", null: false
    t.integer "interval"
    t.integer "day_of_month"
    t.date "specific_dates", default: [], array: true
    t.time "time_of_day", null: false
    t.date "ends_at"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "scheduled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.bigint "task_template_id"
    t.index ["scheduled_at"], name: "index_tasks_on_scheduled_at"
    t.index ["task_template_id", "scheduled_at"], name: "index_tasks_on_template_and_scheduled_at_unique", unique: true, where: "(task_template_id IS NOT NULL)"
    t.index ["task_template_id"], name: "index_tasks_on_task_template_id"
  end

  add_foreign_key "task_tags", "tags"
  add_foreign_key "task_tags", "tasks"
  add_foreign_key "task_template_tags", "tags"
  add_foreign_key "task_template_tags", "task_templates"
  add_foreign_key "tasks", "task_templates"
end
