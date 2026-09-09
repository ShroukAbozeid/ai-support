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

ActiveRecord::Schema[8.1].define(version: 2026_09_07_151948) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "open_ai_response_id"
    t.bigint "reply_to_message_id"
    t.integer "role"
    t.bigint "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["open_ai_response_id"], name: "index_messages_on_open_ai_response_id"
    t.index ["reply_to_message_id"], name: "index_messages_on_reply_to_message_id", unique: true
    t.index ["ticket_id", "created_at"], name: "index_messages_on_ticket_id_and_created_at"
    t.index ["ticket_id"], name: "index_messages_on_ticket_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "open_ai_conversation_id"
    t.integer "priority"
    t.integer "status"
    t.string "subject"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["open_ai_conversation_id"], name: "index_tickets_on_open_ai_conversation_id", unique: true
    t.index ["user_id", "status"], name: "index_tickets_on_user_id_and_status"
    t.index ["user_id"], name: "index_tickets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "messages", "messages", column: "reply_to_message_id"
  add_foreign_key "messages", "tickets"
  add_foreign_key "messages", "users"
  add_foreign_key "tickets", "users"
end
