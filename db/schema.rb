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

ActiveRecord::Schema[8.1].define(version: 2026_09_23_051602) do
  create_table "address_books", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "ctag", default: 0, null: false
    t.string "name", default: "Contacts", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_address_books_on_user_id", unique: true
  end

  create_table "app_passwords", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.string "secret_digest", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["secret_digest"], name: "index_app_passwords_on_secret_digest", unique: true
    t.index ["user_id"], name: "index_app_passwords_on_user_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.integer "address_book_id", null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.text "emails"
    t.string "etag", null: false
    t.string "family_name"
    t.string "given_name"
    t.string "organization"
    t.text "phones"
    t.string "resource_name", null: false
    t.string "sort_key", null: false
    t.datetime "trashed_at"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.text "vcard", null: false
    t.index ["address_book_id", "resource_name"], name: "index_contacts_on_address_book_id_and_resource_name", unique: true
    t.index ["address_book_id", "sort_key"], name: "index_contacts_on_address_book_id_and_sort_key"
    t.index ["address_book_id", "uid"], name: "index_contacts_on_address_book_id_and_uid", unique: true
    t.index ["address_book_id"], name: "index_contacts_on_address_book_id"
    t.index ["archived_at"], name: "index_contacts_on_archived_at"
    t.index ["trashed_at"], name: "index_contacts_on_trashed_at"
  end

  create_table "passkeys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.text "public_key", null: false
    t.integer "sign_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["external_id"], name: "index_passkeys_on_external_id", unique: true
    t.index ["user_id"], name: "index_passkeys_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "setup_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.integer "user_id", null: false
    t.index ["token_digest"], name: "index_setup_links_on_token_digest", unique: true
    t.index ["user_id"], name: "index_setup_links_on_user_id"
  end

  create_table "sync_changes", force: :cascade do |t|
    t.integer "address_book_id", null: false
    t.datetime "created_at", null: false
    t.boolean "removed", default: false, null: false
    t.string "resource_name", null: false
    t.datetime "updated_at", null: false
    t.index ["address_book_id", "id"], name: "index_sync_changes_on_address_book_id_and_id"
    t.index ["address_book_id"], name: "index_sync_changes_on_address_book_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.string "webauthn_id", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
    t.index ["webauthn_id"], name: "index_users_on_webauthn_id", unique: true
  end

  add_foreign_key "address_books", "users"
  add_foreign_key "app_passwords", "users"
  add_foreign_key "contacts", "address_books"
  add_foreign_key "passkeys", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "setup_links", "users"
  add_foreign_key "sync_changes", "address_books"
end
