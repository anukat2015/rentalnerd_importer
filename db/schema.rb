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

ActiveRecord::Schema.define(version: 20151205185940) do

  create_table "import_diffs", force: true do |t|
    t.text     "address"
    t.string   "neighborhood"
    t.integer  "bedrooms"
    t.integer  "bathrooms"
    t.integer  "price"
    t.integer  "sqft"
    t.date     "date_closed"
    t.date     "date_listed"
    t.string   "source"
    t.string   "origin_url"
    t.string   "diff_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "old_log_id"
    t.integer  "new_log_id"
    t.integer  "import_job_id"
    t.string   "transaction_type", default: "rental"
    t.date     "date_transacted"
    t.boolean  "garage"
    t.integer  "year_built"
    t.integer  "level",            default: 1
    t.boolean  "sfh",              default: false
  end

  create_table "import_jobs", force: true do |t|
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "import_logs", force: true do |t|
    t.text     "address"
    t.string   "neighborhood"
    t.integer  "bedrooms"
    t.integer  "bathrooms"
    t.integer  "price"
    t.integer  "sqft"
    t.date     "date_closed"
    t.date     "date_listed"
    t.string   "source"
    t.string   "origin_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_job_id"
    t.string   "transaction_type", default: "rental"
    t.date     "date_transacted"
    t.boolean  "garage"
    t.integer  "year_built"
    t.integer  "level",            default: 1
    t.boolean  "sfh",              default: false
  end

  create_table "luxury_addresses", force: true do |t|
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "neighborhood_vertices", force: true do |t|
    t.integer  "neighborhood_id"
    t.integer  "vertex_order"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "neighborhoods", force: true do |t|
    t.string   "name"
    t.string   "shapefile_source"
    t.float    "max_latitude"
    t.float    "min_latitude"
    t.float    "max_longitude"
    t.float    "min_longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "park_vertices", force: true do |t|
    t.integer  "park_id"
    t.integer  "vertex_order"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "parks", force: true do |t|
    t.string   "name"
    t.integer  "size"
    t.string   "shapefile_source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "prediction_models", force: true do |t|
    t.float    "base_rent"
    t.float    "bedroom_coefficient"
    t.float    "bathroom_coefficient"
    t.float    "sqft_coefficient"
    t.float    "elevation_coefficient"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "area_name"
    t.boolean  "active"
    t.float    "dist_to_park_coefficient"
    t.float    "level_coefficient"
    t.float    "age_coefficient"
    t.float    "garage_coefficient"
  end

  create_table "prediction_neighborhoods", force: true do |t|
    t.integer  "prediction_model_id"
    t.string   "name"
    t.float    "coefficient"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "neighborhood_id"
    t.boolean  "active",              default: true
    t.float    "regular_coefficient"
    t.float    "luxury_coefficient"
  end

  create_table "prediction_results", force: true do |t|
    t.integer  "property_id"
    t.integer  "prediction_model_id"
    t.float    "predicted_rent"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "error_level"
    t.float    "listed_rent"
    t.string   "transaction_type",            default: "rental"
    t.float    "listed_sale"
    t.integer  "property_transaction_log_id"
    t.float    "cap_rate"
  end

  create_table "properties", force: true do |t|
    t.text     "address"
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
    t.text     "lookup_address"
    t.boolean  "luxurious"
    t.boolean  "garage"
    t.integer  "year_built"
    t.integer  "level",          default: 1
    t.float    "dist_to_park"
    t.boolean  "sfh",            default: false
  end

  create_table "property_neighborhoods", force: true do |t|
    t.integer  "property_id",     limit: 8, null: false
    t.integer  "neighborhood_id",           null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "property_neighborhoods", ["neighborhood_id"], name: "index_property_neighborhoods_on_neighborhood_id", using: :btree
  add_index "property_neighborhoods", ["property_id", "neighborhood_id"], name: "index_property_neighborhoods_on_property_id_and_neighborhood_id", unique: true, using: :btree

  create_table "property_transaction_logs", force: true do |t|
    t.integer  "price"
    t.string   "transaction_status"
    t.date     "date_listed"
    t.date     "date_closed"
    t.integer  "days_on_market"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "property_id"
    t.string   "transaction_type"
  end

  create_table "property_transactions", force: true do |t|
    t.integer  "property_id"
    t.integer  "property_transaction_log_id"
    t.string   "transaction_type",            limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "property_transactions", ["property_id", "transaction_type"], name: "index_property_transactions_on_property_id_and_transaction_type", unique: true, using: :btree

end
