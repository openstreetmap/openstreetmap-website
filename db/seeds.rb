# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Language.load(Rails.root.join("config/languages.yml"))

def oauth_token(application_id, user_id)
  application = Doorkeeper.config.application_model.find_by(:uid => application_id)

  Doorkeeper.config.access_token_model.find_or_create_for(
    :application => application,
    :resource_owner => user_id,
    :scopes => application.scopes
  )
end

def log(*)
  puts(*) # rubocop:disable Rails/Output
end

User.find_by(:display_name => "admin")&.soft_destroy!
User.find_by(:display_name => "testuser")&.soft_destroy!

password = "openstreetmap"
admin = User.create!(:display_name => "admin", :email => "admin_#{SecureRandom.uuid}@demo.cc",
                     :pass_crypt => password, :pass_crypt_confirmation => password,
                     :tou_agreed => Time.now.utc, :terms_seen => true,
                     :terms_agreed => Time.now.utc, :email_valid => true,
                     :data_public => true)
admin.activate!
admin.confirm!
admin.save!

admin.roles.create!(:role => "administrator", :granter_id => admin.id)

testuser = User.create!(:display_name => "testuser", :email => "testuser__#{SecureRandom.uuid}@demo.cc",
                        :pass_crypt => password, :pass_crypt_confirmation => password,
                        :tou_agreed => Time.now.utc, :terms_seen => true,
                        :terms_agreed => Time.now.utc, :email_valid => true,
                        :data_public => true)
testuser.activate!
testuser.confirm!
testuser.save!

oauth_owner = User.find_by(:display_name => "admin")

josmeditor = Doorkeeper::Application.create!(:name => "JOSM", :owner_type => "User", :owner_id => oauth_owner.id,
                                             :confidential => false,
                                             :redirect_uri => "http://127.0.0.1:8111/oauth_authorization",
                                             :scopes => ["read_prefs write_prefs write_api read_gpx write_gpx write_notes"])

log %(JOSM client id: #{josmeditor.uid})
log ""

ideditor = Doorkeeper::Application.create!(:name => "Local iD", :owner_type => "User", :owner_id => oauth_owner.id,
                                           :redirect_uri => "http://localhost:3000",
                                           :scopes => ["read_prefs write_prefs write_api read_gpx write_gpx write_notes"])

log "# Copy the following lines to config/settings.local.yml"
log "#"

log %(id_application: "#{ideditor.uid}")

website = Doorkeeper::Application.create!(:name => "OpenStreetMap Web Site", :owner_type => "User", :owner_id => oauth_owner.id,
                                          :redirect_uri => "http://localhost:3000",
                                          :scopes => ["write_api write_notes"])

log %(oauth_application: "#{website.uid}")
log %(oauth_key: "#{oauth_token(website.uid, oauth_owner.id).token}")

log "#"

key = OpenSSL::PKey::RSA.new 2048
pem = key.private_to_pem

log "doorkeeper_signing_key: |"
log(pem.lines.each { |x| x.prepend("  ") })
