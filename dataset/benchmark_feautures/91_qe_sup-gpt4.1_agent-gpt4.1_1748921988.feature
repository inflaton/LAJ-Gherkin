Feature: Modify custom fields for an invoice item via PUT /1.0/kb/invoiceItems/{invoiceItemId}/customFields
As an API user,
I want to modify custom fields for a specific invoice item,
so that I can update invoice item metadata as needed.

  Background:
  Given the KillBill API server is running and reachable
  And the database contains invoice items with diverse existing custom fields
  And valid authentication and authorization tokens are configured
  And the API endpoint PUT /1.0/kb/invoiceItems/{invoiceItemId}/customFields is available
  And the CustomField schema is known and valid

    @TC01
    Scenario: Successful modification of custom fields with all required parameters
    Given an existing invoice item with id <valid_invoiceItemId>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 204
    And the custom fields for the invoice item should be updated in the database

    @TC02
    Scenario: Successful modification with all optional headers provided
    Given an existing invoice item with id <valid_invoiceItemId>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    And the X-Killbill-Reason header is set to "update reason"
    And the X-Killbill-Comment header is set to "additional comment"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 204
    And the custom fields for the invoice item should be updated in the database

    @TC03
    Scenario: Successful modification with only required header provided
    Given an existing invoice item with id <valid_invoiceItemId>
    And a valid JSON array of CustomField objects in the request body
    And only the X-Killbill-CreatedBy header is present
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 204
    And the custom fields for the invoice item should be updated in the database

    @TC04
    Scenario: Successful modification when invoice item has no prior custom fields
    Given an existing invoice item with id <valid_invoiceItemId> and no custom fields
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 204
    And the custom fields for the invoice item should be created in the database

    @TC05
    Scenario: Successful modification when invoice item already has custom fields
    Given an existing invoice item with id <valid_invoiceItemId> and existing custom fields
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 204
    And the custom fields for the invoice item should be updated accordingly

    @TC06
    Scenario: Attempt to modify custom fields with invalid invoiceItemId format
    Given an invoice item id <invalid_invoiceItemId> that does not match the uuid pattern
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<invalid_invoiceItemId>/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid invoice item ID

    @TC07
    Scenario: Attempt to modify custom fields for a non-existent invoice item
    Given a non-existent invoice item id <nonexistent_invoiceItemId> matching uuid pattern
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<nonexistent_invoiceItemId>/customFields
    Then the response status code should be 404
    And the response body should contain an error message indicating invoice item not found

    @TC08
    Scenario: Attempt to modify custom fields with malformed JSON body
    Given an existing invoice item with id <valid_invoiceItemId>
    And a malformed JSON body in the request
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating malformed request body

    @TC09
    Scenario: Attempt to modify custom fields with missing required header
    Given an existing invoice item with id <valid_invoiceItemId>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is missing
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating missing required header

    @TC10
    Scenario: Attempt to modify custom fields with empty request body
    Given an existing invoice item with id <valid_invoiceItemId>
    And an empty request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid or missing request body

    @TC11
    Scenario: Attempt to modify custom fields with unsupported fields in request body
    Given an existing invoice item with id <valid_invoiceItemId>
    And a JSON array of CustomField objects containing extra/unsupported fields
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating unsupported fields

    @TC12
    Scenario: Attempt to modify custom fields with excessively large payload
    Given an existing invoice item with id <valid_invoiceItemId>
    And a JSON array of CustomField objects approaching the maximum allowed size
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 204 or 413 depending on system configuration
    And if 413, the response body should contain an error message indicating payload too large

    @TC13
    Scenario: Attempt to modify custom fields with invalid authentication
    Given an existing invoice item with id <valid_invoiceItemId>
    And a valid JSON array of CustomField objects in the request body
    And the authentication token is missing or invalid
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC14
    Scenario: Attempt to modify custom fields with SQL injection in custom field values
    Given an existing invoice item with id <valid_invoiceItemId>
    And a JSON array of CustomField objects containing SQL injection payloads in field values
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid input or security violation

    @TC15
    Scenario: System error during modification (e.g., database unavailable)
    Given an existing invoice item with id <valid_invoiceItemId>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    And the database is unavailable
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 500
    And the response body should contain an error message indicating internal server error

    @TC16
    Scenario: Timeout occurs during modification of custom fields
    Given an existing invoice item with id <valid_invoiceItemId>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    And the system is under heavy load
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 504
    And the response body should contain an error message indicating gateway timeout

    @TC17
    Scenario: Verify idempotency of repeated requests with same payload
    Given an existing invoice item with id <valid_invoiceItemId>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends the same PUT request multiple times
    Then the response status code should be 204 each time
    And the custom fields for the invoice item should remain consistent

    @TC18
    Scenario: Regression - previously fixed bug where updating custom fields caused data loss
    Given an existing invoice item with id <valid_invoiceItemId> and existing custom fields
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 204
    And no unrelated data for the invoice item should be lost or corrupted

    @TC19
    Scenario: Integration - dependent service is unavailable
    Given an existing invoice item with id <valid_invoiceItemId>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    And a dependent service (e.g., audit logging) is unavailable
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC20
    Scenario: Performance - modifying custom fields for large number of invoice items in parallel
    Given a set of N invoice items each with unique ids
    And valid JSON arrays of CustomField objects for each
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends parallel PUT requests to /1.0/kb/invoiceItems/{invoiceItemId}/customFields for all N items
    Then the average response time should be within acceptable performance thresholds
    And all custom fields should be updated correctly for each invoice item

    @TC21
    Scenario: Performance - modifying custom fields with large payload for a single invoice item
    Given an existing invoice item with id <valid_invoiceItemId>
    And a JSON array of CustomField objects at maximum allowed size
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 204
    And the response time should be within acceptable limits

    @TC22
    Scenario: Edge case - modifying custom fields with minimum allowed values
    Given an existing invoice item with id <valid_invoiceItemId>
    And a JSON array of CustomField objects with minimum allowed field values
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields
    Then the response status code should be 204
    And the custom fields should be updated as expected

    @TC23
    Scenario: Edge case - modifying custom fields with extra/unexpected parameters in URL
    Given an existing invoice item with id <valid_invoiceItemId>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/customFields?unexpected=param
    Then the response status code should be 204 or 400 depending on API strictness
    And the custom fields should be updated if request is accepted

    @TC24
    Scenario: State variation - database is empty
    Given the database contains no invoice items
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<any_invoiceItemId>/customFields
    Then the response status code should be 404
    And the response body should contain an error message indicating invoice item not found

    @TC25
    Scenario: State variation - database is partially populated
    Given the database contains some invoice items and some missing
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When the user sends a PUT request to /1.0/kb/invoiceItems/<existing_invoiceItemId>/customFields
    Then the response status code should be 204
    And the custom fields should be updated for the existing item
    When the user sends a PUT request to /1.0/kb/invoiceItems/<missing_invoiceItemId>/customFields
    Then the response status code should be 404
    And the response body should contain an error message indicating invoice item not found