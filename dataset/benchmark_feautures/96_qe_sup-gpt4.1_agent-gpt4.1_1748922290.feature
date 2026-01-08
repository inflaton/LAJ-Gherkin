Feature: Remove tags from invoice payment via DELETE /1.0/kb/invoicePayments/{paymentId}/tags
As an API user,
I want to remove one or more tags from a specific invoice payment,
so that I can manage tag associations for invoice payments as needed.

  Background:
  Given the KillBill API is running and accessible
  And the database is seeded with invoice payments having various tags
  And valid and invalid payment IDs are available for testing
  And valid and invalid tag definition IDs are available for testing
  And a valid X-Killbill-CreatedBy header value is available

    @TC01
    Scenario: Successful removal of all tags from a payment (no tagDef param)
    Given an invoice payment exists with one or more tags
    And a valid paymentId is provided
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags without tagDef query parameter
    Then the response status code should be 204
    And all tags should be removed from the invoice payment
    And the response body should be empty

    @TC02
    Scenario: Successful removal of specific tags from a payment (single tagDef)
    Given an invoice payment exists with multiple tags
    And a valid paymentId is provided
    And a valid tagDef query parameter is set to a single valid tag definition ID present on the payment
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags with tagDef query parameter
    Then the response status code should be 204
    And only the specified tag should be removed from the invoice payment
    And the response body should be empty

    @TC03
    Scenario: Successful removal of multiple specific tags from a payment (multiple tagDef)
    Given an invoice payment exists with several tags
    And a valid paymentId is provided
    And the tagDef query parameter is set to multiple valid tag definition IDs present on the payment
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags with multiple tagDef query parameters
    Then the response status code should be 204
    And only the specified tags should be removed from the invoice payment
    And the response body should be empty

    @TC04
    Scenario: Successful removal with optional headers (Reason and Comment)
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    And the X-Killbill-CreatedBy, X-Killbill-Reason, and X-Killbill-Comment headers are set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the response status code should be 204
    And the tags should be removed from the invoice payment
    And the response body should be empty

    @TC05
    Scenario: Removal from a payment with no tags
    Given an invoice payment exists with no tags
    And a valid paymentId is provided
    And the X-Killbill-CreatedBy header is set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the response status code should be 204
    And the response body should be empty
    And the system remains unchanged

    @TC06
    Scenario: Invalid paymentId format
    Given a paymentId is provided in an invalid format (not a UUID)
    And the X-Killbill-CreatedBy header is set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid paymentId

    @TC07
    Scenario: Non-existent paymentId
    Given a paymentId is provided that does not exist in the system
    And the X-Killbill-CreatedBy header is set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the response status code should be 404
    And the response body should contain an error message indicating payment not found

    @TC08
    Scenario: Missing required X-Killbill-CreatedBy header
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags without the X-Killbill-CreatedBy header
    Then the response status code should be 400
    And the response body should contain an error message indicating missing required header

    @TC09
    Scenario: Invalid tagDef value (not a UUID)
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    And the tagDef query parameter is set to an invalid value (not a UUID)
    And the X-Killbill-CreatedBy header is set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid tagDef value

    @TC10
    Scenario: tagDef value not present on payment
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    And the tagDef query parameter is set to a valid tag definition ID not present on the payment
    And the X-Killbill-CreatedBy header is set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the response status code should be 204
    And the response body should be empty
    And the system remains unchanged

    @TC11
    Scenario: Unauthorized access (missing or invalid authentication token)
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    And the X-Killbill-CreatedBy header is set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags without valid authentication
    Then the response status code should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC12
    Scenario: System error (service unavailable)
    Given the KillBill API service is unavailable
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailability

    @TC13
    Scenario: Injection attack attempt in tagDef parameter
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    And the tagDef query parameter is set to a string containing SQL injection code
    And the X-Killbill-CreatedBy header is set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid input

    @TC14
    Scenario: Extra unexpected query parameter
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    And the X-Killbill-CreatedBy header is set
    And an extra query parameter is included in the request
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the response status code should be 204
    And the response body should be empty

    @TC15
    Scenario: Large number of tagDef parameters
    Given an invoice payment exists with many tags
    And a valid paymentId is provided
    And the tagDef query parameter is set to a large number of valid tag definition IDs
    And the X-Killbill-CreatedBy header is set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the response status code should be 204
    And all specified tags should be removed from the invoice payment
    And the response body should be empty

    @TC16
    Scenario: Concurrent tag removal requests
    Given an invoice payment exists with multiple tags
    And a valid paymentId is provided
    And the X-Killbill-CreatedBy header is set
    When multiple users send concurrent DELETE requests to /1.0/kb/invoicePayments/{paymentId}/tags for the same tags
    Then the system should handle concurrency gracefully
    And no error should occur due to race conditions
    And the final state should reflect the correct removal of tags

    @TC17
    Scenario: Performance under load
    Given multiple invoice payments exist with tags
    And valid paymentIds are provided
    And the X-Killbill-CreatedBy header is set
    When the user sends a high volume of DELETE requests to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the average response time should remain within acceptable thresholds (e.g., < 500ms)
    And the system should not return 5xx errors due to load

    @TC18
    Scenario: Regression - previously fixed issue with tag removal
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    And the X-Killbill-CreatedBy header is set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the tags should be removed as expected
    And no regression issues should occur

    @TC19
    Scenario: Backward compatibility with previous API clients
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    And the X-Killbill-CreatedBy header is set
    When a client using an older version of the API sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the response status code should be 204
    And the tags should be removed as expected

    @TC20
    Scenario: Integration with audit logging
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    And the X-Killbill-CreatedBy header is set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the tag removal action should be recorded in the audit logs with correct user, reason, and comment if provided

    @TC21
    Scenario: Data consistency after tag removal
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    And the X-Killbill-CreatedBy header is set
    When the user sends a DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags
    Then the tags should be removed from the payment
    And subsequent GET requests for the payment's tags should return the updated list

    @TC22
    Scenario: Timeout during tag removal
    Given an invoice payment exists with tags
    And a valid paymentId is provided
    And the X-Killbill-CreatedBy header is set
    When the DELETE request to /1.0/kb/invoicePayments/{paymentId}/tags takes longer than expected
    Then the system should return a 504 Gateway Timeout error
    And the response body should contain an appropriate timeout message