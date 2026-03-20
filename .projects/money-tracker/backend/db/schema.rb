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

ActiveRecord::Schema[8.1].define(version: 2026_03_15_213137) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookmark_tags", force: :cascade do |t|
    t.bigint "bookmark_id", null: false
    t.bigint "tag_id", null: false
    t.index ["bookmark_id"], name: "index_bookmark_tags_on_bookmark_id"
    t.index ["tag_id"], name: "index_bookmark_tags_on_tag_id"
  end

  create_table "bookmarks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url", null: false
  end

  create_table "budgets", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.decimal "limit_amount", precision: 10, scale: 2, null: false
    t.integer "month", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["category_id", "month", "year"], name: "index_budgets_on_category_id_and_month_and_year", unique: true
    t.index ["category_id"], name: "index_budgets_on_category_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.string "icon", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "expense_kind"
    t.text "notes"
    t.string "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["date"], name: "index_transactions_on_date"
  end

  add_foreign_key "bookmark_tags", "bookmarks"
  add_foreign_key "bookmark_tags", "tags"
  add_foreign_key "budgets", "categories"
  add_foreign_key "transactions", "categories"
end
