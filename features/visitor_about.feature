Feature: Learn about the Microcosm
  In order to learn about this microcosm
  as a visitor
  I want to read their webpage

  Background:
    Given there is a microcosm "MappingDC", "Washington, DC, USA", "38.9", "-77.03", "38.516", "39.472", "-77.671", "-76.349"
    And the microcosm has description "MappingDC strives to improve OSM in the DC area"
    And the microcosm has the "Facebook" page "https://facebook.com/groups/mappingdc"
    And the microcosm has the "Twitter" page "https://twitter.com/mappingdc"
    And the microcosm has the "Website" page "https://mappingdc.org"
    And I am on the microcosm "MappingDC" page


  Scenario: The microcosm should be listed
    When I am on the microcosms page
    Then I should see "MappingDC"


  Scenario: Describe the microcosm
    Then I should see the microcosm "MappingDC" name
    Then I should see "Washington, DC, USA"
    Then I should see the "Facebook" link to "https://facebook.com/groups/mappingdc"
    Then I should see the "Twitter" link to "https://twitter.com/mappingdc"
    Then I should see the "Website" link to "https://mappingdc.org"
    Then I should see "MappingDC strives to improve OSM in the DC area"


  Scenario: Can load by id
    Then I am on the microcosm page by id
    Then I should see "MappingDC strives to improve OSM in the DC area"


#  @javascript
#  Scenario: Can see a map of the microcosm area
#    When I am on the microcosm page by id
#    Then I should see a map of the microcosm centered at their AOI


  Scenario: Regular user cannot edit the microcosm
    Given there is a user "abe@example.com" with name "Abe"
    When user "abe@example.com" logs in
    When I am on the microcosm edit page
    Then I should be forbidden


  Scenario: Logged out user sees message to join microcosm
    Given there is a user "abe@example.com" with name "Abe"
    When I am on the microcosm "MappingDC" page
    Then I press "Join"


  Scenario: A user may join a microcosm
    Given there is a user "abe@example.com" with name "Abraham"
    When user "abe@example.com" logs in
    And I am on the microcosm "MappingDC" page
    And I should see a "Join" button
    And I press "Join"
    Then I should see "Abraham"


  Scenario: See upcoming events
    Given there is a user "abe@example.com" with name "Abe"
    And this user is an organizer of this microcosm
    When user "abe@example.com" logs in
    And I am on the microcosm "MappingDC" page
    And I click "Upcoming Events"
    And I click "new event"
    And I set the event to "Update DC Bike Lanes", "2030-01-20T12:34", "DC Library", "We will update the dc bike lane data in OSM."
    And I submit the form
    And I logout
    And I am on the microcosm "MappingDC" page
    And I click "Upcoming Events"
    Then I should see "Update DC Bike Lanes"
    When I am on the all events page
    Then I should see "Update DC Bike Lanes"


  Scenario: See recent changesets
    Given there is a user "abe@example.com" with name "Abe"
    And there is a changeset by "Abe" at "38.8", "39.1", "-77.1", "-76.8" with comment "Add public bookcase"
    And there is a changeset by "Abe" at "138.8", "139.1", "-7.1", "-6.8" with comment "Add library"
    When I am on the microcosm "MappingDC" page
    Then I should see "Add public bookcase"
    And I should not see "Add library"
