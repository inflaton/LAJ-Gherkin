Feature: Update Payment Transaction State via Admin API
As an administrator of KillBill,
I want to update the state of a payment transaction and its associated payment state via the Admin API,
so that I can correct or adjust payment records as needed.

  Background:
  Given the KillBill API server is running and accessible
  And the database contains at least one payment with multiple transactions
  And valid authentication credentials are available
  And the API consumer has administrator privileges
  And the AdminPayment schema is known and valid
  And the required headers (X-Killbill-CreatedBy) are set for all requests

    @TC01
    Scenario: Successful update of payment transaction and payment state
    Given a valid paymentId and paymentTransactionId exist in the system
    And a valid AdminPayment request body with updated state fields is prepared
    When the administrator sends a PUT request to /1.0/kb/admin/payments/{paymentId}/transactions/{paymentTransactionId} with all required headers
    Then the API responds with HTTP 204 No Content
    And the payment transaction and payment state are updated in the database

    @TC02
    Scenario: Successful update with optional headers
    Given a valid paymentId and paymentTransactionId exist in the system
    And a valid AdminPayment request body is prepared
    And X-Killbill-Reason and X-Killbill-Comment headers are included
    When the administrator sends a PUT request to /1.0/kb/admin/payments/{paymentId}/transactions/{paymentTransactionId} with all headers
    Then the API responds with HTTP 204 No Content
    And the payment transaction and payment state are updated accordingly

    @TC03
    Scenario: Update with missing required header X-Killbill-CreatedBy
    Given a valid paymentId and paymentTransactionId exist in the system
    And a valid AdminPayment request body is prepared
    When the administrator sends a PUT request without the X-Killbill-CreatedBy header
    Then the API responds with HTTP 400 Bad Request
    And the response contains an error message indicating the missing header

    @TC04
    Scenario: Update with invalid paymentId format
    Given an invalid paymentId (not matching UUID pattern) and a valid paymentTransactionId
    And a valid AdminPayment request body is prepared
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 400 Bad Request
    And the response contains an error message about invalid paymentId

    @TC05
    Scenario: Update with invalid paymentTransactionId format
    Given a valid paymentId and an invalid paymentTransactionId (not matching UUID pattern)
    And a valid AdminPayment request body is prepared
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 400 Bad Request
    And the response contains an error message about invalid paymentTransactionId

    @TC06
    Scenario: Update with non-existent paymentId
    Given a paymentId that does not exist in the system and a valid paymentTransactionId
    And a valid AdminPayment request body is prepared
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 404 Not Found
    And the response contains an error message indicating payment not found

    @TC07
    Scenario: Update with non-existent paymentTransactionId
    Given a valid paymentId and a paymentTransactionId that does not exist for that payment
    And a valid AdminPayment request body is prepared
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 404 Not Found
    And the response contains an error message indicating transaction not found

    @TC08
    Scenario: Update with inconsistent or invalid state data in AdminPayment body
    Given a valid paymentId and paymentTransactionId
    And an AdminPayment request body with inconsistent or invalid state fields (e.g., invalid state transition)
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 400 Bad Request
    And the response contains an error message about invalid state data

    @TC09
    Scenario: Update with missing request body
    Given a valid paymentId and paymentTransactionId
    When the administrator sends a PUT request without a request body
    Then the API responds with HTTP 400 Bad Request
    And the response contains an error message indicating the missing body

    @TC10
    Scenario: Update with malformed JSON in request body
    Given a valid paymentId and paymentTransactionId
    And a malformed JSON body is prepared
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 400 Bad Request
    And the response contains an error message about JSON parsing

    @TC11
    Scenario: Unauthorized access attempt
    Given a valid paymentId and paymentTransactionId
    And a valid AdminPayment request body is prepared
    When the request is sent without valid authentication credentials
    Then the API responds with HTTP 401 Unauthorized
    And the response contains an error message about authentication

    @TC12
    Scenario: Attempt update when payment and transaction database is empty
    Given the payment and transaction tables are empty
    When the administrator sends a PUT request to the endpoint with any paymentId and paymentTransactionId
    Then the API responds with HTTP 404 Not Found
    And the response contains an error message indicating payment or transaction not found

    @TC13
    Scenario: Update with extra, unsupported parameters in the request body
    Given a valid paymentId and paymentTransactionId
    And a valid AdminPayment request body with additional unsupported fields
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 204 No Content
    And the unsupported fields are ignored

    @TC14
    Scenario: Update with maximum allowed field values
    Given a valid paymentId and paymentTransactionId
    And an AdminPayment request body with maximum allowed string lengths and numeric values
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 204 No Content
    And the values are stored correctly without truncation or error

    @TC15
    Scenario: Update with minimum allowed/empty field values
    Given a valid paymentId and paymentTransactionId
    And an AdminPayment request body with minimum allowed or empty values for optional fields
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 204 No Content
    And the values are stored correctly

    @TC16
    Scenario: Update with slow backend or dependency timeout
    Given a valid paymentId and paymentTransactionId
    And a valid AdminPayment request body is prepared
    And the backend service is deliberately slowed or unresponsive
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 504 Gateway Timeout or 503 Service Unavailable
    And the response contains an appropriate error message

    @TC17
    Scenario: Update with concurrent requests on the same transaction
    Given a valid paymentId and paymentTransactionId
    And multiple valid AdminPayment request bodies are prepared
    When multiple administrators send PUT requests concurrently to the same endpoint
    Then the API responds with HTTP 204 No Content for successful updates
    And the final state is consistent and no data corruption occurs

    @TC18
    Scenario: Security testing - SQL injection attempt in AdminPayment fields
    Given a valid paymentId and paymentTransactionId
    And an AdminPayment request body with SQL injection payloads in string fields
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 400 Bad Request or ignores malicious input
    And no injection is executed in the backend

    @TC19
    Scenario: Security testing - XSS attempt in AdminPayment fields
    Given a valid paymentId and paymentTransactionId
    And an AdminPayment request body with XSS payloads in string fields
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 204 No Content or sanitizes input
    And no XSS is possible in downstream consumers

    @TC20
    Scenario: Regression - Update transaction with previously problematic state
    Given a valid paymentId and paymentTransactionId that previously caused errors
    And a valid AdminPayment request body is prepared
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 204 No Content
    And the update succeeds without regression

    @TC21
    Scenario: Performance - Update under high load
    Given a valid paymentId and paymentTransactionId
    And a valid AdminPayment request body is prepared
    When the administrator sends 1000 PUT requests in rapid succession
    Then the API responds with HTTP 204 No Content for each request
    And the average response time is within acceptable limits

    @TC22
    Scenario: Integration - Update when dependent service is degraded
    Given a valid paymentId and paymentTransactionId
    And a valid AdminPayment request body is prepared
    And a dependent service is partially degraded
    When the administrator sends a PUT request to the endpoint
    Then the API responds according to the system's resilience strategy (e.g., retries, fallback, error message)
    And data consistency is maintained

    @TC23
    Scenario: Update with partial input (only required fields in AdminPayment)
    Given a valid paymentId and paymentTransactionId
    And an AdminPayment request body with only required fields
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 204 No Content
    And the update is successful

    @TC24
    Scenario: Update with all possible combinations of optional headers
    Given a valid paymentId and paymentTransactionId
    And a valid AdminPayment request body is prepared
    When the administrator sends PUT requests with all combinations of X-Killbill-Reason and X-Killbill-Comment headers (present/missing)
    Then the API responds with HTTP 204 No Content for each valid combination
    And the update is successful

    @TC25
    Scenario: Update with extra query parameters
    Given a valid paymentId and paymentTransactionId
    And a valid AdminPayment request body is prepared
    When the administrator sends a PUT request with unsupported query parameters
    Then the API responds with HTTP 204 No Content
    And ignores the extra query parameters

    @TC26
    Scenario: Update with whitespace or case variations in header values
    Given a valid paymentId and paymentTransactionId
    And a valid AdminPayment request body is prepared
    When the administrator sends a PUT request with header values containing leading/trailing whitespace or case variations
    Then the API responds with HTTP 204 No Content
    And processes the request correctly

    @TC27
    Scenario: Update when paymentId and paymentTransactionId refer to different payments
    Given a valid paymentId and a paymentTransactionId that belongs to a different payment
    And a valid AdminPayment request body is prepared
    When the administrator sends a PUT request to the endpoint
    Then the API responds with HTTP 400 Bad Request or 404 Not Found
    And the response contains an error message about mismatched IDs

    @TC28
    Scenario: Accessibility - API documentation is accessible
    Given the API documentation is available
    When an administrator reviews the documentation for the PUT endpoint
    Then the documentation is accessible via screen readers
    And all required parameters and error codes are described