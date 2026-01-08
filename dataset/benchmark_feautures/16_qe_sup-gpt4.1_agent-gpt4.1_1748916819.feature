Feature: Retrieve account emails via GET /1.0/kb/accounts/{accountId}/emails
As a KillBill API user,
I want to retrieve all emails associated with a specific account,
so that I can view and manage account communications.

  Background:
  Given the KillBill API server is running and accessible
  And the API endpoint GET /1.0/kb/accounts/{accountId}/emails is available
  And the database contains accounts with various email records
  And I have a valid authentication token (if required)

    @TC01
    Scenario: Successful retrieval of emails for an account with emails
    Given an existing account with accountId 'valid-account-uuid' that has multiple associated emails
    When I perform a GET request to /1.0/kb/accounts/valid-account-uuid/emails
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array of AccountEmail objects
    And each AccountEmail object should contain the expected fields (e.g., email, accountId, isActive)
    And the response should list all emails associated with the account

    @TC02
    Scenario: Successful retrieval of emails for an account with no emails
    Given an existing account with accountId 'valid-account-no-emails-uuid' that has no associated emails
    When I perform a GET request to /1.0/kb/accounts/valid-account-no-emails-uuid/emails
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC03
    Scenario: Retrieval with an invalid accountId format
    Given an accountId of 'invalid-format' that does not match the required UUID pattern
    When I perform a GET request to /1.0/kb/accounts/invalid-format/emails
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId format

    @TC04
    Scenario: Retrieval with a non-existent but valid-format accountId
    Given an accountId 'non-existent-uuid' that is a valid UUID but does not exist in the system
    When I perform a GET request to /1.0/kb/accounts/non-existent-uuid/emails
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC05
    Scenario: Retrieval without authentication (if required)
    Given no authentication token is provided or the token is invalid
    When I perform a GET request to /1.0/kb/accounts/valid-account-uuid/emails
    Then the response status code should be 401 or 403
    And the response body should indicate authentication failure

    @TC06
    Scenario: Retrieval when the API service is unavailable
    Given the KillBill API server is down or unreachable
    When I perform a GET request to /1.0/kb/accounts/valid-account-uuid/emails
    Then the response status code should be 503
    And the response body should indicate service unavailability

    @TC07
    Scenario: Retrieval with extra query parameters
    Given an existing account with accountId 'valid-account-uuid'
    When I perform a GET request to /1.0/kb/accounts/valid-account-uuid/emails?extra=param
    Then the response status code should be 200
    And the response body should be a JSON array of AccountEmail objects
    And extra parameters should be ignored by the API

    @TC08
    Scenario: Retrieval with a very large number of emails
    Given an account with accountId 'large-email-account-uuid' that has 1000+ associated emails
    When I perform a GET request to /1.0/kb/accounts/large-email-account-uuid/emails
    Then the response status code should be 200
    And the response body should be a JSON array containing all associated emails
    And the response time should be within acceptable limits (e.g., < 2 seconds)

    @TC09
    Scenario: Retrieval with slow network or transient failure
    Given a transient network failure occurs during the request
    When I perform a GET request to /1.0/kb/accounts/valid-account-uuid/emails
    Then the client should retry as per policy and eventually receive a 200 response or a timeout error

    @TC10
    Scenario: Security test - SQL injection attempt in accountId
    Given an accountId value of "' OR 1=1 --" is used in the request
    When I perform a GET request to /1.0/kb/accounts/' OR 1=1 --/emails
    Then the response status code should be 400
    And the response body should not expose internal error details

    @TC11
    Scenario: Security test - XSS attempt in accountId
    Given an accountId value of "<script>alert('xss')</script>" is used in the request
    When I perform a GET request to /1.0/kb/accounts/<script>alert('xss')</script>/emails
    Then the response status code should be 400
    And the response body should not execute or return any script content

    @TC12
    Scenario: Regression - previously fixed bug: emails with special characters
    Given an account with accountId 'special-characters-uuid' has emails containing special/unicode characters
    When I perform a GET request to /1.0/kb/accounts/special-characters-uuid/emails
    Then the response status code should be 200
    And the response body should correctly return emails with special/unicode characters

    @TC13
    Scenario: Performance under concurrent requests
    Given multiple clients request emails for the same accountId simultaneously
    When 100 concurrent GET requests are made to /1.0/kb/accounts/valid-account-uuid/emails
    Then all responses should have status code 200
    And response times should remain within acceptable thresholds

    @TC14
    Scenario: Backward compatibility - legacy clients
    Given a legacy client using previous API version headers
    When the client performs a GET request to /1.0/kb/accounts/valid-account-uuid/emails
    Then the response status code should be 200
    And the response body should remain compatible with previous JSON structure

    @TC15
    Scenario: Accessibility - API documentation and error messages
    Given a visually impaired user accesses the API documentation or receives an error response
    When an error occurs (e.g., 400, 401, 503)
    Then the error message should be clear, descriptive, and accessible (e.g., machine-readable JSON with error details)