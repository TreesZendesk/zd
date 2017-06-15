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

ActiveRecord::Schema.define(version: 20161007022914) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "authors", force: :cascade do |t|
    t.string   "author_id"
    t.string   "name"
    t.string   "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_authors_on_author_id", using: :btree
  end

  create_table "channels", force: :cascade do |t|
    t.string "name"
    t.string "channel_id"
    t.string "channel_secret"
    t.string "channel_access_token"
    t.string "zendesk_subdomain"
    t.string "zendesk_locale"

    t.string "instance_push_id"
    t.string "zendesk_access_token"
    t.index ["channel_id"], name: "index_channels_on_channel_id", using: :btree
  end

  create_table "external_resources", force: :cascade do |t|
    t.string   "external_id"
    t.text     "message"
    t.string   "thread_id"
    t.datetime "created_at",                        null: false
    t.string   "line_timestamp"
    t.string   "author_id"
    t.boolean  "allow_channelback", default: false
    t.datetime "updated_at",                        null: false
    t.index ["author_id"], name: "index_external_resources_on_author_id", using: :btree
    t.index ["external_id"], name: "index_external_resources_on_external_id", using: :btree
    t.index ["thread_id"], name: "index_external_resources_on_thread_id", using: :btree
  end

  create_table "jobs", force: :cascade do |t|
    t.string   "channel_id"
    t.integer  "external_resource_id"
    t.string   "status"
    t.string   "zendesk_status"
    t.string   "channel_uid"
    t.string   "thread_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["channel_id"], name: "index_jobs_on_channel_id", using: :btree
    t.index ["channel_uid"], name: "index_jobs_on_channel_uid", using: :btree
    t.index ["thread_id"], name: "index_jobs_on_thread_id", using: :btree
  end

end
