Feature: Retrieve a list of catalog versions via GET /1.0/kb/catalog/versions
As a KillBill API user,
I want to retrieve catalog version effective dates via the catalog versions API,
so that I can view available catalog versions for my tenant or globally.

  Background:
  Given the KillBill API server is running and accessible
  And the /1.0/kb/catalog/versions endpoint is available
  And the system contains catalog versions with various effective dates
  And I have a valid API authentication token

    @TC01
    Scenario: Successful retrieval of all catalog versions (no accountId)
    Given the database contains multiple catalog versions with different effective dates
    And I have a valid authentication token
    When I send a GET request to /1.0/kb/catalog/versions without any query parameters
    Then the response status code should be 200
    And the response content-type should be application/json
    And the response body should be a JSON array of strings
    And each string should be a valid ISO 8601 date-time
    And the array should contain all catalog version effective dates present in the system

    @TC02
    Scenario: Successful retrieval of catalog versions for a specific accountId
    Given the database contains catalog versions associated with multiple tenants
    And I have a valid authentication token
    And there exists an account with accountId '123e4567-e89b-12d3-a456-426614174000'
    When I send a GET request to /1.0/kb/catalog/versions with query parameter accountId=123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 200
    And the response content-type should be application/json
    And the response body should be a JSON array of strings
    And each string should be a valid ISO 8601 date-time
    And the array should contain only catalog version effective dates relevant to the given accountId's tenant

    @TC03
    Scenario: Retrieval when no catalog versions exist
    Given the database contains no catalog versions
    And I have a valid authentication token
    When I send a GET request to /1.0/kb/catalog/versions
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC04
    Scenario: Retrieval with accountId that does not exist
    Given the database contains catalog versions for other tenants
    And I have a valid authentication token
    And accountId '00000000-0000-0000-0000-000000000000' does not exist
    When I send a GET request to /1.0/kb/catalog/versions with query parameter accountId=00000000-0000-0000-0000-000000000000
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC05
    Scenario: Retrieval with invalid accountId format
    Given I have a valid authentication token
    When I send a GET request to /1.0/kb/catalog/versions with query parameter accountId=not-a-uuid
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId format

    @TC06
    Scenario: Retrieval without authentication token
    Given the database contains catalog versions
    When I send a GET request to /1.0/kb/catalog/versions without an authentication token
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication is required

    @TC07
    Scenario: Retrieval with expired or invalid authentication token
    Given the database contains catalog versions
    And I have an expired or invalid authentication token
    When I send a GET request to /1.0/kb/catalog/versions
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication is required

    @TC08
    Scenario: Retrieval when service is unavailable
    Given the KillBill API server is down or unreachable
    When I send a GET request to /1.0/kb/catalog/versions
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailability

    @TC09
    Scenario: Retrieval with extra unsupported query parameters
    Given the database contains catalog versions
    And I have a valid authentication token
    When I send a GET request to /1.0/kb/catalog/versions with query parameter foo=bar
    Then the response status code should be 200
    And the response body should be a JSON array of strings
    And the extra parameter should be ignored

    @TC10
    Scenario: Retrieval with large number of catalog versions
    Given the database contains 10,000 catalog versions
    And I have a valid authentication token
    When I send a GET request to /1.0/kb/catalog/versions
    Then the response status code should be 200
    And the response body should be a JSON array of 10,000 strings
    And each string should be a valid ISO 8601 date-time
    And the response time should be within acceptable limits (e.g., < 2 seconds)

    @TC11
    Scenario: Retrieval with slow downstream dependency
    Given the database contains catalog versions
    And a downstream service dependency is responding slowly
    When I send a GET request to /1.0/kb/catalog/versions
    Then the response status code should be 200 or 504 depending on timeout configuration
    And if 504, the response body should contain an appropriate timeout error message

    @TC12
    Scenario: Security - SQL injection attempt in accountId
    Given I have a valid authentication token
    When I send a GET request to /1.0/kb/catalog/versions with query parameter accountId="' OR 1=1 --"
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId format
    And no sensitive information should be exposed

    @TC13
    Scenario: Regression - previously fixed issue with empty array response
    Given the database contains no catalog versions
    And I have a valid authentication token
    When I send a GET request to /1.0/kb/catalog/versions
    Then the response status code should be 200
    And the response body should be an empty JSON array
    And no error or stack trace should be present in the response

    @TC14
    Scenario: Backward compatibility - valid request from older client
    Given the database contains catalog versions
    And I have a valid authentication token
    And I use an older client version to send the request
    When I send a GET request to /1.0/kb/catalog/versions
    Then the response status code should be 200
    And the response body should be a JSON array of strings
    And the format should be compatible with previous API versions

    @TC15
    Scenario: Performance - concurrent requests
    Given the database contains catalog versions
    And I have multiple valid authentication tokens
    When I send 100 concurrent GET requests to /1.0/kb/catalog/versions
    Then all responses should have status code 200
    And all response bodies should be JSON arrays of strings
    And the system should not exceed acceptable resource utilization thresholds

    @TC16
    Scenario: Edge Case - partial input (empty accountId parameter)
    Given the database contains catalog versions
    And I have a valid authentication token
    When I send a GET request to /1.0/kb/catalog/versions with query parameter accountId=""
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId format

    @TC17
    Scenario: Edge Case - accountId with leading/trailing spaces
    Given the database contains catalog versions
    And I have a valid authentication token
    When I send a GET request to /1.0/kb/catalog/versions with query parameter accountId=" 123e4567-e89b-12d3-a456-426614174000 "
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId format

    @TC18
    Scenario: Edge Case - accountId with mixed case
    Given the database contains catalog versions for an accountId with mixed case letters
    And I have a valid authentication token
    When I send a GET request to /1.0/kb/catalog/versions with query parameter accountId="123E4567-E89B-12D3-A456-426614174000"
    Then the response status code should be 200
    And the response body should be a JSON array of strings
    And the array should contain only catalog version effective dates relevant to the given accountId's tenant

    @TC19
    Scenario: Edge Case - malformed JSON response
    Given the database contains catalog versions
    And I have a valid authentication token
    And the API is misconfigured to return malformed JSON
    When I send a GET request to /1.0/kb/catalog/versions
    Then the response status code should be 500
    And the response body should contain an error message indicating a server error

    @TC20
    Scenario: Accessibility - verify endpoint is not UI but returns machine-readable JSON
    Given the database contains catalog versions
    And I have a valid authentication token
    When I send a GET request to /1.0/kb/catalog/versions
    Then the response content-type should be application/json
    And the response body should be a JSON array of strings
    And no HTML or UI elements should be present in the response