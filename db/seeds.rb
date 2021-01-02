
Language.load(Rails.root.join("config/languages.yml"))

# Variables

def lorem_ipsum
  "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
end

def lorem_ipsum_markdown 
  <<~EOM 
    # H1 Lorem ipsum
    
    Dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna.
    * Aliquyam erat, sed diam voluptua. 
    * At vero eos et accusam et justo duo dolores et ea rebum. 
    * Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. 
    
    ## H2 Lorem ipsum dolor sit amet.
    
    [Consetetur sadipscing elitr](#lorem), sed diam nonumy eirmod tempor invidunt 
    Ut labore et dolore magna aliquyam erat, sed diam voluptua. 
    
    At vero eos et accusam et justo duo dolores et ea rebum. 
    Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.

    ![Logo](https://upload.wikimedia.org/wikipedia/commons/thumb/b/b0/Openstreetmap_logo.svg/160px-Openstreetmap_logo.svg.png)
  EOM
end


# Users

admin = User.find_or_initialize_by(:email => "superadmin@osm.dev")
admin.update_attributes(
  :email => "superadmin@osm.dev",
  :email_valid => true,
  :display_name => "SuperAdminUser",
  :description => lorem_ipsum_markdown,
  :home_lat => "52.5170365",
  :home_lon => "13.3888599",
  :status => "confirmed",
  :terms_seen => true,
  :terms_agreed => Time.now.getutc,
  :data_public => true,
  :pass_crypt => "password",
  :pass_crypt_confirmation => "password",
)
admin.roles.create(:role => "administrator", :granter_id => admin.id )

moderator = User.find_or_initialize_by(:email => "moderator@osm.dev")
moderator.update_attributes(
  :email_valid => true,
  :display_name => "ModeratorUser",
  :home_lat => "52.5170365",
  :home_lon => "13.3888599",
  :status => "confirmed",
  :terms_seen => true,
  :terms_agreed => Time.now.getutc,
  :data_public => true,
  :pass_crypt => "password",
  :pass_crypt_confirmation => "password",
)
moderator.roles.create(:role => "moderator", :granter => admin)

blogger = User.find_or_initialize_by(:email => "blogger@osm.dev")
blogger.update_attributes(
  :email_valid => true,
  :display_name => "BloggerUser",
  :description => lorem_ipsum_markdown,
  :home_lat => "52.5170365",
  :home_lon => "13.3888599",
  :status => "confirmed",
  :terms_seen => true,
  :terms_agreed => Time.now.getutc,
  :data_public => true,
  :pass_crypt => "password",
  :pass_crypt_confirmation => "password",
)

commenter = User.find_or_initialize_by(:email => "commenter@osm.dev")
commenter.update_attributes(
  :email_valid => true,
  :display_name => "CommentUser",
  :status => "confirmed",
  :terms_seen => false,
  :data_public => false,
  :pass_crypt => "password",
  :pass_crypt_confirmation => "password",
)


# Diary entries

diary_entry1 = DiaryEntry.create(
  :title => "Diary entry 1 => Short Title",
  :body => lorem_ipsum_markdown,
  :user => blogger,
)

diary_entry2 = DiaryEntry.create(
  :title => "Diary entry 2 => Long Title Long Title Long Title Long Title Long Title",
  :body => lorem_ipsum + lorem_ipsum_markdown + lorem_ipsum,
  :latitude => "52.5170365",
  :longitude => "13.3888599",
  :user => blogger,
)

10.times do |i|
  DiaryEntry.create(
    :title => "Diary entry #{i+3} => #{i+1} of 10",
    :body => lorem_ipsum_markdown,
    :latitude => i,
    :longitude => i,
    :user => blogger
  )
end

comment3 = DiaryComment.create(
  :diary_entry => diary_entry1,
  :user => commenter,
  :body => "First!!1",
)

comment2 = DiaryComment.create(
  :diary_entry => diary_entry1,
  :user => blogger,
  :body => "Good job",
)

comment3 = DiaryComment.create(
  :diary_entry => diary_entry1,
  :user => commenter,
  :body => lorem_ipsum_markdown,
)

5.times do |i|
  DiaryComment.create(
    :diary_entry => diary_entry2,
    :user => commenter,
    :body => lorem_ipsum[i*10]
  )
end


# OAuth Consumer Key for iD Editor
# Learn more at https://github.com/openstreetmap/openstreetmap-website/blob/master/CONFIGURE.md#oauth-consumer-keys

application_params = {
  :name => "iD #{Time.now.getutc}", 
  :url => "http://localhost:3000",
  :allow_read_prefs => true,
  :allow_write_api => true,
}
client_application = admin.client_applications.build(application_params)
client_application.save
