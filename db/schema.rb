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

ActiveRecord::Schema.define(version: 20151220071406) do

  create_table "facilities", force: :cascade do |t|
    t.integer  "namespace_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "name",               null: false
    t.string   "description",        null: false
    t.string   "verify_calendar_id"
    t.string   "rent_calendar_id"
  end

  add_index "facilities", ["namespace_id"], name: "index_facilities_on_namespace_id"

  create_table "namespaces", force: :cascade do |t|
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name",        null: false
    t.string   "description", null: false
  end

  create_table "namespaces_users", force: :cascade do |t|
    t.integer "user_id"
    t.integer "namespace_id"
  end

  add_index "namespaces_users", ["namespace_id"], name: "index_namespaces_users_on_namespace_id"
  add_index "namespaces_users", ["user_id"], name: "index_namespaces_users_on_user_id"

  create_table "rents", force: :cascade do |t|
    t.integer  "facility_id"
    t.integer  "user_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "name",                        null: false
    t.boolean  "verified",    default: false, null: false
  end

  add_index "rents", ["facility_id"], name: "index_rents_on_facility_id"
  add_index "rents", ["user_id"], name: "index_rents_on_user_id"

  create_table "spans", force: :cascade do |t|
    t.string   "event_id"
    t.integer  "rent_id"
    t.datetime "start"
    t.datetime "end"
  end

  add_index "spans", ["event_id"], name: "index_spans_on_event_id"
  add_index "spans", ["rent_id"], name: "index_spans_on_rent_id"

  create_table "users", force: :cascade do |t|
    t.string "uid",  null: false
    t.string "name", null: false
    t.string "unit", null: false
  end

  add_index "users", ["uid"], name: "index_users_on_uid"

end
