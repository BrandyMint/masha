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

ActiveRecord::Schema.define(version: 20130528050127) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "authentications", force: true do |t|
    t.integer  "user_id",    null: false
    t.string   "provider",   null: false
    t.string   "uid",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authentications", ["provider", "uid"], name: "index_authentications_on_provider_and_uid", unique: true, using: :btree
  add_index "authentications", ["user_id", "provider"], name: "index_authentications_on_user_id_and_provider", unique: true, using: :btree

  create_table "projects", force: true do |t|
    t.string   "name"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "projects", ["owner_id"], name: "index_projects_on_owner_id", using: :btree

  create_table "roles", force: true do |t|
    t.string   "name",          null: false
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", unique: true, using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "time_shifts", force: true do |t|
    t.integer  "project_id", null: false
    t.integer  "user_id",    null: false
    t.integer  "minutes",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "time_shifts", ["project_id"], name: "index_time_shifts_on_project_id", using: :btree
  add_index "time_shifts", ["user_id"], name: "index_time_shifts_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "name",                       null: false
    t.boolean  "is_root",    default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users_roles", id: false, force: true do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", unique: true, using: :btree

end
