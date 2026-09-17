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

ActiveRecord::Schema[8.1].define(version: 2026_09_17_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "invoice_items", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.bigint "invoice_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_amount", precision: 12, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.date "due_on"
    t.string "number", null: false
    t.string "status", default: "draft", null: false
    t.bigint "subscription_id"
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["number"], name: "index_invoices_on_number", unique: true
    t.index ["subscription_id"], name: "index_invoices_on_subscription_id"
    t.index ["user_id", "status"], name: "index_invoices_on_user_id_and_status"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

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

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.bigint "invoice_id", null: false
    t.datetime "paid_at"
    t.string "status", default: "pending", null: false
    t.string "transaction_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
    t.index ["transaction_id"], name: "index_payments_on_transaction_id", unique: true
    t.index ["user_id", "status"], name: "index_payments_on_user_id_and_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.date "current_period_end", null: false
    t.date "current_period_start", null: false
    t.string "plan_name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "status"], name: "index_subscriptions_on_user_id_and_status"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.integer "category"
    t.datetime "created_at", null: false
    t.string "open_ai_conversation_id"
    t.integer "priority"
    t.boolean "requires_human", default: false, null: false
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

  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "subscriptions"
  add_foreign_key "invoices", "users"
  add_foreign_key "messages", "messages", column: "reply_to_message_id"
  add_foreign_key "messages", "tickets"
  add_foreign_key "messages", "users"
  add_foreign_key "payments", "invoices"
  add_foreign_key "payments", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tickets", "users"
end
