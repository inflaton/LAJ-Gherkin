Feature: Export account data via GET /1.0/kb/export/{accountId}
As a KillBill API user,
I want to export account data by accountId,
so that I can retrieve a structured export of a specific account for backup or migration purposes.

  Background:
  Given the KillBill API service is running and accessible
  And the API endpoint GET /1.0/kb/export/{accountId} is available
  And the database contains accounts with diverse data
  And I have a valid authentication token (if required)
  And I have seeded the system with accounts having various states (existing, non-existing, malformed IDs)

    @TC01
    Scenario: Successful export with all required and optional headers
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the request includes header "X-Killbill-CreatedBy" with value "test-user"
    And the request includes header "X-Killbill-Reason" with value "data backup"
    And the request includes header "X-Killbill-Comment" with value "monthly export"
    When I send a GET request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 200
    And the response Content-Type should be "application/octet-stream"
    And the response body should contain a valid export archive for the account

    @TC02
    Scenario: Successful export with only required header
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the request includes header "X-Killbill-CreatedBy" with value "test-user"
    When I send a GET request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 200
    And the response Content-Type should be "application/octet-stream"
    And the response body should contain a valid export archive for the account

    @TC03
    Scenario: Export with missing required header
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the request does not include header "X-Killbill-CreatedBy"
    When I send a GET request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 400
    And the response body should indicate that the required header is missing

    @TC04
    Scenario: Export with invalid accountId format (malformed UUID)
    Given the request includes header "X-Killbill-CreatedBy" with value "test-user"
    When I send a GET request to /1.0/kb/export/invalid-account-id
    Then the response status code should be 400
    And the response body should indicate invalid accountId format

    @TC05
    Scenario: Export for non-existent account
    Given the request includes header "X-Killbill-CreatedBy" with value "test-user"
    And no account exists with accountId "11111111-2222-3333-4444-555555555555"
    When I send a GET request to /1.0/kb/export/11111111-2222-3333-4444-555555555555
    Then the response status code should be 404
    And the response body should indicate that the account was not found

    @TC06
    Scenario: Export with extra, unsupported headers
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the request includes header "X-Killbill-CreatedBy" with value "test-user"
    And the request includes extra header "X-Extra-Header" with value "extra-value"
    When I send a GET request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 200
    And the response Content-Type should be "application/octet-stream"
    And the response body should contain a valid export archive for the account

    @TC07
    Scenario: Export when account database is empty
    Given the request includes header "X-Killbill-CreatedBy" with value "test-user"
    And the account database is empty
    When I send a GET request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 404
    And the response body should indicate that the account was not found

    @TC08
    Scenario: Export with very large account data
    Given an account exists with accountId "999e4567-e89b-12d3-a456-426614174999" and has a large volume of data
    And the request includes header "X-Killbill-CreatedBy" with value "test-user"
    When I send a GET request to /1.0/kb/export/999e4567-e89b-12d3-a456-426614174999
    Then the response status code should be 200
    And the response Content-Type should be "application/octet-stream"
    And the response body size should be greater than 10MB
    And the response time should be within acceptable limits (e.g., < 5 seconds)

    @TC09
    Scenario: Export with slow downstream dependency (simulate degraded performance)
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the request includes header "X-Killbill-CreatedBy" with value "test-user"
    And the downstream export service is responding slowly
    When I send a GET request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 200
    And the response time should not exceed the configured timeout
    And the response Content-Type should be "application/octet-stream"

    @TC10
    Scenario: Export when export service is unavailable
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the request includes header "X-Killbill-CreatedBy" with value "test-user"
    And the export service is unavailable
    When I send a GET request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 500
    And the response body should indicate an internal server error

    @TC11
    Scenario: Export with malicious accountId input (injection attempt)
    Given the request includes header "X-Killbill-CreatedBy" with value "test-user"
    When I send a GET request to /1.0/kb/export/' OR '1'='1
    Then the response status code should be 400
    And the response body should indicate invalid accountId format

    @TC12
    Scenario: Export with missing accountId in path
    Given the request includes header "X-Killbill-CreatedBy" with value "test-user"
    When I send a GET request to /1.0/kb/export/
    Then the response status code should be 404
    And the response body should indicate that the endpoint was not found

    @TC13
    Scenario: Export with concurrent requests for the same account
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the request includes header "X-Killbill-CreatedBy" with value "test-user"
    When I send 10 concurrent GET requests to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then all responses should have status code 200
    And all response bodies should be valid export archives for the account

    @TC14
    Scenario: Regression - Export after previous bug fix for missing Content-Type
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the request includes header "X-Killbill-CreatedBy" with value "test-user"
    When I send a GET request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 200
    And the response Content-Type should be "application/octet-stream"

    @TC15
    Scenario: Backward compatibility - Export with previously supported headers
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the request includes header "X-Killbill-CreatedBy" with value "test-user"
    And the request includes legacy header "X-Killbill-User"
    When I send a GET request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 200
    And the response Content-Type should be "application/octet-stream"

    @TC16
    Scenario: Export with unsupported HTTP method
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    When I send a POST request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 405
    And the response body should indicate that the method is not allowed

    @TC17
    Scenario: Export with long-running operation (timeout)
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the request includes header "X-Killbill-CreatedBy" with value "test-user"
    And the export operation takes longer than the configured timeout
    When I send a GET request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 504
    And the response body should indicate a gateway timeout

    @TC18
    Scenario: Export with unauthorized access attempt (if authentication is required)
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the request does not include a valid authentication token
    When I send a GET request to /1.0/kb/export/123e4567-e89b-12d3-a456-426614174000
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC19
    Scenario: Accessibility - Export endpoint is discoverable and usable via assistive tools
    Given the API documentation is available
    When a screen reader or assistive tool is used to access the documentation for GET /1.0/kb/export/{accountId}
    Then the endpoint and its required parameters should be clearly described
    And all error messages should be accessible and understandable