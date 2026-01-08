Feature: Retrieve account audit logs with history by account id
As a KillBill API user,
I want to retrieve audit logs with history for a specific account by its ID,
so that I can review all account-related changes and their history.

  Background:
  Given the KillBill API is available at the correct baseUrl
  And the database contains accounts with diverse audit history data
  And I have a valid authentication token
  And the API endpoint GET /1.0/kb/accounts/{accountId}/auditLogsWithHistory is accessible

    @TC01
    Scenario: Successfully retrieve audit logs with history for a valid accountId
    Given an account exists with accountId "1111-2222-3333-4444-5555" and has associated audit logs
    When I send a GET request to /1.0/kb/accounts/1111-2222-3333-4444-5555/auditLogsWithHistory with valid authentication
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array of AuditLog objects
    And each AuditLog object should contain all required fields as per the API definition
    And the audit logs should represent the full history for the account

    @TC02
    Scenario: Retrieve audit logs with history for a valid accountId with no audit logs
    Given an account exists with accountId "6666-7777-8888-9999-0000" and has no audit logs
    When I send a GET request to /1.0/kb/accounts/6666-7777-8888-9999-0000/auditLogsWithHistory with valid authentication
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC03
    Scenario: Attempt to retrieve audit logs with history for a non-existent accountId
    Given no account exists with accountId "aaaa-bbbb-cccc-dddd-eeee"
    When I send a GET request to /1.0/kb/accounts/aaaa-bbbb-cccc-dddd-eeee/auditLogsWithHistory with valid authentication
    Then the response status code should be 404
    And the response body should contain an error message indicating account not found

    @TC04
    Scenario: Attempt to retrieve audit logs with invalid accountId format
    Given I have an accountId "invalid-account-id"
    When I send a GET request to /1.0/kb/accounts/invalid-account-id/auditLogsWithHistory with valid authentication
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId format

    @TC05
    Scenario: Attempt to retrieve audit logs with missing authentication token
    Given an account exists with accountId "1111-2222-3333-4444-5555"
    When I send a GET request to /1.0/kb/accounts/1111-2222-3333-4444-5555/auditLogsWithHistory without authentication
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication required

    @TC06
    Scenario: Attempt to retrieve audit logs with expired or invalid authentication token
    Given an account exists with accountId "1111-2222-3333-4444-5555"
    When I send a GET request to /1.0/kb/accounts/1111-2222-3333-4444-5555/auditLogsWithHistory with an expired or invalid authentication token
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication required

    @TC07
    Scenario: System error occurs while retrieving audit logs (e.g., database unavailable)
    Given the database is unavailable
    When I send a GET request to /1.0/kb/accounts/1111-2222-3333-4444-5555/auditLogsWithHistory with valid authentication
    Then the response status code should be 500
    And the response body should contain an error message indicating internal server error

    @TC08
    Scenario: Attempt to retrieve audit logs with extra unsupported parameters
    Given an account exists with accountId "1111-2222-3333-4444-5555"
    When I send a GET request to /1.0/kb/accounts/1111-2222-3333-4444-5555/auditLogsWithHistory with unsupported query parameters
    Then the response status code should be 200
    And the response body should be a JSON array of AuditLog objects
    And unsupported parameters should be ignored

    @TC09
    Scenario: Retrieve audit logs for an account with a large audit history
    Given an account exists with accountId "9999-8888-7777-6666-5555" and has a large number of audit logs
    When I send a GET request to /1.0/kb/accounts/9999-8888-7777-6666-5555/auditLogsWithHistory with valid authentication
    Then the response status code should be 200
    And the response body should be a JSON array of AuditLog objects
    And the response should include all audit logs for the account
    And the response time should be within acceptable performance thresholds

    @TC10
    Scenario: Security test - Attempt SQL injection in accountId path parameter
    Given I have an accountId "1111-2222-3333-4444-5555; DROP TABLE accounts;"
    When I send a GET request to /1.0/kb/accounts/1111-2222-3333-4444-5555; DROP TABLE accounts;/auditLogsWithHistory with valid authentication
    Then the response status code should be 400 or 404
    And the response body should not expose sensitive system information
    And the database should remain intact

    @TC11
    Scenario: Performance test - Multiple concurrent requests for audit logs
    Given multiple valid accountIds with audit logs exist
    When I send 100 concurrent GET requests to /1.0/kb/accounts/{accountId}/auditLogsWithHistory with valid authentication
    Then each response status code should be 200
    And each response body should be a JSON array of AuditLog objects
    And the average response time should remain within performance SLAs

    @TC12
    Scenario: Regression test - Previously fixed bug for missing audit log fields
    Given an account exists with accountId "1234-5678-9012-3456-7890" and has audit logs
    When I send a GET request to /1.0/kb/accounts/1234-5678-9012-3456-7890/auditLogsWithHistory with valid authentication
    Then the response status code should be 200
    And each AuditLog object should include all mandatory fields as per the latest schema

    @TC13
    Scenario: Integration test - Dependency service is degraded
    Given the audit log storage service is responding slowly
    When I send a GET request to /1.0/kb/accounts/1111-2222-3333-4444-5555/auditLogsWithHistory with valid authentication
    Then the response status code should be 200 or 503
    And the response body should contain either the audit logs or an error message indicating service unavailable
    And the system should log the degraded dependency

    @TC14
    Scenario: Edge case - accountId with leading/trailing whitespace
    Given an account exists with accountId "1111-2222-3333-4444-5555"
    When I send a GET request to /1.0/kb/accounts/ 1111-2222-3333-4444-5555 /auditLogsWithHistory with valid authentication
    Then the response status code should be 404 or 400
    And the response body should indicate account not found or invalid accountId format

    @TC15
    Scenario: Edge case - accountId with uppercase letters
    Given an account exists with accountId "AAAA-BBBB-CCCC-DDDD-EEEE"
    When I send a GET request to /1.0/kb/accounts/AAAA-BBBB-CCCC-DDDD-EEEE/auditLogsWithHistory with valid authentication
    Then the response status code should be 200 or 404 depending on system case-sensitivity
    And the response body should be as per the account's presence

    @TC16
    Scenario: Edge case - accountId at maximum allowed length (UUID standard)
    Given an account exists with a maximum length UUID accountId
    When I send a GET request to /1.0/kb/accounts/{max_length_uuid}/auditLogsWithHistory with valid authentication
    Then the response status code should be 200
    And the response body should be a JSON array of AuditLog objects or an empty array

    @TC17
    Scenario: Attempt to retrieve audit logs with partial accountId
    Given I have an accountId "1111-2222-3333"
    When I send a GET request to /1.0/kb/accounts/1111-2222-3333/auditLogsWithHistory with valid authentication
    Then the response status code should be 400
    And the response body should indicate invalid accountId format