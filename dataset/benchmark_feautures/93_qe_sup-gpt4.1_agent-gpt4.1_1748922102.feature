Feature: Retrieve invoice item audit logs with history by id
As a KillBill API user,
I want to retrieve audit logs with history for a specific invoice item by its ID,
so that I can view the change history and audit trail for that invoice item.

  Background:
  Given the KillBill API is available at the correct baseUrl
  And the system contains invoice items with diverse audit log histories
  And I have a valid authentication token
  And the API endpoint GET /1.0/kb/invoiceItems/{invoiceItemId}/auditLogsWithHistory is reachable

    @TC01
    Scenario: Successful retrieval of audit logs with history for a valid invoice item ID
    Given an existing invoice item with ID <valid_invoiceItemId> exists in the system
    And the invoice item has associated audit logs
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/auditLogsWithHistory with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array of AuditLog objects
    And each AuditLog object should contain all required fields as per the API definition
    And the audit logs should accurately reflect the history for the specified invoice item

    @TC02
    Scenario: Retrieval of audit logs when invoice item exists but has no audit logs
    Given an existing invoice item with ID <valid_invoiceItemId_no_logs> exists in the system
    And the invoice item has no associated audit logs
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId_no_logs>/auditLogsWithHistory with a valid authentication token
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC03
    Scenario: Invoice item not found (invalid or non-existent ID)
    Given no invoice item exists with ID <nonexistent_invoiceItemId>
    When I send a GET request to /1.0/kb/invoiceItems/<nonexistent_invoiceItemId>/auditLogsWithHistory with a valid authentication token
    Then the response status code should be 404
    And the response body should contain an appropriate error message indicating the invoice item was not found

    @TC04
    Scenario: Invalid invoice item ID format (malformed UUID)
    Given an invoice item ID <malformed_invoiceItemId> that does not match the expected UUID pattern
    When I send a GET request to /1.0/kb/invoiceItems/<malformed_invoiceItemId>/auditLogsWithHistory with a valid authentication token
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid invoice item ID format

    @TC05
    Scenario: Missing authentication token (unauthorized access)
    Given an existing invoice item with ID <valid_invoiceItemId> exists in the system
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/auditLogsWithHistory without an authentication token
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication is required

    @TC06
    Scenario: Invalid authentication token (unauthorized access)
    Given an existing invoice item with ID <valid_invoiceItemId> exists in the system
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/auditLogsWithHistory with an invalid or expired authentication token
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication is required or invalid

    @TC07
    Scenario: Extra query parameters are provided
    Given an existing invoice item with ID <valid_invoiceItemId> exists in the system
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/auditLogsWithHistory with extra unsupported query parameters
    Then the response status code should be 200
    And the response body should be a JSON array of AuditLog objects
    And the extra parameters should be ignored by the API

    @TC08
    Scenario: System/database unavailable during request
    Given an existing invoice item with ID <valid_invoiceItemId> exists in the system
    And the database is currently unavailable
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/auditLogsWithHistory with a valid authentication token
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailability

    @TC09
    Scenario: Large audit log history for an invoice item (performance and payload size)
    Given an existing invoice item with ID <valid_invoiceItemId_large_logs> exists in the system
    And the invoice item has a very large number of associated audit logs
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId_large_logs>/auditLogsWithHistory with a valid authentication token
    Then the response status code should be 200
    And the response body should be a large JSON array of AuditLog objects
    And the response time should be within acceptable performance thresholds
    And no data truncation should occur

    @TC10
    Scenario: Attempted SQL injection via invoice item ID
    Given an invoice item ID <sql_injection_invoiceItemId> containing SQL injection payload
    When I send a GET request to /1.0/kb/invoiceItems/<sql_injection_invoiceItemId>/auditLogsWithHistory with a valid authentication token
    Then the response status code should be 400 or 404
    And the response body should not contain sensitive system information
    And the system should not execute the injected payload

    @TC11
    Scenario: XSS attempt via invoice item ID
    Given an invoice item ID <xss_invoiceItemId> containing XSS payload
    When I send a GET request to /1.0/kb/invoiceItems/<xss_invoiceItemId>/auditLogsWithHistory with a valid authentication token
    Then the response status code should be 400 or 404
    And the response body should not contain reflected XSS content

    @TC12
    Scenario: Regression - previously fixed issue with missing audit log fields
    Given an existing invoice item with ID <valid_invoiceItemId_regression> exists in the system
    And the invoice item has associated audit logs
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId_regression>/auditLogsWithHistory with a valid authentication token
    Then the response status code should be 200
    And the response body should contain AuditLog objects with all required fields present

    @TC13
    Scenario: Backward compatibility with older clients
    Given an existing invoice item with ID <valid_invoiceItemId> exists in the system
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/auditLogsWithHistory using headers from an older client version
    Then the response status code should be 200
    And the response body should be compatible with the older client

    @TC14
    Scenario: Concurrent requests for the same invoice item
    Given an existing invoice item with ID <valid_invoiceItemId> exists in the system
    When multiple GET requests are sent concurrently to /1.0/kb/invoiceItems/<valid_invoiceItemId>/auditLogsWithHistory with valid authentication tokens
    Then all responses should have status code 200
    And all response bodies should be consistent and correct

    @TC15
    Scenario: Response time under normal and peak load
    Given an existing invoice item with ID <valid_invoiceItemId> exists in the system
    When I send GET requests to /1.0/kb/invoiceItems/<valid_invoiceItemId>/auditLogsWithHistory under normal and peak load conditions
    Then the response time should remain within acceptable thresholds

    @TC16
    Scenario: API returns correct Content-Type header
    Given an existing invoice item with ID <valid_invoiceItemId> exists in the system
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/auditLogsWithHistory
    Then the response should include the header Content-Type with value application/json

    @TC17
    Scenario: Partial input (truncated or incomplete invoice item ID)
    Given an invoice item ID <partial_invoiceItemId> that is incomplete or truncated
    When I send a GET request to /1.0/kb/invoiceItems/<partial_invoiceItemId>/auditLogsWithHistory with a valid authentication token
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid invoice item ID format

    @TC18
    Scenario: Empty database (no invoice items exist)
    Given the system database contains no invoice items
    When I send a GET request to /1.0/kb/invoiceItems/<any_invoiceItemId>/auditLogsWithHistory with a valid authentication token
    Then the response status code should be 404
    And the response body should contain an appropriate error message indicating the invoice item was not found