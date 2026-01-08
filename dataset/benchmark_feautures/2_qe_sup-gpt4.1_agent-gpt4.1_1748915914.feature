Feature: Add tags to account via POST /1.0/kb/accounts/{accountId}/tags
As a KillBill API user,
I want to add tags to a specific account,
so that I can manage account metadata effectively.

  Background:
  Given the KillBill API is available
  And the database contains accounts with various valid and invalid UUIDs
  And valid tag definitions exist in the system
  And I have a valid authentication token
  And I have the correct permissions to add tags

    @TC01
    Scenario: Successful addition of multiple tags to an account
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1", "tag-def-uuid-2"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1", "tag-def-uuid-2"]
    Then the response status should be 201
    And the response body should be a JSON array of Tag objects matching the posted tag definitions
    And the tags should be associated with the account in the database

    @TC02
    Scenario: Successful addition of a single tag to an account
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition ID ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1"]
    Then the response status should be 201
    And the response body should be a JSON array of Tag objects with one entry
    And the tag should be associated with the account in the database

    @TC03
    Scenario: Addition of tags with optional headers provided
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    And header "X-Killbill-Reason" is set to "testing"
    And header "X-Killbill-Comment" is set to "QA scenario"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1"]
    Then the response status should be 201
    And the response body should be a JSON array of Tag objects
    And the tags should be associated with the account in the database

    @TC04
    Scenario: Addition of tags when no tags previously exist for the account
    Given an existing account with accountId "valid-account-uuid" and no tags
    And valid tag definition IDs ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1"]
    Then the response status should be 201
    And the tag should be associated with the account in the database

    @TC05
    Scenario: Addition of tags when tags already exist for the account
    Given an existing account with accountId "valid-account-uuid" and existing tags ["tag-def-uuid-3"]
    And valid tag definition IDs ["tag-def-uuid-1", "tag-def-uuid-2"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1", "tag-def-uuid-2"]
    Then the response status should be 201
    And the response body should include all tags ["tag-def-uuid-1", "tag-def-uuid-2", "tag-def-uuid-3"]
    And the new tags should be associated with the account in the database

    @TC06
    Scenario: Addition of tags with pagination, sorting, or filtering parameters (should be ignored)
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags?limit=10&offset=0&sort=asc with body ["tag-def-uuid-1"]
    Then the response status should be 201
    And the response body should be a JSON array of Tag objects
    And the pagination, sorting, and filtering parameters should have no effect

    @TC07
    Scenario: Addition of tags with empty request body
    Given an existing account with accountId "valid-account-uuid"
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body []
    Then the response status should be 400
    And the response body should contain an error message indicating the request body is invalid

    @TC08
    Scenario: Addition of tags with malformed request body (not an array)
    Given an existing account with accountId "valid-account-uuid"
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body {"not": "an array"}
    Then the response status should be 400
    And the response body should contain an error message indicating malformed request body

    @TC09
    Scenario: Addition of tags with invalid tag definition IDs (malformed UUID)
    Given an existing account with accountId "valid-account-uuid"
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["not-a-uuid"]
    Then the response status should be 400
    And the response body should indicate invalid tag definition ID format

    @TC10
    Scenario: Addition of tags with non-existent tag definition IDs
    Given an existing account with accountId "valid-account-uuid"
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["non-existent-tag-def-uuid"]
    Then the response status should be 400
    And the response body should indicate tag definition not found

    @TC11
    Scenario: Addition of tags with missing required header X-Killbill-CreatedBy
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1"]
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1"] and without header "X-Killbill-CreatedBy"
    Then the response status should be 400
    And the response body should indicate missing required header

    @TC12
    Scenario: Addition of tags with missing accountId in path
    Given valid tag definition IDs ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts//tags with body ["tag-def-uuid-1"]
    Then the response status should be 400
    And the response body should indicate invalid or missing accountId

    @TC13
    Scenario: Addition of tags with invalid accountId format
    Given accountId "invalid-account-id"
    And valid tag definition IDs ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/invalid-account-id/tags with body ["tag-def-uuid-1"]
    Then the response status should be 400
    And the response body should indicate invalid accountId format

    @TC14
    Scenario: Addition of tags to non-existent account
    Given accountId "non-existent-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/non-existent-account-uuid/tags with body ["tag-def-uuid-1"]
    Then the response status should be 400
    And the response body should indicate account not found

    @TC15
    Scenario: Unauthorized attempt to add tags (missing or invalid authentication token)
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1"] and without authentication token
    Then the response status should be 401
    And the response body should indicate unauthorized access

    @TC16
    Scenario: System error during tag addition (dependency failure)
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    And the tag service is unavailable
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1"]
    Then the response status should be 503
    And the response body should indicate service unavailable

    @TC17
    Scenario: Addition of tags with extra unexpected parameters in request body
    Given an existing account with accountId "valid-account-uuid"
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1", {"extra": "field"}]
    Then the response status should be 400
    And the response body should indicate invalid request body

    @TC18
    Scenario: Addition of tags with large number of tag definition IDs (boundary test)
    Given an existing account with accountId "valid-account-uuid"
    And a list of 100 valid tag definition IDs
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body containing 100 tag definition UUIDs
    Then the response status should be 201
    And the response body should be a JSON array of 100 Tag objects

    @TC19
    Scenario: Addition of tags with duplicate tag definition IDs in the request
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1", "tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1", "tag-def-uuid-1"]
    Then the response status should be 201
    And the response body should contain only one Tag object for the duplicated tag definition

    @TC20
    Scenario: Addition of tags with slow response (performance test)
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1"]
    Then the response should be received within 2 seconds

    @TC21
    Scenario: Addition of tags under concurrent requests
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1", "tag-def-uuid-2"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags concurrently from 10 clients with body ["tag-def-uuid-1", "tag-def-uuid-2"]
    Then all responses should be 201 or appropriate error code if duplicate
    And the account should not have duplicate tags

    @TC22
    Scenario: Addition of tags with injection attempt in header
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user<script>alert(1)</script>"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-1"]
    Then the response status should be 400 or 201 (based on sanitization)
    And the response body should not reflect the script content

    @TC23
    Scenario: Regression - previously fixed issue: adding tags to account with special characters in tag definition IDs
    Given an existing account with accountId "valid-account-uuid"
    And tag definition ID "tag-def-uuid-!@#$%"
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags with body ["tag-def-uuid-!@#$%"]
    Then the response status should be 400
    And the response body should indicate invalid tag definition ID format

    @TC24
    Scenario: Regression - backward compatibility with previous API version
    Given an existing account with accountId "valid-account-uuid"
    And valid tag definition IDs ["tag-def-uuid-1"]
    And header "X-Killbill-CreatedBy" is set to "test-user"
    When I POST to /1.0/kb/accounts/valid-account-uuid/tags using API version 1.0
    Then the response status should be 201
    And the response body should be a JSON array of Tag objects