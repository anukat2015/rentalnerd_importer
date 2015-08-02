# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150802161336) do

  create_table "import_diffs", force: true do |t|
    t.string   "address"
    t.string   "neighborhood"
    t.integer  "bedrooms"
    t.integer  "bathrooms"
    t.integer  "price"
    t.integer  "sqft"
    t.date     "date_rented"
    t.date     "date_listed"
    t.string   "source"
    t.string   "origin_url"
    t.string   "diff_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "old_log_id"
    t.integer  "new_log_id"
    t.integer  "import_job_id"
  end

  create_table "import_jobs", force: true do |t|
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "import_logs", force: true do |t|
    t.string   "address"
    t.string   "neighborhood"
    t.integer  "bedrooms"
    t.integer  "bathrooms"
    t.integer  "price"
    t.integer  "sqft"
    t.date     "date_rented"
    t.date     "date_listed"
    t.string   "source"
    t.string   "origin_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_job_id"
  end

  create_table "properties", force: true do |t|
    t.string   "address"
    t.string   "neighborhood"
    t.integer  "bedrooms"
    t.integer  "bathrooms"
    t.integer  "sqft"
    t.string   "source"
    t.string   "origin_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "latitude"
    t.float    "longitude"
    t.float    "elevation"
    t.string   "lookup_address"
  end

  create_table "property_transaction_logs", force: true do |t|
    t.integer  "price"
    t.string   "transaction_status"
    t.date     "date_listed"
    t.date     "date_rented"
    t.integer  "days_on_market"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "property_id"
    t.string   "transaction_type"
  end

  create_table "property_transactions", force: true do |t|
    t.integer  "property_id"
    t.integer  "transaction_log_id"
    t.string   "transaction_type",   limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "property_transactions", ["property_id", "transaction_type"], name: "index_property_transactions_on_property_id_and_transaction_type", unique: true, using: :btree

end
