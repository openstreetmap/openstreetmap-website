# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Language.load(Rails.root.join("config/languages.yml"))

def log(*)
  puts(*) # rubocop:disable Rails/Output
end

display_name = "admin"
password = "openstreetmap"
email = "admin_#{SecureRandom.uuid}@example.com"
role = "administrator"

admin = User.find_or_create_by!(:display_name => display_name) do |user|
  user.email = email
  user.pass_crypt = password
  user.pass_crypt_confirmation = password
  user.tou_agreed = Time.now.utc
  user.terms_seen = true
  user.terms_agreed = Time.now.utc
  user.email_valid = true
  user.data_public = true
end
admin.activate!
admin.confirm!
admin.save!

admin.roles.create!(:role => role, :granter_id => admin.id)

log(
  <<~MESSAGE
    Created user:
      - Display name: #{display_name}
      - Email: #{email}
      - Password: #{password}
      - Role: #{role}
  MESSAGE
)
Oauth::Util.register_apps(display_name)
