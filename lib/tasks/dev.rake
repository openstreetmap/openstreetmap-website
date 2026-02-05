# frozen_string_literal: true

namespace :dev do
  desc "Populate the development database with some fake data"
  task :populate => :environment do
    raise "This task can only be run in development mode" unless Rails.env.development?

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
      user.activate
    end

    admin.roles.create!(:role => role, :granter_id => admin.id)

    puts(
      <<~MESSAGE
        Created user:
          - Display name: #{display_name}
          - Email: #{email}
          - Password: #{password}
          - Role: #{role}
      MESSAGE
    )
    Oauth::Util.register_apps(display_name)
  end
end
