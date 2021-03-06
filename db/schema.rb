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

ActiveRecord::Schema.define(version: 2019_12_18_121552) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "branches", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "branch_id", null: false
    t.integer "age", null: false
    t.integer "parent_id", null: false
    t.integer "anglex10", default: 0, null: false
    t.float "length", null: false
    t.integer "sumdevx10", null: false
    t.float "factor", null: false
    t.integer "time_since_last_split", default: 0, null: false
    t.integer "num_children", default: 0
    t.integer "generation", default: 0, null: false
    t.boolean "has_split", default: false, null: false
    t.boolean "is_split_child", default: false, null: false
  end

  create_table "trees", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "id_str", null: false
    t.string "priv_key", null: false
    t.integer "time_active", null: false
    t.string "name", default: "Unnamed Tree"
    t.json "branches_and_roots", default: "{}", null: false
    t.boolean "is_private", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_branch_id", default: 0, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "password_salt_enc", null: false
    t.string "salt", null: false
    t.string "username_hash", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
