Feature: Retrieve Account Email Audit Logs With History by ID
As a KillBill API user,
I want to retrieve audit logs with history for a specific account email by its ID,
so that I can view the change history and audit trail for a particular account email.

  Background:
    Given the KillBill API server is running and accessible
    And I have a valid API authentication token
    And the database contains accounts and account emails with diverse audit logs
    And the endpoint GET /1.0/kb/accounts/{accountId}/emails/{accountEmailId}/auditLogsWithHistory is available

  @TC01
  Scenario: Successful retrieval of audit logs with valid accountId and accountEmailId
    Given an existing account with accountId "valid-account-uuid"
    And an existing account email with accountEmailId "valid-email-uuid" associated with that account
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/emails/valid-email-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 200
    And the response Content-Type should be "application/json"
    And the response body should be a JSON array of AuditLog objects
    And each AuditLog object should contain id, changeType, changedBy, changeDate, and history fields

  @TC02
  Scenario: Retrieval with valid accountId and accountEmailId but no audit logs exist
    Given an existing account with accountId "valid-account-uuid"
    And an existing account email with accountEmailId "email-without-audit-uuid" associated with that account
    And the account email has no associated audit logs
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/emails/email-without-audit-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 200
    And the response Content-Type should be "application/json"
    And the response body should be an empty JSON array

  @TC03
  Scenario: Retrieval with non-existent accountId
    Given a non-existent accountId "nonexistent-account-uuid"
    And a valid accountEmailId "valid-email-uuid"
    When I send a GET request to /1.0/kb/accounts/nonexistent-account-uuid/emails/valid-email-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 404
    And the response body should contain an error message indicating "Account not found"

  @TC04
  Scenario: Retrieval with non-existent accountEmailId
    Given an existing account with accountId "valid-account-uuid"
    And a non-existent accountEmailId "nonexistent-email-uuid"
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/emails/nonexistent-email-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 404
    And the response body should contain an error message indicating "Account email not found"

  @TC05
  Scenario: Retrieval with invalid accountId format
    Given an invalid accountId "invalid-format"
    And a valid accountEmailId "valid-email-uuid"
    When I send a GET request to /1.0/kb/accounts/invalid-format/emails/valid-email-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 400
    And the response body should contain an error message indicating "Invalid accountId format"

  @TC06
  Scenario: Retrieval with invalid accountEmailId format
    Given a valid accountId "valid-account-uuid"
    And an invalid accountEmailId "invalid-format"
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/emails/invalid-format/auditLogsWithHistory with valid authentication
    Then the response status code should be 400
    And the response body should contain an error message indicating "Invalid accountEmailId format"

  @TC07
  Scenario: Retrieval with missing authentication token
    Given an existing account with accountId "valid-account-uuid"
    And an existing account email with accountEmailId "valid-email-uuid"
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/emails/valid-email-uuid/auditLogsWithHistory without authentication
    Then the response status code should be 401
    And the response body should contain an error message indicating "Unauthorized"

  @TC08
  Scenario: Retrieval with invalid authentication token
    Given an existing account with accountId "valid-account-uuid"
    And an existing account email with accountEmailId "valid-email-uuid"
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/emails/valid-email-uuid/auditLogsWithHistory with an invalid authentication token
    Then the response status code should be 401
    And the response body should contain an error message indicating "Unauthorized"

  @TC09
  Scenario: Retrieval when API service is unavailable
    Given the KillBill API server is down or unreachable
    When I send a GET request to /1.0/kb/accounts/any-account-uuid/emails/any-email-uuid/auditLogsWithHistory
    Then the response status code should be 503
    And the response body should contain an error message indicating "Service Unavailable"

  @TC10
  Scenario: Retrieval with extra query parameters
    Given an existing account with accountId "valid-account-uuid"
    And an existing account email with accountEmailId "valid-email-uuid"
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/emails/valid-email-uuid/auditLogsWithHistory?extra=param with valid authentication
    Then the response status code should be 200
    And the response body should be a JSON array of AuditLog objects

  @TC11
  Scenario: Retrieval with extremely large number of audit logs
    Given an existing account with accountId "large-audit-account-uuid"
    And an existing account email with accountEmailId "large-audit-email-uuid" associated with that account
    And the account email has more than 1000 audit logs
    When I send a GET request to /1.0/kb/accounts/large-audit-account-uuid/emails/large-audit-email-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 200
    And the response body should be a JSON array containing more than 1000 AuditLog objects
    And the response time should be within acceptable limits (e.g., < 2 seconds)

  @TC12
  Scenario: Retrieval with slow downstream dependency
    Given an existing account with accountId "valid-account-uuid"
    And an existing account email with accountEmailId "valid-email-uuid"
    And the downstream audit log service is responding slowly
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/emails/valid-email-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 504
    And the response body should contain an error message indicating "Gateway Timeout"

  @TC13
  Scenario: Security test - SQL injection attempt in accountId
    Given a malicious accountId "'; DROP TABLE accounts;--"
    And a valid accountEmailId "valid-email-uuid"
    When I send a GET request to /1.0/kb/accounts/'; DROP TABLE accounts;--/emails/valid-email-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 400
    And the response body should contain an error message indicating "Invalid accountId format"

  @TC14
  Scenario: Security test - XSS attempt in accountEmailId
    Given a valid accountId "valid-account-uuid"
    And a malicious accountEmailId "<script>alert(1)</script>"
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/emails/<script>alert(1)</script>/auditLogsWithHistory with valid authentication
    Then the response status code should be 400
    And the response body should contain an error message indicating "Invalid accountEmailId format"

  @TC15
  Scenario: Regression - previously fixed issue with audit log ordering
    Given an existing account with accountId "valid-account-uuid"
    And an existing account email with accountEmailId "valid-email-uuid"
    And the audit logs were previously returned out of order
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/emails/valid-email-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 200
    And the response body should be a JSON array of AuditLog objects ordered by changeDate descending

  @TC16
  Scenario: Backward compatibility - clients expecting unchanged AuditLog schema
    Given an existing account with accountId "valid-account-uuid"
    And an existing account email with accountEmailId "valid-email-uuid"
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/emails/valid-email-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 200
    And the response body should match the expected AuditLog schema as defined in #/definitions/AuditLog

  @TC17
  Scenario: Accessibility - verify response is consumable by screen readers (if UI is present)
    Given an existing account with accountId "valid-account-uuid"
    And an existing account email with accountEmailId "valid-email-uuid"
    When I retrieve the audit logs with history via the API and render them in the UI
    Then the UI should provide semantic markup for screen readers
    And all audit log fields should be accessible via keyboard navigation

  @TC18
  Scenario: State variation - empty database
    Given the accounts and account_emails tables are empty
    When I send a GET request to /1.0/kb/accounts/any-account-uuid/emails/any-email-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 404
    And the response body should contain an error message indicating "Account not found"

  @TC19
  Scenario: State variation - partially populated database
    Given the database contains some accounts but not the requested accountId
    When I send a GET request to /1.0/kb/accounts/missing-account-uuid/emails/any-email-uuid/auditLogsWithHistory with valid authentication
    Then the response status code should be 404
    And the response body should contain an error message indicating "Account not found"