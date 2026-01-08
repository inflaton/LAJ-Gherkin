Feature: Retrieve custom field audit logs with history by id
As a KillBill API user,
I want to retrieve audit logs for a specific custom field by its ID,
so that I can view the history and changes associated with that custom field.

  Background:
  Given the KillBill API is running and accessible
  And a valid authentication token is provided in the request headers
  And the database contains a diverse set of custom fields, some with audit logs and some without
  And the API endpoint GET /1.0/kb/customFields/{customFieldId}/auditLogsWithHistory is available

    @TC01
    Scenario: Successful retrieval of audit logs with history for an existing custom field
    Given a custom field exists in the system with id <validCustomFieldId>
    And audit logs exist for this custom field
    When the user sends a GET request to /1.0/kb/customFields/<validCustomFieldId>/auditLogsWithHistory
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array of AuditLog objects
    And each AuditLog object should contain required fields as per the AuditLog definition

    @TC02
    Scenario: Retrieval of audit logs for a custom field with no audit logs
    Given a custom field exists in the system with id <validCustomFieldIdNoLogs>
    And no audit logs exist for this custom field
    When the user sends a GET request to /1.0/kb/customFields/<validCustomFieldIdNoLogs>/auditLogsWithHistory
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be an empty JSON array

    @TC03
    Scenario: Retrieval of audit logs for a non-existent custom field
    Given no custom field exists in the system with id <nonExistentCustomFieldId>
    When the user sends a GET request to /1.0/kb/customFields/<nonExistentCustomFieldId>/auditLogsWithHistory
    Then the response status code should be 404
    And the response body should contain an error message indicating custom field not found

    @TC04
    Scenario: Retrieval of audit logs for a custom field whose associated Account does not exist
    Given a custom field exists in the system with id <orphanedCustomFieldId>
    And the associated Account for this custom field does not exist
    When the user sends a GET request to /1.0/kb/customFields/<orphanedCustomFieldId>/auditLogsWithHistory
    Then the response status code should be 404
    And the response body should contain an error message indicating account not found

    @TC05
    Scenario: Retrieval with invalid custom field id format
    Given the user provides an invalid customFieldId <invalidCustomFieldId> (not matching uuid pattern)
    When the user sends a GET request to /1.0/kb/customFields/<invalidCustomFieldId>/auditLogsWithHistory
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid customFieldId format

    @TC06
    Scenario: Retrieval with missing authentication token
    Given a valid custom field exists in the system with id <validCustomFieldId>
    And the request does not include an authentication token
    When the user sends a GET request to /1.0/kb/customFields/<validCustomFieldId>/auditLogsWithHistory
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication is required

    @TC07
    Scenario: Retrieval with invalid authentication token
    Given a valid custom field exists in the system with id <validCustomFieldId>
    And the request includes an invalid authentication token
    When the user sends a GET request to /1.0/kb/customFields/<validCustomFieldId>/auditLogsWithHistory
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication failed

    @TC08
    Scenario: System error during retrieval (e.g., database unavailable)
    Given a valid custom field exists in the system with id <validCustomFieldId>
    And the backend database is temporarily unavailable
    When the user sends a GET request to /1.0/kb/customFields/<validCustomFieldId>/auditLogsWithHistory
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC09
    Scenario: Security test - SQL injection attempt in customFieldId
    Given the user provides a customFieldId value containing SQL injection payload <sqlInjectionPayload>
    When the user sends a GET request to /1.0/kb/customFields/<sqlInjectionPayload>/auditLogsWithHistory
    Then the response status code should be 400 or 404
    And the response body should not expose any internal server errors or stack traces

    @TC10
    Scenario: Edge case - Extra path segments in the URL
    Given a valid custom field exists in the system with id <validCustomFieldId>
    When the user sends a GET request to /1.0/kb/customFields/<validCustomFieldId>/auditLogsWithHistory/extra
    Then the response status code should be 404
    And the response body should contain an error message indicating resource not found

    @TC11
    Scenario: Edge case - Very large number of audit logs for a custom field
    Given a custom field exists in the system with id <largeAuditLogCustomFieldId>
    And this custom field has a very large number of audit logs (e.g., 10,000+)
    When the user sends a GET request to /1.0/kb/customFields/<largeAuditLogCustomFieldId>/auditLogsWithHistory
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array containing all audit logs
    And the response time should be within acceptable performance thresholds (e.g., < 2 seconds)

    @TC12
    Scenario: Regression - Previously fixed issue with empty audit log array
    Given a custom field exists in the system with id <regressionCustomFieldId>
    And this custom field previously caused the API to return a non-JSON response when no audit logs existed
    When the user sends a GET request to /1.0/kb/customFields/<regressionCustomFieldId>/auditLogsWithHistory
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be an empty JSON array

    @TC13
    Scenario: Regression - Backward compatibility with older clients
    Given a valid custom field exists in the system with id <validCustomFieldId>
    And the request is sent with an older User-Agent header
    When the user sends a GET request to /1.0/kb/customFields/<validCustomFieldId>/auditLogsWithHistory
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array of AuditLog objects

    @TC14
    Scenario: Performance under concurrent requests
    Given multiple valid custom field ids exist in the system
    When the user sends 100 concurrent GET requests to /1.0/kb/customFields/{customFieldId}/auditLogsWithHistory for different ids
    Then all responses should have status code 200 (for existing ids) or 404 (for non-existent ids)
    And the average response time should be within acceptable performance thresholds

    @TC15
    Scenario: Malformed request - Missing customFieldId in path
    Given the user omits the customFieldId in the request path
    When the user sends a GET request to /1.0/kb/customFields//auditLogsWithHistory
    Then the response status code should be 404 or 400
    And the response body should contain an error message indicating invalid or missing path parameter

    @TC16
    Scenario: Edge case - customFieldId at UUID boundary values
    Given a custom field exists in the system with id <boundaryUuidCustomFieldId> (e.g., all zeros or all Fs)
    When the user sends a GET request to /1.0/kb/customFields/<boundaryUuidCustomFieldId>/auditLogsWithHistory
    Then the response status code should be 200 (if exists) or 404 (if not exists)
    And the response body should be as per the existence of the custom field

    @TC17
    Scenario: Edge case - customFieldId with leading/trailing spaces
    Given a custom field exists in the system with id <validCustomFieldId>
    When the user sends a GET request to /1.0/kb/customFields/ <validCustomFieldId> /auditLogsWithHistory (with spaces)
    Then the response status code should be 404 or 400
    And the response body should contain an error message indicating invalid path parameter