Feature: Retrieve overdue state for account via GET /1.0/kb/accounts/{accountId}/overdue
As a KillBill API user,
I want to retrieve the overdue state for a specific account,
so that I can determine the account's current overdue status.

  Background:
  Given the KillBill API server is running and accessible
  And the database is seeded with accounts having diverse overdue states
  And I have a valid API authentication token (if required)
  And the OverdueState schema is defined and available for validation

    @TC01
    Scenario: Successful retrieval of overdue state for a valid account
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the account has an overdue state set in the database
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/overdue
    Then the response status code should be 200
    And the response Content-Type should be "application/json"
    And the response body should match the OverdueState JSON schema
    And the overdue state data should reflect the account's current overdue status

    @TC02
    Scenario: Retrieval for a valid account with no overdue state
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174001"
    And the account has no overdue state set in the database
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174001/overdue
    Then the response status code should be 200
    And the response Content-Type should be "application/json"
    And the response body should match the OverdueState JSON schema
    And the overdue state data should indicate no overdue status

    @TC03
    Scenario: Retrieval for a non-existent account
    Given no account exists with accountId "00000000-0000-0000-0000-000000000000"
    When I perform a GET request to /1.0/kb/accounts/00000000-0000-0000-0000-000000000000/overdue
    Then the response status code should be 404
    And the response body should contain an error message indicating account not found

    @TC04
    Scenario: Retrieval with an invalid accountId format (malformed UUID)
    Given I have an invalid accountId "not-a-uuid"
    When I perform a GET request to /1.0/kb/accounts/not-a-uuid/overdue
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId format

    @TC05
    Scenario: Retrieval with a missing accountId (empty path parameter)
    Given I omit the accountId in the request path
    When I perform a GET request to /1.0/kb/accounts//overdue
    Then the response status code should be 400
    And the response body should contain an error message indicating missing accountId

    @TC06
    Scenario: Retrieval with an unsupported accountId pattern (valid UUID but not matching system expectations)
    Given I have an accountId "123e4567-e89b-12d3-a456-426614174XYZ" that does not match the required pattern
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174XYZ/overdue
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId format

    @TC07
    Scenario: Unauthorized access attempt (missing authentication token)
    Given I do not provide a valid API authentication token
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/overdue
    Then the response status code should be 401
    And the response body should indicate authentication is required

    @TC08
    Scenario: Unauthorized access attempt (invalid authentication token)
    Given I provide an invalid API authentication token
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/overdue
    Then the response status code should be 401
    And the response body should indicate authentication is required

    @TC09
    Scenario: Server error during overdue state retrieval
    Given the backend service is unavailable or returns an error
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/overdue
    Then the response status code should be 500
    And the response body should contain an error message indicating server error

    @TC10
    Scenario: Injection attack attempt in accountId parameter
    Given I provide an accountId "123e4567-e89b-12d3-a456-426614174000;DROP TABLE accounts;"
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000;DROP TABLE accounts;/overdue
    Then the response status code should be 400
    And the response body should indicate invalid accountId format

    @TC11
    Scenario: XSS attack attempt in accountId parameter
    Given I provide an accountId "<script>alert('xss')</script>"
    When I perform a GET request to /1.0/kb/accounts/<script>alert('xss')</script>/overdue
    Then the response status code should be 400
    And the response body should indicate invalid accountId format

    @TC12
    Scenario: Retrieval with extra query parameters
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/overdue?extra=param
    Then the response status code should be 200
    And the response Content-Type should be "application/json"
    And the response body should match the OverdueState JSON schema
    And the extra query parameter should be ignored

    @TC13
    Scenario: Retrieval when database is empty
    Given the accounts database is empty
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/overdue
    Then the response status code should be 404
    And the response body should contain an error message indicating account not found

    @TC14
    Scenario: Performance - retrieval of overdue state under normal load
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/overdue
    Then the response time should be less than 500ms
    And the response status code should be 200
    And the response body should match the OverdueState JSON schema

    @TC15
    Scenario: Performance - concurrent retrievals for multiple accounts
    Given multiple accounts exist with unique accountIds
    When I perform concurrent GET requests to /1.0/kb/accounts/{accountId}/overdue for each accountId
    Then all responses should have status code 200 (for valid accounts)
    And the average response time should be within acceptable limits (e.g., < 750ms)

    @TC16
    Scenario: Regression - previously fixed bug for accountId with leading/trailing spaces
    Given an account exists with accountId " 123e4567-e89b-12d3-a456-426614174000 " (with spaces)
    When I perform a GET request to /1.0/kb/accounts/ 123e4567-e89b-12d3-a456-426614174000 /overdue
    Then the response status code should be 400
    And the response body should indicate invalid accountId format

    @TC17
    Scenario: Integration - dependency service is degraded
    Given the dependency service for overdue state is responding slowly
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/overdue
    Then the response status code should be 503 or 504
    And the response body should indicate a dependency timeout or service unavailable

    @TC18
    Scenario: Large payload handling (account with extensive overdue history)
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174002" and a large overdue history
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174002/overdue
    Then the response status code should be 200
    And the response body should match the OverdueState JSON schema
    And the payload size should not exceed system limits

    @TC19
    Scenario: Recovery from transient network error
    Given a transient network failure occurs during the request
    When I retry the GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/overdue
    Then the request should eventually succeed with status code 200 if the network recovers

    @TC20
    Scenario: Backward compatibility - unchanged response structure
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    When I perform a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/overdue
    Then the response body structure should remain consistent with previous API versions
    And all required fields in OverdueState should be present