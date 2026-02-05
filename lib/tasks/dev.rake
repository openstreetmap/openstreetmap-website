# frozen_string_literal: true

return unless Rails.env.development?

def create_user(display_name:, password:, email:, admin: false)
  user = User.find_or_create_by!(:display_name => display_name) do |record|
    record.email = email
    record.pass_crypt = password
    record.pass_crypt_confirmation = password
    record.tou_agreed = Time.now.utc
    record.terms_seen = true
    record.terms_agreed = Time.now.utc
    record.email_valid = true
    record.data_public = true
  end
  user.activate!
  user.confirm!
  user.save!

  user.roles.create!(:role => "admin", :granter_id => user.id) if admin

  initial_line = admin ? "Created admin user" : "Created user"
  puts(
    <<~MESSAGE
      #{initial_line}:
        - Display name: #{display_name}
        - Email: #{email}
        - Password: #{password}
    MESSAGE
  )
end

namespace "dev" do
  desc "Populate the development database with some fake data"
  task "populate" => :environment do
    # Ensure that all dates (e.g. terms_agreed) are consistent
    Timecop.freeze(Time.utc(2015, 10, 21, 12, 0, 0)) do
      create_user(:display_name => "admin", :password => "password", :email => "admin@example.com", :admin => true)
      create_user(:display_name => "mapper", :password => "password", :email => "mapper@example.com")
    end

    Oauth::Util.register_apps("admin")
  end
end
