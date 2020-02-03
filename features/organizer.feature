Feature: Manage a Microcosm
  In order to manage microcosms
  as an organizer
  I want to manage the microcosm

  Background:
    Given there is a microcosm "MappingDC", "Washington, DC, USA", "38.9", "-77.03", "38.516", "39.472", "-77.671", "-76.349"
    And the microcosm has description "MappingDC strives to improve OSM in the DC area"
    And the microcosm has the "Facebook" page "https://facebook.com/groups/mappingdc"
    And the microcosm has the "Twitter" page "https://twitter.com/mappingdc"
    And the microcosm has the "Website" page "https://mappingdc.org"
    And I am on the microcosm "MappingDC" page


  Scenario: Edit a microcosm
    Given there is a user "abe@example.com" with name "Abe"
    And this user is an organizer of this microcosm
    When user "abe@example.com" logs in
    And I am on the microcosms page
    And I click the link to "/microcosms/mappingdc/edit"
    And I set the microcosm in ".edit_microcosm" to "Baltimore", "40", "-76"
    And I submit the form
    Then I should not see "Washington, DC, USA"
    Then I should see "Baltimore"

  Scenario: Promote a user to organizer
    Given there is a user "organizer@example.com" with name "Organizer"
    And this user is an organizer of this microcosm
    Given there is a user "promotee@example.com" with name "Promotee"
    And the user belongs to the microcosm
    When user "organizer@example.com" logs in
    And I am on the microcosm "MappingDC" page
    And I click "Members"
    And Within ".members" I click the 2 "edit"
    And I set the user to "Organizer"
    And I submit the form
    Then I should see "Organizers Organizer Promotee"

  Scenario: Create an event
    Given there is a user "abe@example.com" with name "Abe"
    And this user is an organizer of this microcosm
    When user "abe@example.com" logs in
    And I am on the microcosm "MappingDC" page
    And I click "Upcoming Events"
    And I click "new event"
    And I set the event to "Update DC Bike Lanes", "2030-01-20T12:34", "DC Library", "We will update the dc bike lane data in OSM."
    And I submit the form
    And I am on the microcosm "MappingDC" page
    Then I should see "Update DC Bike Lanes"
    And I click "Update DC Bike Lanes"
    Then I should see "Update DC Bike Lanes"
    And I should see "Location: DC Library"
    And I should see "Description: We will update the dc bike lane data in OSM."
    And I should see "Organized by: Abe"
    And I should see "20 January 2030 at 12:34"
