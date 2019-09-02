Feature: Learn about the Microcosm
  In order to learn about this microcosm
  as a visitor
  I want to read their webpage

  Background:
    Given there is a microcosm "MappingDC"
    And the microcosm has the "Facebook" page "https://facebook.com/groups/mappingdc"
    And the microcosm has the "Twitter" page "https://twitter.com/mappingdc"
    And the microcosm has the "Website" page "https://mappingdc.org"
    And the microcosm has description "MappingDC strives to improve OSM in the DC area"
    And I am on the microcosm "MappingDC" page


  Scenario: The microcosm should be listed
    When I am on the microcosms page
    Then I should see "MappingDC"


  Scenario: Describe the microcosm
    Then I should see the microcosm "MappingDC" name
    Then I should see the "Facebook" link to "https://facebook.com/groups/mappingdc"
    Then I should see the "Twitter" link to "https://twitter.com/mappingdc"
    Then I should see the "Website" link to "https://mappingdc.org"
    Then I should see "MappingDC strives to improve OSM in the DC area"


  Scenario: Can load by id
    Then I am on the microcosm "MappingDC" page by id
    Then I should see "MappingDC strives to improve OSM in the DC area"


  Scenario: Regular user cannot edit the microcosm
    Given there is a user "abe@example.com" with name "Abe"
    When user "abe@example.com" logs in
    When I am on the microcosm edit page
    Then I should be forbidden


  Scenario: Logged out user sees message to join microcosm
    Given there is a user "abe@example.com" with name "Abe"
    When I am on the microcosm "MappingDC" page
    Then I should see "Log in to join this microcosm."


  Scenario: A user may join a microcosm
    Given there is a user "abe@example.com" with name "Abraham"
    When user "abe@example.com" logs in
    And I am on the microcosm "MappingDC" page
    And I should see a "Join" button
    And I press "Join"
    Then I should see "Abraham"