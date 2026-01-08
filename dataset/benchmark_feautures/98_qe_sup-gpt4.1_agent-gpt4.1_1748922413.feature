Feature: Add custom fields to invoice payment via POST /1.0/kb/invoicePayments/{paymentId}/customFields
As a KillBill API user,
I want to add custom fields to a specific invoice payment,
so that I can store additional metadata on invoice payments.

  Background:
  Given the KillBill API is available
  And the API endpoint POST /1.0/kb/invoicePayments/{paymentId}/customFields is reachable
  And the database contains a variety of invoice payments with and without existing custom fields
  And valid authentication and authorization tokens are available
  And the request will include the required header X-Killbill-CreatedBy
  And the request Content-Type is set to application/json

    @TC01
    Scenario: Successful addition of custom fields to an invoice payment (happy path)
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201
    And the response body contains a JSON array matching the created CustomField objects
    And each CustomField in the response has valid fieldName, fieldValue, and objectType

    @TC02
    Scenario: Add custom fields with optional headers (X-Killbill-Reason and X-Killbill-Comment)
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    And the header X-Killbill-Reason is set to "test reason"
    And the header X-Killbill-Comment is set to "test comment"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201
    And the response body contains a JSON array matching the created CustomField objects

    @TC03
    Scenario: Add custom fields when no custom fields previously exist for the payment
    Given an existing invoice payment with id <valid_paymentId> that has no custom fields
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201
    And the response body contains a JSON array matching the created CustomField objects

    @TC04
    Scenario: Add custom fields when custom fields already exist for the payment
    Given an existing invoice payment with id <valid_paymentId> that already has custom fields
    And a valid JSON array of new CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201
    And the response body contains a JSON array matching the newly created CustomField objects
    And the existing custom fields remain unchanged

    @TC05
    Scenario: Add multiple custom fields in a single request
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array containing multiple CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201
    And the response body contains a JSON array matching the created CustomField objects

    @TC06
    Scenario: Add custom fields with extra, unexpected parameters in the request body
    Given an existing invoice payment with id <valid_paymentId>
    And a JSON array of CustomField objects with extra fields in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201 or 400 depending on API strictness
    And if 201, the response body contains only the valid CustomField properties
    And if 400, the response body contains an error message indicating unexpected fields

    @TC07
    Scenario: Add custom fields with empty request body
    Given an existing invoice payment with id <valid_paymentId>
    And the request body is an empty JSON array
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201 or 400 depending on API design
    And if 201, the response body is an empty array
    And if 400, the response body contains an error message indicating missing custom fields

    @TC08
    Scenario: Add custom fields with malformed JSON in request body
    Given an existing invoice payment with id <valid_paymentId>
    And the request body contains invalid JSON
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating malformed JSON

    @TC09
    Scenario: Add custom fields with missing required header X-Killbill-CreatedBy
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is not set
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 400 or 401 depending on API design
    And the response body contains an error message indicating missing required header

    @TC10
    Scenario: Add custom fields with invalid paymentId format
    Given a paymentId that does not match the uuid pattern
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<invalid_paymentId>/customFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid paymentId

    @TC11
    Scenario: Add custom fields to a non-existent paymentId
    Given a paymentId that does not exist in the system
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<nonexistent_paymentId>/customFields
    Then the API responds with HTTP 404
    And the response body contains an error message indicating payment not found

    @TC12
    Scenario: Add custom fields with unauthorized access (invalid or missing authentication token)
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects in the request body
    And the authentication token is missing or invalid
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 401
    And the response body contains an error message indicating unauthorized access

    @TC13
    Scenario: Add custom fields when dependent service is unavailable
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    And the database or dependent service is down
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 503
    And the response body contains an error message indicating service unavailable

    @TC14
    Scenario: Add custom fields with input that attempts SQL injection or XSS
    Given an existing invoice payment with id <valid_paymentId>
    And a JSON array of CustomField objects containing SQL injection or XSS payloads in fieldValue
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 400 or sanitizes the input
    And the response does not persist malicious payloads

    @TC15
    Scenario: Add custom fields with very large request body (stress test)
    Given an existing invoice payment with id <valid_paymentId>
    And a JSON array of CustomField objects near the maximum allowed payload size
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201 or 413 depending on payload size
    And if 201, the response body contains all created CustomField objects
    And if 413, the response body contains an error message indicating payload too large

    @TC16
    Scenario: Add custom fields with partial input (missing required fields in CustomField)
    Given an existing invoice payment with id <valid_paymentId>
    And a JSON array of CustomField objects with missing required properties
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating missing required fields

    @TC17
    Scenario: Add custom fields with additional, unsupported query parameters
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields?unexpected=param
    Then the API responds with HTTP 201 or 400 depending on API strictness
    And if 400, the response body contains an error message indicating unsupported parameters

    @TC18
    Scenario: Add custom fields with network timeout or slow response
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    And the network is experiencing high latency
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds within the documented timeout threshold
    And if the timeout is exceeded, the client receives an appropriate error (e.g., 504 Gateway Timeout)

    @TC19
    Scenario: Add custom fields concurrently to the same payment (concurrency test)
    Given an existing invoice payment with id <valid_paymentId>
    And multiple clients each have a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When multiple clients send POST requests concurrently to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201 for each successful request
    And all custom fields are correctly created without data loss or corruption

    @TC20
    Scenario: Regression - Add custom fields to payment after previous bug fix (e.g., duplicate field names)
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects, including duplicate field names
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201 or 400 depending on API logic
    And if 201, the response body contains all created CustomField objects
    And if 400, the response body contains an error message indicating duplicate fields

    @TC21
    Scenario: Regression - Add custom fields with previously problematic unicode characters
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects containing unicode characters in fieldValue
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201
    And the response body contains the unicode characters as expected

    @TC22
    Scenario: Performance - Add custom fields under normal load
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201 within 2 seconds

    @TC23
    Scenario: Performance - Add custom fields under peak load (stress test)
    Given multiple invoice payments exist
    And each has a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When multiple clients send POST requests to /1.0/kb/invoicePayments/{paymentId}/customFields simultaneously
    Then all APIs respond with HTTP 201 within the documented SLA

    @TC24
    Scenario: Integration - Add custom fields and verify persistence
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201
    And the created custom fields are persisted and retrievable via GET /1.0/kb/invoicePayments/<valid_paymentId>/customFields

    @TC25
    Scenario: Integration - Add custom fields and verify data consistency across systems
    Given an existing invoice payment with id <valid_paymentId>
    And a valid JSON array of CustomField objects in the request body
    And the header X-Killbill-CreatedBy is set to "qa_user"
    When the client sends a POST request to /1.0/kb/invoicePayments/<valid_paymentId>/customFields
    Then the API responds with HTTP 201
    And the custom fields are reflected in all relevant system integrations

    @TC26
    Scenario: Accessibility - API documentation is accessible and clear
    Given the API documentation for POST /1.0/kb/invoicePayments/{paymentId}/customFields is available
    When a screen reader is used to navigate the documentation
    Then all required fields, error codes, and request/response examples are accessible and understandable