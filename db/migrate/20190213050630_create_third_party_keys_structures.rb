class CreateThirdPartyKeysStructures < ActiveRecord::Migration[5.2]
  def change
    create_table :third_party_services do |t|
      t.bigint :user_ref
      t.string :uri
      t.string :access_key
    end
    add_foreign_key :third_party_services, :users, column: :user_ref, primary_key: "id"

    create_table :third_party_key_events do |t|
      t.datetime :created_at, null: false
    end

    create_table :third_party_keys do |t|
      t.references :third_party_service, foreign_key: true
      t.bigint :created_ref
      t.bigint :revoked_ref
      t.bigint :user_ref
      t.string :data
    end

    add_foreign_key :third_party_keys, :third_party_key_events, column: :created_ref, primary_key: "id"
    add_foreign_key :third_party_keys, :third_party_key_events, column: :revoked_ref, primary_key: "id"
    add_foreign_key :third_party_keys, :users, column: :user_ref, primary_key: "id"
  end
end
