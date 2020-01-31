Given("there is a microcosm {string}, {string}, {string}, {string}, {string}, {string}, {string}, {string}") do |name, location, lat, lon, min_lat, max_lat, min_lon, max_lon|
  @the_microcosm = Microcosm.create!(
    :name => name,
    :location => location,
    :lat => lat,
    :lon => lon,
    :min_lat => min_lat,
    :min_lon => min_lon,
    :max_lat => max_lat,
    :max_lon => max_lon
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
  expect(page).to have_css("#microcosm_map")
  expect(page).to have_css(".leaflet-container")
  coords = page.evaluate_script("window.map.getCenter()")
  expect(coords['lat']).to eq(@the_microcosm.lat)
  expect(coords['lng']).to eq(@the_microcosm.lon)
end

Given("I am on the microcosm edit page") do
  visit edit_microcosm_path(@the_microcosm)
end

Given("there is an event for this microcosm") do
  @the_event = Event.create!(
    :title => "Some Event",
    :moment => DateTime.now,
    :location => "Some Location",
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

Given("the user belongs to the microcosm") do
  @the_microcosm.microcosm_members.create!(:user_id => @the_user.id, :role => MicrocosmMember::Roles::MEMBER)
end

Given("this user is an organizer of this microcosm") do
  @the_microcosm.microcosm_members.create!(:user_id => @the_user.id, :role => MicrocosmMember::Roles::ORGANIZER)
end

Then("I should see the microcosm {string} name") do |name|
  expect(page).to have_content(name)
end

And("I set the microcosm in {string} to {string}, {string}, {string}") do |scope, name, lat, lon|
  within(scope) do
    fill_in "Name", :with => name
    fill_in "Location", :with => name
    fill_in "Latitude", :with => lat
    fill_in "Longitude", :with => lon
    fill_in "Minimum Latitude", :with => lat
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
  expect(page).to have_link(title, :href => href)
end

Then("I should see {string}") do |msg|
  expect(page).to have_content(msg, :normalize_ws => true)
end

Then("I should not see {string}") do |msg|
  expect(page).not_to have_content(msg)
end

Then("I should see a {string} button") do |title|
  expect(page).to have_selector(:link_or_button, title)
end

Then("I should be forbidden") do
  expect(page.status_code).to eq(403)
end

And("I click {string}") do |title|
  within("#content") do
    click_link(title)
  end
end

And("Within {string} I click the {int} {string}") do |scope, nth, text|
  within(scope) do
    find(:xpath, "(.//a[contains(text(), #{text})])[#{nth}]").click
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
