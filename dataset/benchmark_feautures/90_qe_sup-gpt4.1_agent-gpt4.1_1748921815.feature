Feature: Add custom fields to an invoice item via POST /1.0/kb/invoiceItems/{invoiceItemId}/customFields
As a KillBill API user,
I want to add custom fields to a specific invoice item,
so that I can store additional metadata on invoice items.

  Background:
  Given the KillBill API is available
  And the database is seeded with at least one invoice item with a valid UUID
  And the API client is authenticated with valid credentials
  And the X-Killbill-CreatedBy header is set to a valid username
  And the endpoint is POST /1.0/kb/invoiceItems/{invoiceItemId}/customFields

    @TC01
    Scenario: Successful creation of custom fields with all required and optional headers
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    And the X-Killbill-Reason header is set to "testing reason"
    And the X-Killbill-Comment header is set to "testing comment"
    When the client sends a POST request to the endpoint
    Then the response status code should be 201
    And the response body should be a JSON array containing the created CustomField objects
    And each CustomField object in the response should match the input data

    @TC02
    Scenario: Successful creation with only required header
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 201
    And the response body should be a JSON array containing the created CustomField objects

    @TC03
    Scenario: Successful creation with a single CustomField object in the array
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a JSON array with one valid CustomField object
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 201
    And the response body should be a JSON array with one CustomField object

    @TC04
    Scenario: Successful creation with multiple CustomField objects in the array
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a JSON array with multiple valid CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 201
    And the response body should be a JSON array with the same number of CustomField objects as in the request

    @TC05
    Scenario: Attempt to add custom fields with a non-existent invoice item ID
    Given no invoice item exists with id "<non_existent_invoice_item_id>"
    And the request body is a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 404
    And the response body should contain an error message indicating invoice item not found

    @TC06
    Scenario: Attempt to add custom fields with an invalid invoice item ID format
    Given an invoice item id is "invalid-uuid-format"
    And the request body is a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid invoice item id

    @TC07
    Scenario: Attempt to add custom fields with a missing X-Killbill-CreatedBy header
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is missing
    When the client sends a POST request to the endpoint
    Then the response status code should be 400
    And the response body should contain an error message indicating missing required header

    @TC08
    Scenario: Attempt to add custom fields with a malformed request body
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is not a valid JSON array (e.g., string or malformed JSON)
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 400
    And the response body should contain an error message indicating malformed request body

    @TC09
    Scenario: Attempt to add custom fields with missing request body
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is missing
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 400
    And the response body should contain an error message indicating missing request body

    @TC10
    Scenario: Attempt to add custom fields with an empty array as request body
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is an empty JSON array
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 201
    And the response body should be an empty JSON array

    @TC11
    Scenario: Attempt to add custom fields with extra/unknown parameters in the request body
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a JSON array of CustomField objects with extra fields
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 201 or 400 depending on API behavior
    And the response body should indicate how extra fields are handled (ignored or error)

    @TC12
    Scenario: Attempt to add custom fields with unauthorized access
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a valid JSON array of CustomField objects
    And the API client is not authenticated or uses invalid credentials
    When the client sends a POST request to the endpoint
    Then the response status code should be 401 or 403
    And the response body should contain an error message indicating unauthorized access

    @TC13
    Scenario: System error during custom field creation
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a valid JSON array of CustomField objects
    And the KillBill service is temporarily unavailable
    When the client sends a POST request to the endpoint
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC14
    Scenario: Large payload (maximum allowed number of CustomField objects)
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a JSON array with the maximum allowed number of CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 201 or 413 depending on API limits
    And the response body should reflect the outcome

    @TC15
    Scenario: Response time within acceptable threshold for normal payload
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response should be received within 2 seconds
    And the response status code should be 201

    @TC16
    Scenario: Concurrent requests to add custom fields to the same invoice item
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And multiple clients prepare valid requests to add custom fields
    When the clients send POST requests concurrently to the endpoint
    Then all responses should be 201 or appropriate error codes if conflicts occur
    And the invoice item should reflect all successfully created custom fields

    @TC17
    Scenario: Regression - previously fixed bug with duplicate custom field names
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body contains CustomField objects with duplicate field names
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response should match the current expected behavior (reject, deduplicate, or allow duplicates)

    @TC18
    Scenario: Integration - verify custom fields are persisted and retrievable
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 201
    And when a GET request is made to retrieve custom fields for the invoice item
    Then the created custom fields should be present in the response

    @TC19
    Scenario: Edge case - custom field values with maximum and minimum allowed lengths
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body contains CustomField objects with field values at maximum and minimum allowed lengths
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 201 or 400 depending on validation
    And the response body should reflect the outcome

    @TC20
    Scenario: Edge case - custom field names and values with special characters
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body contains CustomField objects with special characters in field names and values
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 201 or 400 depending on validation
    And the response body should reflect the outcome

    @TC21
    Scenario: Edge case - custom field injection/XSS attempt
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body contains CustomField objects with script tags or SQL injection patterns in field names or values
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 400 or 201 depending on sanitization
    And the response body should reflect the outcome and no injection is executed

    @TC22
    Scenario: System state - empty database (no invoice items)
    Given the invoice items database is empty
    And the request body is a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint with any invoiceItemId
    Then the response status code should be 404
    And the response body should indicate invoice item not found

    @TC23
    Scenario: State variation - partially populated database
    Given the database contains some invoice items but not the target invoiceItemId
    And the request body is a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint with a non-existent invoiceItemId
    Then the response status code should be 404
    And the response body should indicate invoice item not found

    @TC24
    Scenario: State variation - degraded system performance
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the KillBill system is under heavy load
    And the request body is a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    When the client sends a POST request to the endpoint
    Then the response status code should be 201
    And the response time should be within the degraded threshold (e.g., 5 seconds)

    @TC25
    Scenario: Recovery from transient network failure
    Given an invoice item exists with id "<valid_invoice_item_id>"
    And the request body is a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is set to "api-user"
    And the network connection is temporarily interrupted during the request
    When the client retries the POST request to the endpoint
    Then the response status code should be 201
    And the custom fields should be created without duplication