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

ActiveRecord::Schema[8.1].define(version: 2026_08_09_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "banks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["title"], name: "index_banks_on_title"
  end

  create_table "loan_offer_changes", force: :cascade do |t|
    t.datetime "changed_at", null: false
    t.datetime "created_at", null: false
    t.bigint "loan_offer_id", null: false
    t.string "note"
    t.jsonb "snapshot", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["changed_at"], name: "index_loan_offer_changes_on_changed_at"
    t.index ["loan_offer_id"], name: "index_loan_offer_changes_on_loan_offer_id"
  end

  create_table "loan_offers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.decimal "bank_commission_percent", precision: 6, scale: 3, default: "0.0", null: false
    t.bigint "bank_id", null: false
    t.decimal "bank_margin_percent", precision: 6, scale: 3, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "fixed_rate_percent", precision: 6, scale: 3
    t.integer "fixed_rate_years"
    t.decimal "life_insurance_percent", precision: 8, scale: 4
    t.decimal "life_insurance_total", precision: 12, scale: 2
    t.integer "life_insurance_years"
    t.decimal "overpayment_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "overpayment_coef", precision: 8, scale: 3, default: "1.0", null: false
    t.integer "overpayment_grace_years", default: 0, null: false
    t.integer "overpayment_mode", default: 0, null: false
    t.decimal "overpayment_penalty_min_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "overpayment_penalty_percent", precision: 6, scale: 3, default: "0.0", null: false
    t.integer "overpayment_penalty_years", default: 0, null: false
    t.date "promoted_from"
    t.date "promoted_until"
    t.decimal "property_insurance_monthly", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "rate_type", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "wibor_kind", default: 1, null: false
    t.index ["active"], name: "index_loan_offers_on_active"
    t.index ["bank_id"], name: "index_loan_offers_on_bank_id"
    t.index ["rate_type"], name: "index_loan_offers_on_rate_type"
  end

  create_table "wibor_snapshots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "effective_date", null: false
    t.datetime "fetched_at", null: false
    t.jsonb "payload", default: {}, null: false
    t.string "source_url", null: false
    t.datetime "updated_at", null: false
    t.decimal "wibor_1m", precision: 6, scale: 3, null: false
    t.decimal "wibor_3m", precision: 6, scale: 3, null: false
    t.index ["effective_date"], name: "index_wibor_snapshots_on_effective_date", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "loan_offer_changes", "loan_offers"
  add_foreign_key "loan_offers", "banks"
end
