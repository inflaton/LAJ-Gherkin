Feature: Retrieve bundle audit logs with history by id
  As a KillBill API user,
  I want to retrieve audit logs with history for a specific bundle using its ID,
  so that I can review all relevant changes and actions performed on the bundle.

    Background:
    Given the KillBill API server is running and reachable
    And the database contains bundles with diverse audit log histories
    And I have a valid API authentication token
    And the API endpoint "/1.0/kb/bundles/{bundleId}/auditLogsWithHistory" is available
    And the bundleId path parameter is required and must be a valid UUID

      @TC01
      Scenario: Successful retrieval of audit logs with history for an existing bundle
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174000"
      And the bundle has associated audit log history
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 200
      And the response Content-Type should be "application/json"
      And the response body should be a JSON array of AuditLog objects
      And each AuditLog object should match the expected schema as defined in the API documentation
      And the audit logs should correspond to the specified bundleId

      @TC02
      Scenario: Retrieval when the bundle exists but has no audit logs
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174001"
      And the bundle has no associated audit log history
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174001/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 200
      And the response Content-Type should be "application/json"
      And the response body should be an empty JSON array

      @TC03
      Scenario: Retrieval with a non-existent bundleId
      Given no bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174999"
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174999/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 404
      And the response body should contain an error message indicating the bundle was not found

      @TC04
      Scenario: Retrieval with an invalid bundleId format
      Given the bundleId provided is "invalid-uuid"
      When I perform a GET request to "/1.0/kb/bundles/invalid-uuid/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 400
      And the response body should contain an error message indicating invalid bundleId format

      @TC05
      Scenario: Retrieval with missing authentication token
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174000"
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000/auditLogsWithHistory" without an authentication token
      Then the response status code should be 401
      And the response body should contain an error message indicating authentication is required

      @TC06
      Scenario: Retrieval with an invalid authentication token
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174000"
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000/auditLogsWithHistory" with an invalid authentication token
      Then the response status code should be 401
      And the response body should contain an error message indicating authentication failure

      @TC07
      Scenario: Retrieval when the API service is unavailable
      Given the KillBill API service is temporarily down
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 503
      And the response body should contain an error message indicating service unavailability

      @TC08
      Scenario: Retrieval with extra unexpected query parameters
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174000"
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000/auditLogsWithHistory?foo=bar"
      Then the response status code should be 200
      And the response body should be a valid JSON array of AuditLog objects

      @TC09
      Scenario: Retrieval with a bundleId at UUID boundary values
      Given a bundle exists in the system with bundleId "00000000-0000-0000-0000-000000000000"
      When I perform a GET request to "/1.0/kb/bundles/00000000-0000-0000-0000-000000000000/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 200 or 404 depending on existence
      And the response body should be a valid JSON array if found, or an error message if not found

      @TC10
      Scenario: Retrieval with a very large number of audit logs
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174002"
      And the bundle has a very large number of associated audit logs (e.g., 10,000+)
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174002/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 200
      And the response body should be a JSON array of AuditLog objects
      And the response time should be within acceptable performance thresholds (e.g., <2 seconds)

      @TC11
      Scenario: Security - SQL injection attempt in bundleId
      Given the bundleId provided is "123e4567-e89b-12d3-a456-426614174000' OR '1'='1"
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000' OR '1'='1/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 400 or 404
      And the response body should not expose internal errors or stack traces
      And the system should remain secure

      @TC12
      Scenario: Recovery from transient network failure
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174000"
      And a transient network failure occurs during the request
      When I retry the GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 200
      And the response body should be a valid JSON array of AuditLog objects

      @TC13
      Scenario: Regression - previously fixed issue with malformed audit log entries
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174003"
      And the bundle has audit log entries previously affected by a known bug (e.g., malformed JSON)
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174003/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 200
      And the response body should contain only well-formed AuditLog objects

      @TC14
      Scenario: Integration - Consistency with other audit log retrieval APIs
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174000"
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000/auditLogsWithHistory" and to other audit log endpoints for the same bundle
      Then the audit log data should be consistent across all endpoints

      @TC15
      Scenario: State variation - database is empty
      Given the database contains no bundles
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 404
      And the response body should contain an error message indicating the bundle was not found

      @TC16
      Scenario: State variation - database is partially populated
      Given the database contains some bundles but not the requested bundleId
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174999/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 404
      And the response body should contain an error message indicating the bundle was not found

      @TC17
      Scenario: Performance - concurrent requests for audit logs
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174000"
      When I perform 50 concurrent GET requests to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000/auditLogsWithHistory" with valid authentication tokens
      Then all responses should have status code 200
      And all response bodies should be valid JSON arrays of AuditLog objects
      And the system should not degrade under load

      @TC18
      Scenario: Retrieval with trailing slash in the endpoint
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174000"
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000/auditLogsWithHistory/" with a valid authentication token
      Then the response status code should be 200
      And the response body should be a valid JSON array of AuditLog objects

      @TC19
      Scenario: Retrieval with whitespace in bundleId
      Given the bundleId provided is " 123e4567-e89b-12d3-a456-426614174000 "
      When I perform a GET request to "/1.0/kb/bundles/ 123e4567-e89b-12d3-a456-426614174000 /auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 400 or 404
      And the response body should indicate invalid bundleId or not found

      @TC20
      Scenario: Retrieval with special characters in bundleId
      Given the bundleId provided is "123e4567-e89b-12d3-a456-426614174000$%"
      When I perform a GET request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000$%/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 400
      And the response body should indicate invalid bundleId format

      @TC21
      Scenario: Retrieval with HTTP method other than GET
      Given a bundle exists in the system with bundleId "123e4567-e89b-12d3-a456-426614174000"
      When I perform a POST request to "/1.0/kb/bundles/123e4567-e89b-12d3-a456-426614174000/auditLogsWithHistory" with a valid authentication token
      Then the response status code should be 405
      And the response body should indicate method not allowed