Feature: Remove tags from invoice item via DELETE /1.0/kb/invoiceItems/{invoiceItemId}/tags
As a KillBill API user,
I want to remove tags from an invoice item,
so that I can manage invoice item metadata efficiently.

  Background:
  Given the KillBill system is up and running
  And the API endpoint DELETE /1.0/kb/invoiceItems/{invoiceItemId}/tags is available
  And the database contains invoice items with and without tags
  And valid and invalid invoiceItemId values are known
  And valid and invalid tag definition IDs are known
  And an authentication token is present and valid

    @TC01
    Scenario: Successful removal of all tags from an invoice item (no tagDef param)
    Given an invoice item exists with multiple tags
    And the X-Killbill-CreatedBy header is set to a valid username
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags without the tagDef query parameter
    Then the response status code should be 204
    And all tags should be removed from the invoice item
    And the response body should be empty

    @TC02
    Scenario: Successful removal of specific tags from an invoice item (tagDef param present)
    Given an invoice item exists with multiple tags
    And the X-Killbill-CreatedBy header is set to a valid username
    And tagDef query parameter contains a subset of the invoice item's tag IDs
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags with the tagDef query parameter
    Then the response status code should be 204
    And only the specified tags should be removed from the invoice item
    And the response body should be empty

    @TC03
    Scenario: Successful removal with optional headers X-Killbill-Reason and X-Killbill-Comment
    Given an invoice item exists with tags
    And the X-Killbill-CreatedBy header is set to a valid username
    And the X-Killbill-Reason header is set
    And the X-Killbill-Comment header is set
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 204
    And the tags should be removed as per the request
    And the response body should be empty

    @TC04
    Scenario: Removal when invoice item has no tags
    Given an invoice item exists without any tags
    And the X-Killbill-CreatedBy header is set to a valid username
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 204
    And the response body should be empty
    And the invoice item should still have no tags

    @TC05
    Scenario: Removal with tagDef containing tag IDs not present on the invoice item
    Given an invoice item exists with some tags
    And the X-Killbill-CreatedBy header is set to a valid username
    And tagDef query parameter contains tag IDs not present on the invoice item
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags with the tagDef query parameter
    Then the response status code should be 204
    And only tags present on the invoice item are affected
    And the response body should be empty

    @TC06
    Scenario: Removal with empty tagDef parameter
    Given an invoice item exists with tags
    And the X-Killbill-CreatedBy header is set to a valid username
    And tagDef query parameter is present but empty
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags with tagDef as empty
    Then the response status code should be 204
    And no tags should be removed
    And the response body should be empty

    @TC07
    Scenario: Removal with extra/unexpected query parameters
    Given an invoice item exists with tags
    And the X-Killbill-CreatedBy header is set to a valid username
    And extra query parameters are included in the request
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags with extra parameters
    Then the response status code should be 204
    And the response body should be empty
    And only the specified tags are removed (if tagDef is present)

    @TC08
    Scenario: Attempt to remove tags from a non-existent invoice item
    Given an invoice item ID that does not exist
    And the X-Killbill-CreatedBy header is set to a valid username
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 404
    And the response body should contain an error message indicating invoice item not found

    @TC09
    Scenario: Attempt to remove tags with invalid invoiceItemId format
    Given an invoice item ID with an invalid format (not a UUID)
    And the X-Killbill-CreatedBy header is set to a valid username
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid invoice item ID

    @TC10
    Scenario: Attempt to remove tags with missing X-Killbill-CreatedBy header
    Given an invoice item exists with tags
    And the X-Killbill-CreatedBy header is missing
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating missing required header

    @TC11
    Scenario: Attempt to remove tags with invalid authentication token
    Given an invoice item exists with tags
    And the authentication token is invalid or expired
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC12
    Scenario: Attempt to remove tags when KillBill service is unavailable
    Given the KillBill service is down or unreachable
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC13
    Scenario: Attempt to remove tags with malformed tagDef values
    Given an invoice item exists with tags
    And the X-Killbill-CreatedBy header is set to a valid username
    And tagDef query parameter contains malformed UUIDs
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags with malformed tagDef
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid tagDef format

    @TC14
    Scenario: Attempt to remove tags with very large number of tagDef values
    Given an invoice item exists with tags
    And the X-Killbill-CreatedBy header is set to a valid username
    And tagDef query parameter contains a very large number of UUIDs
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 204 or 413 depending on system limits
    And the response body should be empty or contain an error message if limit exceeded

    @TC15
    Scenario: Attempt to remove tags with XSS or injection attempts in headers
    Given an invoice item exists with tags
    And the X-Killbill-CreatedBy header or X-Killbill-Reason or X-Killbill-Comment contains malicious payload
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid input

    @TC16
    Scenario: Attempt to remove tags with partial input (missing tagDef array elements)
    Given an invoice item exists with tags
    And the X-Killbill-CreatedBy header is set to a valid username
    And tagDef query parameter is partially specified (e.g., some elements missing or empty)
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid tagDef format

    @TC17
    Scenario: Performance test - high concurrency
    Given multiple concurrent DELETE requests to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    And the X-Killbill-CreatedBy header is set to a valid username
    When the requests are sent simultaneously
    Then the system should process all requests within acceptable response time thresholds
    And no data corruption or race conditions should occur

    @TC18
    Scenario: Regression - previously fixed issue: removing tags from invoice item with special characters in comment
    Given an invoice item exists with tags
    And the X-Killbill-CreatedBy header is set to a valid username
    And the X-Killbill-Comment header contains special characters
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 204
    And the tags should be removed as expected

    @TC19
    Scenario: Integration - dependent service (e.g., audit logging) unavailable
    Given an invoice item exists with tags
    And the audit logging service is unavailable
    And the X-Killbill-CreatedBy header is set to a valid username
    When the user sends a DELETE request to /1.0/kb/invoiceItems/{invoiceItemId}/tags
    Then the response status code should be 204 or 207 depending on integration design
    And the response body should indicate any partial failures if applicable

    @TC20
    Scenario: Accessibility - API documentation and error messages are accessible
    Given a user with accessibility needs reviews the API documentation and error messages
    When the user interacts with the API and receives error responses
    Then the error messages should be clear, descriptive, and compatible with screen readers
    And the API documentation should meet accessibility standards