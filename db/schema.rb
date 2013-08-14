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

ActiveRecord::Schema.define(version: 20130814065346) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: true do |t|
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "authentications", force: true do |t|
    t.integer  "user_id",    null: false
    t.string   "provider",   null: false
    t.string   "uid",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "auth_hash"
  end

  add_index "authentications", ["provider", "uid"], name: "index_authentications_on_provider_and_uid", unique: true, using: :btree
  add_index "authentications", ["user_id", "provider"], name: "index_authentications_on_user_id_and_provider", unique: true, using: :btree

  create_table "invites", force: true do |t|
    t.integer  "user_id"
    t.string   "email",      null: false
    t.string   "role",       null: false
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invites", ["email"], name: "index_invites_on_email", unique: true, using: :btree
  add_index "invites", ["project_id"], name: "index_invites_on_project_id", using: :btree
  add_index "invites", ["user_id"], name: "index_invites_on_user_id", using: :btree

  create_table "memberships", force: true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.integer  "role_cd",    default: 2, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "memberships", ["project_id"], name: "index_memberships_on_project_id", using: :btree
  add_index "memberships", ["user_id", "project_id"], name: "index_memberships_on_user_id_and_project_id", unique: true, using: :btree
  add_index "memberships", ["user_id"], name: "index_memberships_on_user_id", using: :btree

  create_table "projects", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug",        null: false
    t.text     "description"
  end

  add_index "projects", ["slug"], name: "index_projects_on_slug", unique: true, using: :btree

  create_table "time_shifts", force: true do |t|
    t.integer  "project_id",  null: false
    t.integer  "user_id",     null: false
    t.decimal  "hours",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "date",        null: false
    t.text     "description", null: false
  end

  add_index "time_shifts", ["date"], name: "index_time_shifts_on_date", order: {"date"=>:desc}, using: :btree
  add_index "time_shifts", ["project_id"], name: "index_time_shifts_on_project_id", using: :btree
  add_index "time_shifts", ["user_id"], name: "index_time_shifts_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "name",                                         null: false
    t.boolean  "is_root",                      default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "pivotal_person_id"
    t.string   "email"
    t.string   "nickname"
    t.string   "crypted_password"
    t.string   "salt"
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.boolean  "subscribed",                   default: true
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["remember_me_token"], name: "index_users_on_remember_me_token", using: :btree

end
