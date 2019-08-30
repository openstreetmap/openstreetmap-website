Given("there is a microcosm {string}") do |name|
  @the_microcosm = Microcosm.create!(:name => name, :key => name.downcase)
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

# TODO: These "has" specs can be refactored.
Given("the microcosm has facebook page {string}") do |fb|
  @the_microcosm.facebook = fb
  @the_microcosm.save
end

Given("the microcosm has twitter account {string}") do |acct|
  @the_microcosm.twitter = acct
  @the_microcosm.save
end

Given("the microcosm has description {string}") do |desc|
  @the_microcosm.description = desc
  @the_microcosm.save
end

When("print body") do
  print body
end

Then("I should see the microcosm {string} name") do |name|
  expect(page).to have_content(name)
end



# Not microcosm specific.

Then("I should see the {string} link to {string}") do |title, href|
  expect(page).to have_link(title, :href => href)
end

Then("I should see {string}") do |msg|
  expect(page).to have_content(msg)
end

Then("I should be forbidden") do
  expect(page.status_code).to eq(403)
end

When("user {string} logs in") do |username|
  visit "/login"
  within("#login_form") do
    fill_in 'username', with: username
    fill_in 'password', with: "test"
    click_button 'Login'
  end
end

Given("there is a user {string}") do |username|
  @user_1 = create(:user, :email => username)
end
