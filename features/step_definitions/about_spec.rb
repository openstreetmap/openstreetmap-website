Given("there is this microcosm:") do |table|
  attribs = table.rows_hash
  attribs["description"] = "Some description"
  attribs["latitude"] = Float(attribs["latitude"])
  attribs["longitude"] = Float(attribs["longitude"])
  @the_microcosm = Microcosm.create!(attribs)
end

Given("there is a changeset by {string} at {string}, {string}, {string}, {string} with comment {string}") do |author, min_lat, max_lat, min_lon, max_lon, comment|
  ch = Changeset.create!(
    :user => User.find_by(:display_name => author),
    :created_at => Time.now.utc,
    :closed_at => Time.now.utc + 1.day,
    :min_lat => (min_lat.to_i * GeoRecord::SCALE),
    :max_lat => (max_lat.to_i * GeoRecord::SCALE),
    :min_lon => (min_lon.to_i * GeoRecord::SCALE),
    :max_lon => (max_lon.to_i * GeoRecord::SCALE),
    :num_changes => 0
  )
  ChangesetTag.create!(
    :changeset => ch,
    :k => "comment",
    :v => comment
  )
end

Given("I am on the microcosms page") do
  visit microcosms_path
end

Given("I am on the microcosm {string} page") do |name|
  visit microcosm_path(Microcosm.find_by(:name => name))
end

Given("I am on the microcosm page by id") do
  visit microcosm_path(@the_microcosm)
end

Then("I should see a map of the microcosm centered at their AOI") do
  assert page.has_css? "#microcosm_map"
  assert page.has_css? ".leaflet-container"
  coords = page.evaluate_script("window.map.getCenter()")
  assert coords["lat"] == @the_microcosm.lat
  assert coords["lng"] == @the_microcosm.lon
end

Given("I am on the microcosm edit page") do
  visit edit_microcosm_path(@the_microcosm)
end

Given("there is an event for this microcosm") do
  @the_event = Event.create!(
    :title => "Some Event",
    :moment => DateTime.now,
    :location => "Some Location",
    :location_url => "https://en.wikipedia.org/wiki/Washington_Monument",
    :latitude => 12.34,
    :longitude => 56.78,
    :description => "Some description",
    :microcosm_id => @the_microcosm.id
  )
end

Given("I am on this event page") do
  visit event_path(@the_event)
end

Given("I am on the all events page") do
  visit events_path
end

# The lines like "The microcosm HAS..." are not behavior driven because it's using @varibles.

Given("the microcosm has the {string} page {string}") do |site, url|
  @the_microcosm.set_link(site, url)
  @the_microcosm.save
end

Given("the microcosm has description {string}") do |desc|
  @the_microcosm.description = desc
  @the_microcosm.save
end

Given("this user is a(n) {string} of this microcosm") do |role|
  @the_microcosm.microcosm_members.create!(:user_id => @the_user.id, :role => role)
end

Given("this microcosm has no organizers") do
  @the_microcosm.organizers.map(&:destroy)
end

Then("I should see the microcosm {string} name") do |name|
  within(".content-heading") do
    page.assert_text name
  end
end

And("I set the microcosm in {string} to {string}, {string}, {string}") do |scope, name, lat, lon|
  within(scope) do
    fill_in "Name", :with => name
    fill_in "Location", :with => name
    fill_in "Latitude", :with => lat
    fill_in "Longitude", :with => lon
    fill_in "Minimum Latitude", :with => lat # TODO: Parameterize this.
    fill_in "Maximum Latitude", :with => lat
    fill_in "Minimum Longitude", :with => lon
    fill_in "Maximum Longitude", :with => lon
    fill_in "Description", :with => name
  end
end

And("I set the event to {string}, {string}, {string}, {string}") do |title, moment, location, description|
  within("#content") do
    fill_in "Title", :with => title
    fill_in "When", :with => moment
    fill_in "Location", :with => location
    fill_in "Description", :with => description
  end
end

And("I set the user to {string}") do |role|
  within("#content") do
    select role, :from => "Role"
  end
end

And("I submit the form") do
  within("#content") do
    find('form input[type="submit"]').click
  end
end

# Not microcosm specific.

Given("{string} is an administrator") do |email|
  user = User.find_by(:email => email)
  user.roles.create(:role => "administrator", :granter => user)
  user.save
end

When("print body") do
  print body
end

Then("I should see the {string} link to {string}") do |title, href|
  assert page.has_link? title, :href => href
end

Then("I should see {string}") do |msg|
  page.assert_text msg, :normalize_ws => true
end

Then("I should not see {string}") do |msg|
  page.assert_no_text msg
end

Then("I should see a {string} button") do |title|
  assert page.has_button? title
end

Then("I should not see a {string} button") do |title|
  assert !page.has_button?(title)
end

Then("I should be forbidden") do
  assert page.status_code == 403
end

And("I click {string}") do |title|
  within("#content") do
    click_link(title)
  end
end

And("Within {string} I click the {string} {string}") do |scope, nth, locator|
  within(scope) do
    # all(:link_or_button).each do |el|
    #   puts el.inspect
    #   puts el.value
    # end
    all(:link_or_button, locator)[unordinalize(nth)].click
  end
end

And("I click the link to {string}") do |url|
  find("a[href='#{url}']").click
end

And("I press {string}") do |title|
  click_button title
end

When("user {string} logs in") do |username|
  visit login_path
  within("#login_form") do
    fill_in "username", :with => username
    fill_in "password", :with => "test"
    click_button "Login"
  end
end

Given("there is a user {string} with name {string}") do |username, name|
  @the_user = create(:user, :email => username, :display_name => name)
end

When("I logout") do
  visit logout_path
end

def unordinalize(ordinal)
  ordinal.scan(/^\d+/).first.to_i - 1
end
