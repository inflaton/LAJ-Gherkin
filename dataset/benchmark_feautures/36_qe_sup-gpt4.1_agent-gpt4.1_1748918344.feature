Feature: Retrieve all tags for an account via GET /1.0/kb/accounts/{accountId}/allTags
As a KillBill API user,
I want to retrieve all tags for a given account, optionally filtered by object type, including deleted tags and audit information,
so that I can understand the tagging state of the account and related objects for compliance, reporting, or operational purposes.

  Background:
  Given the KillBill API is running and accessible
  And the API authentication token is valid and present in the request headers
  And the database is seeded with accounts having diverse tags across all supported object types
  And some accounts have no tags, some have deleted tags, and some have tags with audit information
  And the accountId used in tests is a valid UUID unless otherwise specified

    @TC01
    Scenario: Successful retrieval of all tags for an account with no query parameters
    Given an account with multiple tags across different object types exists
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags with a valid accountId and no query parameters
    Then the response status should be 200
    And the response body should be a JSON array of Tag objects containing all tags for the account (excluding deleted tags)
    And each Tag object should conform to the Tag schema
    And the audit information in the response should be NONE

    @TC02
    Scenario: Retrieve tags filtered by a specific objectType
    Given an account with tags attached to multiple object types exists
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags with objectType set to INVOICE
    Then the response status should be 200
    And the response body should only include Tag objects where objectType is INVOICE
    And deleted tags should not be included

    @TC03
    Scenario: Retrieve tags including deleted tags
    Given an account with both active and deleted tags exists
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags with includedDeleted set to true
    Then the response status should be 200
    And the response body should include both active and deleted Tag objects

    @TC04
    Scenario: Retrieve tags with audit information set to FULL
    Given an account with tags exists
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags with audit set to FULL
    Then the response status should be 200
    And each Tag object should include full audit information in the response

    @TC05
    Scenario: Retrieve tags with audit information set to MINIMAL
    Given an account with tags exists
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags with audit set to MINIMAL
    Then the response status should be 200
    And each Tag object should include minimal audit information in the response

    @TC06
    Scenario: Retrieve tags with all combinations of objectType, includedDeleted, and audit parameters
    Given an account with tags (active and deleted) across all object types exists
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags with objectType set to PAYMENT, includedDeleted set to true, and audit set to FULL
    Then the response status should be 200
    And the response body should only include Tag objects where objectType is PAYMENT, including deleted tags, with full audit information

    @TC07
    Scenario: Retrieve tags for an account with no tags
    Given an account exists with no tags
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 200
    And the response body should be an empty JSON array

    @TC08
    Scenario: Retrieve tags for a non-existent account
    Given an accountId that does not exist in the system
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 404
    And the response body should contain an error message indicating account not found

    @TC09
    Scenario: Invalid accountId supplied (malformed UUID)
    Given an accountId that is not a valid UUID format
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 400
    And the response body should contain an error message indicating invalid accountId

    @TC10
    Scenario: Unauthorized access attempt
    Given the API authentication token is missing or invalid
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC11
    Scenario: System error - downstream service unavailable
    Given the downstream tag storage service is unavailable
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 503
    And the response body should contain an error message indicating service unavailable

    @TC12
    Scenario: Security test - SQL injection attempt in accountId
    Given an accountId containing SQL injection payload (e.g., "abc' OR '1'='1")
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 400
    And the response body should not expose any internal server information

    @TC13
    Scenario: Extra unsupported query parameters
    Given a valid accountId
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags with an unsupported query parameter foo=bar
    Then the response status should be 200
    And the response body should be as if the unsupported parameter was not provided

    @TC14
    Scenario: Large number of tags (performance and response size)
    Given an account with a large number of tags (e.g., 10,000 tags)
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 200
    And the response time should be within acceptable thresholds (e.g., < 2 seconds)
    And the response body should contain all tags

    @TC15
    Scenario: Timeout due to long-running operation
    Given the backend is intentionally slowed to simulate a timeout
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 504
    And the response body should contain an error message indicating timeout

    @TC16
    Scenario: Regression - previously fixed bug where deleted tags were always excluded
    Given an account with deleted tags and includedDeleted set to true
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 200
    And the response body should include deleted tags

    @TC17
    Scenario: Backward compatibility - clients using no query parameters
    Given a client using a previous version of the API with no query parameters
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 200
    And the response should be identical to the default parameter values

    @TC18
    Scenario: Integration - tags consistency after adding a tag via another API
    Given a tag is added to an account via POST /1.0/kb/accounts/{accountId}/tags
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 200
    And the new tag should be present in the response

    @TC19
    Scenario: Integration - tags consistency after deleting a tag via another API
    Given a tag is deleted from an account via DELETE /1.0/kb/accounts/{accountId}/tags/{tagId}
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags with includedDeleted set to true
    Then the response status should be 200
    And the deleted tag should be present in the response

    @TC20
    Scenario: Edge case - minimum allowed values for parameters
    Given an account with tags exists
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags with audit set to NONE and includedDeleted set to false
    Then the response status should be 200
    And the response body should include only active tags with no audit information

    @TC21
    Scenario: Edge case - maximum allowed values for parameters
    Given an account with tags exists
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags with audit set to FULL and includedDeleted set to true
    Then the response status should be 200
    And the response body should include all tags (active and deleted) with full audit information

    @TC22
    Scenario: Partial and unexpected input formats for query parameters
    Given an account with tags exists
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags with audit set to "partial" (an invalid value)
    Then the response status should be 400
    And the response body should contain an error message indicating invalid audit value

    @TC23
    Scenario: Concurrency - multiple requests for the same account
    Given an account with tags exists
    When 10 concurrent requests are made to GET /1.0/kb/accounts/{accountId}/allTags
    Then all responses should be 200
    And all response bodies should be consistent and correct

    @TC24
    Scenario: Integration - dependent service returns inconsistent data
    Given the tag storage service returns inconsistent data for the same account
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags multiple times
    Then the API should handle the inconsistency gracefully and log a warning

    @TC25
    Scenario: State variation - database is empty
    Given the database contains no accounts
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 404
    And the response body should indicate account not found

    @TC26
    Scenario: State variation - account exists but is soft-deleted
    Given an account exists but is marked as deleted (soft-deleted)
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response status should be 404
    And the response body should indicate account not found or deleted

    @TC27
    Scenario: API returns correct Content-Type
    Given an account with tags exists
    When the user calls GET /1.0/kb/accounts/{accountId}/allTags
    Then the response header Content-Type should be application/json

    @TC28
    Scenario: Accessibility - response is readable by screen readers (if UI involved)
    Given a UI client displays the tags retrieved from the API
    When the UI renders the tags
    Then the tags and metadata should be accessible to screen readers and meet accessibility standards