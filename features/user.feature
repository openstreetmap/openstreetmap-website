Feature: User associated operations for a Microcosm
  In order to use microcosms
  as a user
  I want to create the microcosm

  Background:
    Given there is a microcosm "MappingDC", "Washington, DC, USA", "38.9", "-77.03", "38.516", "39.472", "-77.671", "-76.349"
    And the microcosm has description "MappingDC strives to improve OSM in the DC area"
    And the microcosm has the "Facebook" page "https://facebook.com/groups/mappingdc"
    And the microcosm has the "Twitter" page "https://twitter.com/mappingdc"
    And the microcosm has the "Website" page "https://mappingdc.org"
    And I am on the microcosm "MappingDC" page

  Scenario: Create a microcosm
    Given there is a user "abe@example.com" with name "Abe"
    When user "abe@example.com" logs in
    And I am on the microcosms page
    And I click the link to "/microcosms/new"
    And I set the microcosm in "#new_microcosm" to "Baltimore", "38", "-77"
    And I submit the form
    Then I should see "Baltimore"

  Scenario: Step up
    Given there is a user "abe@example.com" with name "Abe"
    Given this microcosm has no organizers
    When user "abe@example.com" logs in
    And I am on the microcosm "MappingDC" page
    And I click "Step up"
    Then I should not see "Organizers Abe"
