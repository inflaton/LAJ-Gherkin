Feature: Retrieve custom fields for an invoice item via GET /1.0/kb/invoiceItems/{invoiceItemId}/customFields
As a KillBill API user,
I want to retrieve custom fields for a specific invoice item,
so that I can view metadata associated with that invoice item.

  Background:
  Given the KillBill API is running and accessible
  And the database contains invoice items with and without custom fields
  And I have a valid authentication token
  And the API endpoint /1.0/kb/invoiceItems/{invoiceItemId}/customFields is available

    @TC01
    Scenario: Successful retrieval of custom fields with valid invoiceItemId and default audit parameter
    Given an invoice item exists with id <valid_invoice_item_id> and has custom fields
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields with no audit parameter
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects associated with <valid_invoice_item_id>
    And the audit information should be at the default NONE level

    @TC02
    Scenario: Successful retrieval with audit=FULL
    Given an invoice item exists with id <valid_invoice_item_id> and has custom fields
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields?audit=FULL
    Then the response status code should be 200
    And the response body should include audit information at FULL level for each CustomField

    @TC03
    Scenario: Successful retrieval with audit=MINIMAL
    Given an invoice item exists with id <valid_invoice_item_id> and has custom fields
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields?audit=MINIMAL
    Then the response status code should be 200
    And the response body should include audit information at MINIMAL level for each CustomField

    @TC04
    Scenario: Successful retrieval for invoice item with no custom fields
    Given an invoice item exists with id <valid_invoice_item_id_no_fields> and has no custom fields
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id_no_fields>/customFields
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC05
    Scenario: Successful retrieval with all combinations of audit parameter values
    Given an invoice item exists with id <valid_invoice_item_id> and has custom fields
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields with audit parameter set to <audit_value>
    Then the response status code should be 200
    And the response body should reflect the audit level <audit_value>
    Examples:
      | audit_value |
      | FULL        |
      | MINIMAL     |
      | NONE        |

    @TC06
    Scenario: Error when invoiceItemId is invalid format
    Given I use an invoice item id <invalid_format_invoice_item_id> that does not match the uuid pattern
    When I send a GET request to /1.0/kb/invoiceItems/<invalid_format_invoice_item_id>/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid invoice item id format

    @TC07
    Scenario: Error when invoice item does not exist
    Given I use a validly formatted but non-existent invoice item id <nonexistent_invoice_item_id>
    When I send a GET request to /1.0/kb/invoiceItems/<nonexistent_invoice_item_id>/customFields
    Then the response status code should be 404
    And the response body should contain an error message indicating invoice item not found

    @TC08
    Scenario: Unauthorized access attempt
    Given I do not provide a valid authentication token
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields
    Then the response status code should be 401
    And the response body should indicate authentication is required

    @TC09
    Scenario: System error or dependency failure
    Given the KillBill service or database is unavailable
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields
    Then the response status code should be 503
    And the response body should indicate service unavailability

    @TC10
    Scenario: Injection attack attempt in invoiceItemId
    Given I use a malicious invoice item id <malicious_invoice_item_id> containing SQL injection characters
    When I send a GET request to /1.0/kb/invoiceItems/<malicious_invoice_item_id>/customFields
    Then the response status code should be 400
    And the response body should indicate invalid invoice item id

    @TC11
    Scenario: Extra unsupported query parameters
    Given an invoice item exists with id <valid_invoice_item_id>
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields?extra=param
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects
    And the extra parameter should be ignored

    @TC12
    Scenario: Large volume of custom fields
    Given an invoice item exists with id <valid_invoice_item_id_large> and has a large number of custom fields
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id_large>/customFields
    Then the response status code should be 200
    And the response body should contain all custom fields associated with <valid_invoice_item_id_large>
    And the response time should be within acceptable limits

    @TC13
    Scenario: Regression - previously fixed bug for missing audit parameter
    Given an invoice item exists with id <valid_invoice_item_id> and has custom fields
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields without audit parameter
    Then the response status code should be 200
    And the response body should not contain audit information unless audit is explicitly set

    @TC14
    Scenario: Backward compatibility - client using older version of API
    Given an invoice item exists with id <valid_invoice_item_id> and has custom fields
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields using an older Accept header
    Then the response status code should be 200
    And the response body should be compatible with previous API version output

    @TC15
    Scenario: Performance under concurrent requests
    Given multiple concurrent GET requests to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields
    When the requests are executed in parallel
    Then all responses should have status code 200
    And response times should remain within acceptable thresholds

    @TC16
    Scenario: Timeout or long-running operation
    Given the backend is under heavy load
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields
    Then the response status code should be 504 if a timeout occurs
    And the response body should indicate a timeout error

    @TC17
    Scenario: Empty database state
    Given the invoice items database is empty
    When I send a GET request to /1.0/kb/invoiceItems/<any_invoice_item_id>/customFields
    Then the response status code should be 404
    And the response body should indicate invoice item not found

    @TC18
    Scenario: Partial input - missing invoiceItemId
    Given I do not provide an invoice item id in the path
    When I send a GET request to /1.0/kb/invoiceItems//customFields
    Then the response status code should be 404 or 400
    And the response body should indicate missing or invalid invoice item id

    @TC19
    Scenario: Unexpected input format in audit parameter
    Given an invoice item exists with id <valid_invoice_item_id>
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields?audit=INVALID
    Then the response status code should be 400
    And the response body should indicate invalid audit parameter value

    @TC20
    Scenario: Integration with dependent services
    Given the custom fields service depends on an external audit service
    When the audit service is unavailable
    And I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields?audit=FULL
    Then the response status code should be 503
    And the response body should indicate dependency failure

    @TC21
    Scenario: Security - XSS attempt in invoiceItemId
    Given I use an invoice item id <xss_invoice_item_id> containing XSS payload
    When I send a GET request to /1.0/kb/invoiceItems/<xss_invoice_item_id>/customFields
    Then the response status code should be 400
    And the response body should indicate invalid invoice item id

    @TC22
    Scenario: Accessibility - response structure is machine readable
    Given an invoice item exists with id <valid_invoice_item_id>
    When I send a GET request to /1.0/kb/invoiceItems/<valid_invoice_item_id>/customFields
    Then the response body should be valid JSON
    And all field names should be descriptive and accessible for screen readers