# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_03_29_204540) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "choices", force: :cascade do |t|
    t.string "content"
    t.boolean "winner", default: false
    t.bigint "survey_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["survey_id"], name: "index_choices_on_survey_id"
  end

  create_table "rankings", force: :cascade do |t|
    t.integer "value"
    t.bigint "response_id"
    t.bigint "choice_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["choice_id"], name: "index_rankings_on_choice_id"
    t.index ["response_id"], name: "index_rankings_on_response_id"
  end

  create_table "responses", force: :cascade do |t|
    t.string "token"
    t.bigint "survey_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["survey_id"], name: "index_responses_on_survey_id"
  end

  create_table "surveys", force: :cascade do |t|
    t.string "name"
    t.string "user_email"
    t.integer "threshold"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "choices", "surveys"
  add_foreign_key "rankings", "choices"
  add_foreign_key "rankings", "responses"
  add_foreign_key "responses", "surveys"
end
