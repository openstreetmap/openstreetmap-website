Given("there is a microcosm {string}, {string}, {string}, {string}, {string}, {string}, {string}, {string}") do |name, location, lat, lon, min_lat, max_lat, min_lon, max_lon|
  @the_microcosm = Microcosm.create!(
      :name => name,
      :location => location,
      :lat => lat,
      :lon => lon,
      :min_lat => min_lat,
      :min_lon => min_lon,
      :max_lat => max_lat,
      :max_lon => max_lon,
  )
end

Given("I am on the microcosms page") do
  visit "/microcosms"
end

Given("I am on the microcosm {string} page") do |name|
  visit "/microcosms/" + name.downcase
end

Given("I am on the microcosm {string} page by id") do |name|
  visit "/microcosms/#{@the_microcosm.id}"
end

Given("I am on the microcosm edit page") do
  visit "/microcosms/#{@the_microcosm.id}/edit"
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
  @the_microcosm.microcosm_members.create!(:user_id => @user_1.id, :role => MicrocosmMember::Roles::MEMBER)
end

Given("this user is an organizer of this microcosm") do
  @the_microcosm.microcosm_members.create!(:user_id => @user_1.id, :role => MicrocosmMember::Roles::ORGANIZER)
end

Then("I should see the microcosm {string} name") do |name|
  expect(page).to have_content(name)
end


And("I set the microcosm to {string}, {string}, {string}, {string}") do |scope, name, lat, lon|
  within(scope) do
    fill_in "Name", with: name
    fill_in "Location", with: name
    fill_in "Lat", with: lat
    fill_in "Lon", with: lon
    fill_in "Min lat", with: lat
    fill_in "Max lat", with: lat
    fill_in "Min lon", with: lon
    fill_in "Max lon", with: lon
    fill_in "Description", with: name
  end
end

And("I set the event to {string}, {string}, {string}") do |title, location, description|
  within("#content") do
    fill_in "Title", with: title
    fill_in "Location", with: location
    fill_in "Description", with: description
  end
end

And("I set the user to {string}") do |role|
  within("#content") do
    select role, :from => 'Role'
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
  user.roles.create(:role => 'administrator', :granter => user)
  user.save
end

When("print body") do
  print body
end

Then("I should see the {string} link to {string}") do |title, href|
  expect(page).to have_link(title, :href => href)
end

Then("I should see {string}") do |msg|
  expect(page).to have_content(msg)
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

And("I click the link to {string}") do |url|
  find("a[href='#{url}']").click
end

And("I press {string}") do |title|
  click_button title
end


When("user {string} logs in") do |username|
  visit "/login"
  within("#login_form") do
    fill_in 'username', with: username
    fill_in 'password', with: "test"
    click_button 'Login'
  end
end

Given("there is a user {string} with name {string}") do |username, name|
  @user_1 = create(:user, :email => username, :display_name => name)
end
