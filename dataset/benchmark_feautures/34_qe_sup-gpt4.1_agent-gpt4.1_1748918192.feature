Feature: Retrieve blocking state audit logs with history by id
As a KillBill API user,
I want to retrieve audit logs with history for a specific blocking state by its ID,
so that I can review historical changes and actions related to account blocking states.

  Background:
  Given the KillBill API server is running and accessible
  And the API endpoint GET /1.0/kb/accounts/block/{blockingId}/auditLogsWithHistory is available
  And the request is authenticated with a valid API key and token
  And the database contains various blocking states with and without audit logs

    @TC01
    Scenario: Successful retrieval of audit logs with history for a valid blockingId
    Given a blocking state exists in the system with blockingId = <valid_blockingId>
    And the blocking state has associated audit logs
    When the user sends a GET request to /1.0/kb/accounts/block/<valid_blockingId>/auditLogsWithHistory
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array of AuditLog objects
    And each AuditLog object should contain all required fields as per the API definition
    And the audit log history should be complete and accurate for the given blockingId

    @TC02
    Scenario: Retrieval for a valid blockingId with no associated audit logs
    Given a blocking state exists in the system with blockingId = <valid_blockingId_no_logs>
    And the blocking state has no associated audit logs
    When the user sends a GET request to /1.0/kb/accounts/block/<valid_blockingId_no_logs>/auditLogsWithHistory
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be an empty JSON array

    @TC03
    Scenario: Retrieval for a non-existent blockingId
    Given no blocking state exists in the system with blockingId = <nonexistent_blockingId>
    When the user sends a GET request to /1.0/kb/accounts/block/<nonexistent_blockingId>/auditLogsWithHistory
    Then the response status code should be 404
    And the response body should contain an error message indicating blocking state not found

    @TC04
    Scenario: Retrieval with an invalid blockingId format (malformed UUID)
    Given the blockingId = <invalid_format_blockingId> does not match the required UUID pattern
    When the user sends a GET request to /1.0/kb/accounts/block/<invalid_format_blockingId>/auditLogsWithHistory
    Then the response status code should be 400 or 404 (as per API design)
    And the response body should contain an error message indicating invalid blockingId

    @TC05
    Scenario: Retrieval with missing authentication
    Given the user does not provide authentication credentials
    When the user sends a GET request to /1.0/kb/accounts/block/<valid_blockingId>/auditLogsWithHistory
    Then the response status code should be 401
    And the response body should contain an authentication error message

    @TC06
    Scenario: Retrieval with invalid authentication
    Given the user provides invalid authentication credentials
    When the user sends a GET request to /1.0/kb/accounts/block/<valid_blockingId>/auditLogsWithHistory
    Then the response status code should be 401
    And the response body should contain an authentication error message

    @TC07
    Scenario: Retrieval when the API service is unavailable
    Given the KillBill API service is down or unreachable
    When the user sends a GET request to /1.0/kb/accounts/block/<valid_blockingId>/auditLogsWithHistory
    Then the response status code should be 503
    And the response body should contain a service unavailable error message

    @TC08
    Scenario: Retrieval with extra/unexpected query parameters
    Given a blocking state exists in the system with blockingId = <valid_blockingId>
    When the user sends a GET request to /1.0/kb/accounts/block/<valid_blockingId>/auditLogsWithHistory?unexpected=param
    Then the response status code should be 200
    And the response body should be as per normal successful response (ignoring extra parameters)

    @TC09
    Scenario: Retrieval with very large audit log history
    Given a blocking state exists in the system with blockingId = <large_history_blockingId>
    And the blocking state has a very large number of associated audit logs
    When the user sends a GET request to /1.0/kb/accounts/block/<large_history_blockingId>/auditLogsWithHistory
    Then the response status code should be 200
    And the response body should contain all audit log entries
    And the response time should be within acceptable limits (e.g., < 2 seconds)

    @TC10
    Scenario: Retrieval with boundary value blockingId (minimum/maximum UUID values)
    Given a blocking state exists in the system with blockingId = <min_or_max_uuid_blockingId>
    When the user sends a GET request to /1.0/kb/accounts/block/<min_or_max_uuid_blockingId>/auditLogsWithHistory
    Then the response status code should be 200 or 404 depending on existence
    And the response body should be correct according to the blocking state existence

    @TC11
    Scenario: Security test - SQL injection attempt in blockingId
    Given the blockingId contains SQL injection payload (e.g., "1 OR 1=1")
    When the user sends a GET request to /1.0/kb/accounts/block/<sql_injection_blockingId>/auditLogsWithHistory
    Then the response status code should be 400 or 404
    And the response body should not expose sensitive information

    @TC12
    Scenario: Security test - XSS attempt in blockingId
    Given the blockingId contains XSS payload (e.g., "<script>alert(1)</script>")
    When the user sends a GET request to /1.0/kb/accounts/block/<xss_blockingId>/auditLogsWithHistory
    Then the response status code should be 400 or 404
    And the response body should not execute or reflect the payload

    @TC13
    Scenario: Retry after transient network failure
    Given a transient network failure occurs during the request
    When the user retries the GET request to /1.0/kb/accounts/block/<valid_blockingId>/auditLogsWithHistory
    Then the response status code should be 200 upon successful retry
    And the response body should be as per normal successful response

    @TC14
    Scenario: Regression - Retrieval for blockingId with previously fixed bug (e.g., missing audit logs)
    Given a blocking state exists in the system with blockingId = <regression_blockingId>
    And previous bug caused missing audit logs for this blockingId
    When the user sends a GET request to /1.0/kb/accounts/block/<regression_blockingId>/auditLogsWithHistory
    Then the response status code should be 200
    And the response body should now include all expected audit logs

    @TC15
    Scenario: Backward compatibility - API invocation with legacy client headers
    Given a blocking state exists in the system with blockingId = <valid_blockingId>
    And the request includes legacy client headers
    When the user sends a GET request to /1.0/kb/accounts/block/<valid_blockingId>/auditLogsWithHistory
    Then the response status code should be 200
    And the response body should be as per normal successful response

    @TC16
    Scenario: Performance - Concurrent requests for multiple blockingIds
    Given multiple valid blockingIds exist in the system
    When the user sends concurrent GET requests to /1.0/kb/accounts/block/<blockingId>/auditLogsWithHistory for each
    Then all responses should have status code 200
    And all response bodies should contain the correct audit logs for each blockingId
    And the system should not degrade below acceptable performance thresholds

    @TC17
    Scenario: State variation - Retrieval when database is empty
    Given the database contains no blocking states
    When the user sends a GET request to /1.0/kb/accounts/block/<any_blockingId>/auditLogsWithHistory
    Then the response status code should be 404
    And the response body should contain an error message indicating blocking state not found

    @TC18
    Scenario: State variation - Retrieval when database is partially populated
    Given the database contains some blocking states with and without audit logs
    When the user sends a GET request to /1.0/kb/accounts/block/<blockingId_with_logs>/auditLogsWithHistory
    Then the response status code should be 200
    And the response body should contain the correct audit logs for the given blockingId

    @TC19
    Scenario: Response structure verification
    Given a blocking state exists in the system with blockingId = <valid_blockingId>
    When the user sends a GET request to /1.0/kb/accounts/block/<valid_blockingId>/auditLogsWithHistory
    Then the response body should match the JSON schema for AuditLog array as defined in the API specification

    @TC20
    Scenario: Timeout condition for slow backend
    Given the backend is responding slowly
    When the user sends a GET request to /1.0/kb/accounts/block/<valid_blockingId>/auditLogsWithHistory
    Then the request should timeout after the configured timeout period
    And the response status code should be 504
    And the response body should indicate a gateway timeout error