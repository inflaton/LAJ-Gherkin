Feature: Retrieve account tags via GET /1.0/kb/accounts/{accountId}/tags
As a KillBill API user,
I want to retrieve tags for a specific account,
so that I can view all relevant tags, including audit and deleted tag options.

  Background:
  Given the KillBill API is running and accessible
  And the database contains accounts with various tag states (active, deleted, none)
  And valid and invalid account UUIDs are identified for testing
  And authentication tokens are set up for authorized requests
  And the API endpoint /1.0/kb/accounts/{accountId}/tags is available

    @TC01
    Scenario: Successful retrieval of tags with only required path parameter (happy path)
    Given an account exists with the accountId 'valid-account-uuid'
    And the account has multiple active tags
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags without query parameters
    Then the response status should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array of Tag objects representing only active tags
    And no deleted tags should be included
    And audit information should not be present (audit = NONE)

    @TC02
    Scenario: Retrieve tags including deleted tags
    Given an account exists with the accountId 'valid-account-uuid'
    And the account has both active and deleted tags
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags with query parameter includedDeleted=true
    Then the response status should be 200
    And the response body should include both active and deleted tags
    And the response body should be a JSON array of Tag objects

    @TC03
    Scenario: Retrieve tags with audit level FULL
    Given an account exists with the accountId 'valid-account-uuid'
    And the account has active tags
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags with query parameter audit=FULL
    Then the response status should be 200
    And each Tag object in the response should include full audit information

    @TC04
    Scenario: Retrieve tags with audit level MINIMAL
    Given an account exists with the accountId 'valid-account-uuid'
    And the account has active tags
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags with query parameter audit=MINIMAL
    Then the response status should be 200
    And each Tag object in the response should include minimal audit information

    @TC05
    Scenario: Retrieve tags with all query parameters (includedDeleted and audit)
    Given an account exists with the accountId 'valid-account-uuid'
    And the account has both active and deleted tags
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags with query parameters includedDeleted=true and audit=FULL
    Then the response status should be 200
    And the response body should include both active and deleted tags
    And each Tag object should include full audit information

    @TC06
    Scenario: Retrieve tags for account with no tags
    Given an account exists with the accountId 'valid-account-uuid-no-tags'
    And the account has no tags
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid-no-tags/tags
    Then the response status should be 200
    And the response body should be an empty JSON array

    @TC07
    Scenario: Retrieve tags for non-existent account
    Given an accountId 'non-existent-account-uuid' that does not exist in the system
    When I send a GET request to /1.0/kb/accounts/non-existent-account-uuid/tags
    Then the response status should be 404
    And the response body should contain an error message indicating account not found

    @TC08
    Scenario: Retrieve tags with invalid accountId format
    Given an accountId 'invalid-format' that does not match the uuid pattern
    When I send a GET request to /1.0/kb/accounts/invalid-format/tags
    Then the response status should be 400
    And the response body should contain an error message indicating invalid accountId

    @TC09
    Scenario: Retrieve tags with unsupported audit parameter value
    Given an account exists with the accountId 'valid-account-uuid'
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags with query parameter audit=INVALID
    Then the response status should be 400
    And the response body should contain an error message indicating invalid audit parameter

    @TC10
    Scenario: Retrieve tags with extra/unknown query parameters
    Given an account exists with the accountId 'valid-account-uuid'
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags with an extra query parameter foo=bar
    Then the response status should be 200
    And the response body should be a JSON array of Tag objects (default behavior)

    @TC11
    Scenario: Retrieve tags when API is unavailable
    Given the KillBill API is down or unreachable
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags
    Then the response status should be 503 or appropriate server error code
    And the response body should contain an error message indicating service unavailability

    @TC12
    Scenario: Retrieve tags with missing authentication token
    Given an account exists with the accountId 'valid-account-uuid'
    And the request is missing the authentication token
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags
    Then the response status should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC13
    Scenario: Retrieve tags with invalid authentication token
    Given an account exists with the accountId 'valid-account-uuid'
    And the request contains an invalid authentication token
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags
    Then the response status should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC14
    Scenario: Retrieve tags with injection attack in accountId
    Given an accountId 'valid-account-uuid;DROP TABLE accounts;' containing SQL injection attempt
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid;DROP TABLE accounts;/tags
    Then the response status should be 400
    And the response body should contain an error message indicating invalid input

    @TC15
    Scenario: Retrieve tags with XSS attempt in query parameter
    Given an account exists with the accountId 'valid-account-uuid'
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags with query parameter audit=<script>alert(1)</script>
    Then the response status should be 400
    And the response body should contain an error message indicating invalid input

    @TC16
    Scenario: Retrieve tags with large number of tags (performance)
    Given an account exists with the accountId 'valid-account-uuid-many-tags'
    And the account has 10,000 tags
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid-many-tags/tags
    Then the response status should be 200
    And the response body should contain a JSON array of 10,000 Tag objects
    And the response time should be within acceptable performance thresholds (e.g., < 2 seconds)

    @TC17
    Scenario: Retrieve tags with concurrent requests (performance)
    Given multiple concurrent GET requests are sent to /1.0/kb/accounts/valid-account-uuid/tags
    When the requests are processed
    Then all responses should have status 200
    And all response bodies should be correct and consistent
    And response times should remain within acceptable limits

    @TC18
    Scenario: Regression - previously fixed issue with deleted tags not being returned when includedDeleted=true
    Given an account exists with the accountId 'regression-account-uuid'
    And the account has both active and deleted tags
    When I send a GET request to /1.0/kb/accounts/regression-account-uuid/tags with query parameter includedDeleted=true
    Then the response status should be 200
    And the response body should include both active and deleted tags
    And previously fixed issues should not reoccur

    @TC19
    Scenario: Regression - backward compatibility with legacy clients
    Given an account exists with the accountId 'legacy-account-uuid'
    When I send a GET request to /1.0/kb/accounts/legacy-account-uuid/tags without query parameters
    Then the response status should be 200
    And the response body should be a JSON array of Tag objects

    @TC20
    Scenario: Retrieve tags with partial UUID (edge case)
    Given an accountId '12345' that is a partial UUID
    When I send a GET request to /1.0/kb/accounts/12345/tags
    Then the response status should be 400
    And the response body should contain an error message indicating invalid accountId

    @TC21
    Scenario: Retrieve tags with empty accountId (edge case)
    Given an empty accountId parameter
    When I send a GET request to /1.0/kb/accounts//tags
    Then the response status should be 400
    And the response body should contain an error message indicating invalid accountId

    @TC22
    Scenario: Retrieve tags with whitespace in accountId (edge case)
    Given an accountId '   ' containing only whitespace
    When I send a GET request to /1.0/kb/accounts/   /tags
    Then the response status should be 400
    And the response body should contain an error message indicating invalid accountId

    @TC23
    Scenario: Retrieve tags with maximum allowed accountId length (boundary)
    Given an accountId at the maximum allowed length according to UUID specification
    When I send a GET request to /1.0/kb/accounts/max-length-uuid/tags
    Then the response status should be 200 or 404 depending on account existence
    And the response body should match the expected behavior

    @TC24
    Scenario: Integration - downstream service returns error
    Given an account exists with the accountId 'valid-account-uuid'
    And the tag retrieval service is temporarily unavailable
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags
    Then the response status should be 502 or appropriate error code
    And the response body should contain an error message indicating downstream failure

    @TC25
    Scenario: Data consistency across systems (integration)
    Given an account exists with the accountId 'valid-account-uuid'
    And tags are updated in an integrated system
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/tags
    Then the response body should reflect the latest tag data consistently