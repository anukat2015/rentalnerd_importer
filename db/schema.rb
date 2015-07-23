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

ActiveRecord::Schema.define(version: 20150722161343) do

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
  end

  create_table "rental_diffs", force: true do |t|
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
    t.integer  "rental_import_job_id"
  end

  create_table "rental_import_jobs", force: true do |t|
    t.string "source"
  end

  create_table "rental_logs", force: true do |t|
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
    t.integer  "rental_import_job_id"
  end

  create_table "rental_transactions", force: true do |t|
    t.integer  "price"
    t.string   "transaction_status"
    t.date     "date_listed"
    t.date     "date_rented"
    t.integer  "days_on_market"
    t.boolean  "is_latest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "property_id"
    t.string   "transaction_type"
  end

end
