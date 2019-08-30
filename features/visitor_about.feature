Feature: Learn about the Microcosm
  In order to learn about this microcosm
  as a vistitor
  I want to read their webpage

  Background:
    Given there is a microcosm "MappingDC"
    And the microcosm has facebook page "mappingdc"
    And the microcosm has twitter account "mappingdc"
    And the microcosm has description "MappingDC strives to improve OSM in the DC area"
    And I am on the microcosm "MappingDC" page


  Scenario: Describe the microcosm
    Then I should see the microcosm "MappingDC" name
    Then I should see the "Facebook" link to "https://facebook.com/groups/mappingdc"
    Then I should see the "Twitter" link to "https://twitter.com/mappingdc"
    Then I should see "MappingDC strives to improve OSM in the DC area"


  Scenario: Can load by id
    Then I am on the microcosm "MappingDC" page by id
    Then I should see "MappingDC strives to improve OSM in the DC area"


  Scenario: Regular user cannot edit the microcosm
    Given there is a user "abe@example.com"
    When user "abe@example.com" logs in
    When I am on the microcosm edit page
    Then I should be forbidden
