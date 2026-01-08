Feature: Modify custom fields for an invoice payment via PUT /1.0/kb/invoicePayments/{paymentId}/customFields
As a KillBill API user,
I want to modify custom fields for a specific invoice payment,
so that I can update or set additional metadata on invoice payments.

  Background:
  Given the KillBill API is accessible
  And the database contains invoice payments with diverse custom fields
  And a valid authentication token is present
  And the API endpoint /1.0/kb/invoicePayments/{paymentId}/customFields is available

    @TC01
    Scenario: Successful modification of custom fields with required headers
    Given an existing invoice payment with paymentId "valid-uuid-1"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid array of CustomField objects
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-1/customFields
    Then the response status code should be 204
    And the custom fields for the payment should be updated in the database

    @TC02
    Scenario: Successful modification with all optional headers provided
    Given an existing invoice payment with paymentId "valid-uuid-2"
    And the request headers X-Killbill-CreatedBy is set to "admin-user", X-Killbill-Reason is set to "Update info", and X-Killbill-Comment is set to "Bulk update"
    And the request body contains a valid array of CustomField objects
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-2/customFields
    Then the response status code should be 204
    And the custom fields for the payment should be updated accordingly

    @TC03
    Scenario: Successful modification when no custom fields exist initially
    Given an existing invoice payment with paymentId "valid-uuid-3" that has no custom fields
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid array of CustomField objects
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-3/customFields
    Then the response status code should be 204
    And the custom fields should be created for the payment

    @TC04
    Scenario: Successful modification with empty custom fields array (removal or no-op)
    Given an existing invoice payment with paymentId "valid-uuid-4" that has existing custom fields
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains an empty array
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-4/customFields
    Then the response status code should be 204
    And all custom fields for the payment should be removed or remain unchanged as per API behavior

    @TC05
    Scenario: Error when paymentId is invalid format
    Given a paymentId "invalid-uuid" that does not match the uuid pattern
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid array of CustomField objects
    When the user sends a PUT request to /1.0/kb/invoicePayments/invalid-uuid/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid paymentId

    @TC06
    Scenario: Error when paymentId is valid format but not found
    Given a paymentId "00000000-0000-0000-0000-000000000000" that does not exist in the system
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid array of CustomField objects
    When the user sends a PUT request to /1.0/kb/invoicePayments/00000000-0000-0000-0000-000000000000/customFields
    Then the response status code should be 404
    And the response body should contain an error message indicating payment not found

    @TC07
    Scenario: Error when required header X-Killbill-CreatedBy is missing
    Given an existing invoice payment with paymentId "valid-uuid-5"
    And the request does not include the X-Killbill-CreatedBy header
    And the request body contains a valid array of CustomField objects
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-5/customFields
    Then the response status code should be 400
    And the response body should indicate the missing required header

    @TC08
    Scenario: Error when request body is missing
    Given an existing invoice payment with paymentId "valid-uuid-6"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body is missing
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-6/customFields
    Then the response status code should be 400
    And the response body should indicate a missing or malformed body

    @TC09
    Scenario: Error when request body is malformed JSON
    Given an existing invoice payment with paymentId "valid-uuid-7"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains malformed JSON
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-7/customFields
    Then the response status code should be 400
    And the response body should indicate a malformed request body

    @TC10
    Scenario: Error when CustomField objects are invalid
    Given an existing invoice payment with paymentId "valid-uuid-8"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains CustomField objects with missing required fields or invalid data types
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-8/customFields
    Then the response status code should be 400
    And the response body should indicate the validation error

    @TC11
    Scenario: Unauthorized access attempt
    Given an existing invoice payment with paymentId "valid-uuid-9"
    And the authentication token is missing or invalid
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid array of CustomField objects
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-9/customFields
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC12
    Scenario: System error or dependency failure
    Given an existing invoice payment with paymentId "valid-uuid-10"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid array of CustomField objects
    And the database is unavailable or returns an error
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-10/customFields
    Then the response status code should be 500
    And the response body should indicate a server error

    @TC13
    Scenario: Security - Injection attempt in custom field value
    Given an existing invoice payment with paymentId "valid-uuid-11"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a CustomField object with a value attempting SQL injection
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-11/customFields
    Then the response status code should be 400 or 422
    And the response body should indicate invalid input or security violation

    @TC14
    Scenario: Edge case - Large number of custom fields
    Given an existing invoice payment with paymentId "valid-uuid-12"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a very large array (e.g., 1000+) of CustomField objects
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-12/customFields
    Then the response status code should be 204 if successful
    And the response time should be within acceptable limits
    And all custom fields should be updated

    @TC15
    Scenario: Edge case - Maximum allowed length for custom field values
    Given an existing invoice payment with paymentId "valid-uuid-13"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains CustomField objects with values at the maximum allowed length
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-13/customFields
    Then the response status code should be 204 if successful
    And the custom fields should be updated with truncated or full values as per API behavior

    @TC16
    Scenario: Edge case - Extra unexpected parameters in request body
    Given an existing invoice payment with paymentId "valid-uuid-14"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains valid CustomField objects and extra unexpected properties
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-14/customFields
    Then the response status code should be 204 or 400 as per API behavior
    And the response body should indicate handling of extra properties

    @TC17
    Scenario: Integration - Verify data consistency after update
    Given an existing invoice payment with paymentId "valid-uuid-15"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid array of CustomField objects
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-15/customFields
    Then the response status code should be 204
    And a subsequent GET request to /1.0/kb/invoicePayments/valid-uuid-15/customFields returns the updated fields

    @TC18
    Scenario: Regression - Previously fixed issue with duplicate custom field names
    Given an existing invoice payment with paymentId "valid-uuid-16"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains CustomField objects with duplicate field names
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-16/customFields
    Then the response status code should be 400 or 204 as per API behavior
    And the response body or subsequent GET should reflect correct handling of duplicates

    @TC19
    Scenario: Performance - Multiple concurrent requests
    Given multiple concurrent PUT requests to /1.0/kb/invoicePayments/{paymentId}/customFields with valid data
    When the requests are executed simultaneously
    Then all requests should complete with status code 204
    And data consistency should be maintained
    And response times should be within acceptable performance thresholds

    @TC20
    Scenario: Performance - Large payload size
    Given an existing invoice payment with paymentId "valid-uuid-17"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a payload approaching the maximum allowed size
    When the user sends a PUT request to /1.0/kb/invoicePayments/valid-uuid-17/customFields
    Then the response status code should be 204 if successful
    And the response time should be within acceptable limits
    And the system should not experience memory or resource exhaustion