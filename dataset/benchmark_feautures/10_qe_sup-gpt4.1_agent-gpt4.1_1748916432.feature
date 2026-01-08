Feature: Retrieve audit logs by account id
As a KillBill API user,
I want to retrieve audit logs for a specific account using GET /1.0/kb/accounts/{accountId}/auditLogs,
so that I can view the account's audit history.

  Background:
  Given the KillBill API is running and accessible
  And the database contains accounts with diverse audit logs
  And I have a valid authentication token
  And the API endpoint /1.0/kb/accounts/{accountId}/auditLogs is available

    @TC01
    Scenario: Successful retrieval of audit logs for an existing account
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the account has associated audit logs
    When I send a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/auditLogs with a valid authentication token
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array of AuditLog objects
    And each AuditLog object should contain all required fields as per API definition

    @TC02
    Scenario: Successful retrieval when account exists but has no audit logs
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174001"
    And the account has no associated audit logs
    When I send a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174001/auditLogs with a valid authentication token
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be an empty JSON array

    @TC03
    Scenario: Account does not exist
    Given no account exists with accountId "00000000-0000-0000-0000-000000000000"
    When I send a GET request to /1.0/kb/accounts/00000000-0000-0000-0000-000000000000/auditLogs with a valid authentication token
    Then the response status code should be 404
    And the response body should contain an error message indicating the account was not found

    @TC04
    Scenario: Invalid accountId format (malformed UUID)
    Given I have an invalid accountId "invalid-uuid"
    When I send a GET request to /1.0/kb/accounts/invalid-uuid/auditLogs with a valid authentication token
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid accountId format

    @TC05
    Scenario: Missing authentication token
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    When I send a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/auditLogs without an authentication token
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication is required

    @TC06
    Scenario: Invalid authentication token
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    When I send a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/auditLogs with an invalid authentication token
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication is required or invalid

    @TC07
    Scenario: Extra query parameters are provided
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    When I send a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/auditLogs?extra=param with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array of AuditLog objects
    And extra query parameters should be ignored

    @TC08
    Scenario: System error occurs (e.g., database unavailable)
    Given the database is unavailable
    When I send a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/auditLogs with a valid authentication token
    Then the response status code should be 500
    And the response body should contain an error message indicating an internal server error

    @TC09
    Scenario: Large number of audit logs for an account
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174002"
    And the account has 10,000 associated audit logs
    When I send a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174002/auditLogs with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array containing 10,000 AuditLog objects
    And the response time should be within acceptable limits (e.g., < 2 seconds)

    @TC10
    Scenario: Attempted injection attack in accountId
    Given I have an accountId "123e4567-e89b-12d3-a456-426614174000;DROP TABLE accounts;"
    When I send a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000;DROP TABLE accounts;/auditLogs with a valid authentication token
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid accountId format or input rejected

    @TC11
    Scenario: Timeout occurs during request
    Given the system is under heavy load
    When I send a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/auditLogs with a valid authentication token
    Then the response status code should be 504 or 503
    And the response body should contain an error message indicating a timeout or service unavailable

    @TC12
    Scenario: Regression - previously fixed bug where empty audit logs returned 500
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174003"
    And the account has no associated audit logs
    When I send a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174003/auditLogs with a valid authentication token
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC13
    Scenario: Backward compatibility - older client requests audit logs
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And I use an older client version
    When I send a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/auditLogs with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array of AuditLog objects

    @TC14
    Scenario: Concurrent requests for audit logs
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    When I send 100 concurrent GET requests to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/auditLogs with valid authentication tokens
    Then all responses should have status code 200
    And all responses should contain a JSON array of AuditLog objects
    And the system should not return errors due to concurrency

    @TC15
    Scenario: Partial input - accountId is empty
    Given I have an empty accountId ""
    When I send a GET request to /1.0/kb/accounts//auditLogs with a valid authentication token
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating accountId is required