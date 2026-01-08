Feature: Remove custom fields from an invoice item via DELETE /1.0/kb/invoiceItems/{invoiceItemId}/customFields
As a KillBill API user,
I want to remove custom fields from an invoice item,
so that I can manage invoice item metadata efficiently.

  Background:
  Given the KillBill API server is running and reachable
  And the database is seeded with invoice items having various custom fields
  And I have a valid authentication token if required
  And I have the X-Killbill-CreatedBy header set to a valid username

    @TC01
    Scenario: Successful removal of all custom fields from an invoice item (no customField query parameter)
    Given an invoice item exists with multiple custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with required headers and without any customField query parameter
    Then the response code should be 204
    And all custom fields for the invoice item should be removed
    And the response body should be empty

    @TC02
    Scenario: Successful removal of specific custom fields from an invoice item (customField query parameter present)
    Given an invoice item exists with multiple custom fields
    And the invoiceItemId is valid
    And I have a list of custom field IDs to remove (subset of all fields)
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with the customField query parameter set to those IDs and required headers
    Then the response code should be 204
    And only the specified custom fields should be removed from the invoice item
    And the response body should be empty

    @TC03
    Scenario: Remove custom fields from an invoice item with only one custom field
    Given an invoice item exists with exactly one custom field
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with required headers and without customField query parameter
    Then the response code should be 204
    And the invoice item should have no custom fields remaining
    And the response body should be empty

    @TC04
    Scenario: Remove custom fields from an invoice item with no custom fields
    Given an invoice item exists with no custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with required headers
    Then the response code should be 204
    And the response body should be empty

    @TC05
    Scenario: Remove custom fields with all optional headers provided
    Given an invoice item exists with multiple custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with X-Killbill-CreatedBy, X-Killbill-Reason, and X-Killbill-Comment headers
    Then the response code should be 204
    And the response body should be empty

    @TC06
    Scenario: Remove custom fields with only required header (X-Killbill-CreatedBy)
    Given an invoice item exists with custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with only the X-Killbill-CreatedBy header
    Then the response code should be 204
    And the response body should be empty

    @TC07
    Scenario: Remove custom fields with an invalid invoiceItemId format
    Given the invoiceItemId is not a valid UUID (e.g., 'invalid-id')
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with required headers
    Then the response code should be 400
    And the response body should contain an error message indicating invalid invoice item ID

    @TC08
    Scenario: Remove custom fields from a non-existent invoice item
    Given the invoiceItemId is a valid UUID but does not exist in the system
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with required headers
    Then the response code should be 404
    And the response body should contain an error message indicating invoice item not found

    @TC09
    Scenario: Remove custom fields with missing required header (X-Killbill-CreatedBy)
    Given an invoice item exists with custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields without the X-Killbill-CreatedBy header
    Then the response code should be 400
    And the response body should indicate the missing required header

    @TC10
    Scenario: Remove custom fields with a malformed customField query parameter
    Given an invoice item exists with custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with customField query parameter set to a non-UUID value (e.g., 'bad-field-id')
    Then the response code should be 400
    And the response body should indicate invalid custom field ID

    @TC11
    Scenario: Remove custom fields with extra/unexpected query parameters
    Given an invoice item exists with custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with an extra query parameter (e.g., foo=bar) and required headers
    Then the response code should be 204
    And the response body should be empty

    @TC12
    Scenario: Remove custom fields with a large number of customField IDs
    Given an invoice item exists with many custom fields (e.g., 100+)
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with all customField IDs as query parameters and required headers
    Then the response code should be 204
    And all specified custom fields should be removed
    And the response body should be empty

    @TC13
    Scenario: Remove custom fields while the system is under heavy load
    Given the system is processing a high volume of requests
    And an invoice item exists with custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with required headers
    Then the response code should be 204 within acceptable response time
    And the response body should be empty

    @TC14
    Scenario: Remove custom fields when dependent service is unavailable
    Given an invoice item exists with custom fields
    And the invoiceItemId is valid
    And the database or dependent service is unavailable
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with required headers
    Then the response code should be 503 or appropriate error code
    And the response body should indicate service unavailable

    @TC15
    Scenario: Remove custom fields with an injection attempt in customField parameter
    Given an invoice item exists with custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with customField query parameter set to a malicious payload (e.g., '1; DROP TABLE users;')
    Then the response code should be 400 or 422
    And the response body should indicate invalid input or security violation

    @TC16
    Scenario: Remove custom fields with a very long X-Killbill-Comment header
    Given an invoice item exists with custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with X-Killbill-Comment header set to a string at or near the maximum allowed length
    Then the response code should be 204
    And the response body should be empty

    @TC17
    Scenario: Remove custom fields with a partial customField list (some valid, some invalid IDs)
    Given an invoice item exists with custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with customField query parameter containing a mix of valid and invalid UUIDs
    Then the response code should be 400
    And the response body should indicate which IDs are invalid

    @TC18
    Scenario: Remove custom fields with repeated customField IDs in query parameter
    Given an invoice item exists with custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with duplicate customField UUIDs in the query parameter
    Then the response code should be 204
    And the specified custom fields should be removed (no error due to duplicates)
    And the response body should be empty

    @TC19
    Scenario: Remove custom fields with expired or invalid authentication token (if applicable)
    Given an invoice item exists with custom fields
    And the invoiceItemId is valid
    And the authentication token is expired or invalid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with required headers
    Then the response code should be 401
    And the response body should indicate unauthorized access

    @TC20
    Scenario: Regression - Remove custom fields after a previous bug fix for header parsing
    Given an invoice item exists with custom fields
    And the invoiceItemId is valid
    When I send a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/customFields with headers formatted as previously problematic (e.g., extra whitespace, unusual casing)
    Then the response code should be 204
    And the response body should be empty