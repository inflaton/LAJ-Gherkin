Feature: Remove custom fields from invoice payment via DELETE /1.0/kb/invoicePayments/{paymentId}/customFields
As a KillBill API user,
I want to remove custom fields from an invoice payment,
so that I can manage the metadata associated with invoice payments efficiently.

  Background:
  Given the KillBill system is running and accessible
  And the API endpoint DELETE /1.0/kb/invoicePayments/{paymentId}/customFields is available
  And the database contains invoice payments with various custom fields
  And I have a valid authentication token

    @TC01
    Scenario: Successful removal of all custom fields from a payment (no customField query parameter)
    Given an invoice payment exists with paymentId = <valid_payment_id> and has multiple custom fields
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields with no customField query parameter
    Then the response status code should be 204
    And all custom fields for the payment should be removed
    And the response body should be empty

    @TC02
    Scenario: Successful removal of specific custom fields from a payment (customField query parameter present)
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1, cf2, cf3]
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields?customField=cf1&customField=cf3
    Then the response status code should be 204
    And only custom fields cf1 and cf3 should be removed from the payment
    And custom field cf2 should remain
    And the response body should be empty

    @TC03
    Scenario: Successful removal with optional headers X-Killbill-Reason and X-Killbill-Comment
    Given an invoice payment exists with paymentId = <valid_payment_id> and has at least one custom field
    And the request includes headers X-Killbill-CreatedBy = "test-user", X-Killbill-Reason = "cleanup", X-Killbill-Comment = "removing obsolete fields"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields
    Then the response status code should be 204
    And all custom fields for the payment should be removed
    And the response body should be empty

    @TC04
    Scenario: Successful removal when payment has no custom fields
    Given an invoice payment exists with paymentId = <valid_payment_id> and has no custom fields
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields
    Then the response status code should be 204
    And the response body should be empty

    @TC05
    Scenario: Removal with extra/unexpected query parameter
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1]
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields?customField=cf1&unexpected=foo
    Then the response status code should be 204
    And custom field cf1 should be removed
    And the response body should be empty

    @TC06
    Scenario: Removal with maximum allowed customField IDs in query
    Given an invoice payment exists with paymentId = <valid_payment_id> and has 100 custom fields
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields with all 100 customField query parameters
    Then the response status code should be 204
    And all 100 custom fields should be removed
    And the response body should be empty

    @TC07
    Scenario: Removal with minimum allowed customField IDs in query (one ID)
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom field cf1
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields?customField=cf1
    Then the response status code should be 204
    And custom field cf1 should be removed
    And the response body should be empty

    @TC08
    Scenario: Removal with invalid paymentId format
    Given the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/invalid-id/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid paymentId format

    @TC09
    Scenario: Removal with non-existent paymentId
    Given the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<nonexistent_payment_id>/customFields
    Then the response status code should be 404
    And the response body should contain an error message indicating payment not found

    @TC10
    Scenario: Removal with non-existent customField IDs
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1]
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields?customField=cf999
    Then the response status code should be 204
    And no custom fields should be removed (since cf999 does not exist)
    And the response body should be empty

    @TC11
    Scenario: Removal with missing X-Killbill-CreatedBy header
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1]
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields without the X-Killbill-CreatedBy header
    Then the response status code should be 400
    And the response body should contain an error message indicating missing required header

    @TC12
    Scenario: Removal with unauthorized user (invalid authentication token)
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1]
    And I have an invalid authentication token
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields
    Then the response status code should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC13
    Scenario: Removal with malformed customField ID in query
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1]
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields?customField=not-a-uuid
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid customField ID format

    @TC14
    Scenario: Removal when KillBill service is unavailable
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1]
    And the KillBill service is unavailable
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC15
    Scenario: Removal with large payload (many customField query parameters)
    Given an invoice payment exists with paymentId = <valid_payment_id> and has 1000 custom fields
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields with all 1000 customField query parameters
    Then the response status code should be 204
    And all 1000 custom fields should be removed
    And the response body should be empty

    @TC16
    Scenario: Removal with partial input (some valid, some invalid customField IDs)
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1, cf2]
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields?customField=cf1&customField=not-a-uuid
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid customField ID format

    @TC17
    Scenario: Removal with XSS attempt in header
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1]
    And the request includes header X-Killbill-CreatedBy = "<script>alert(1)</script>"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid header value

    @TC18
    Scenario: Removal with SQL injection attempt in customField query parameter
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1]
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields?customField=1%20OR%201=1
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid customField ID format

    @TC19
    Scenario: Removal with slow/degraded system performance
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1, cf2, cf3]
    And the system is under heavy load
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields
    Then the response status code should be 204
    And the response time should be within acceptable thresholds (e.g., < 2 seconds)
    And all custom fields should be removed

    @TC20
    Scenario: Regression - Previously fixed issue with removal of all fields
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1, cf2]
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields
    Then the response status code should be 204
    And all custom fields should be removed
    And the response body should be empty

    @TC21
    Scenario: Integration - Removal with dependent service (audit log) available
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1]
    And the audit log service is available and operational
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields
    Then the response status code should be 204
    And an audit log entry should be created for the removal
    And the response body should be empty

    @TC22
    Scenario: Integration - Removal with dependent service (audit log) unavailable
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1]
    And the audit log service is unavailable
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields
    Then the response status code should be 204 or 503 depending on error handling
    And the response body should reflect the audit log service status

    @TC23
    Scenario: Backward compatibility - Removal with legacy client
    Given an invoice payment exists with paymentId = <valid_payment_id> and has custom fields [cf1]
    And the request is made using a legacy client version
    And the request includes header X-Killbill-CreatedBy = "test-user"
    When I invoke DELETE /1.0/kb/invoicePayments/<valid_payment_id>/customFields
    Then the response status code should be 204
    And custom field cf1 should be removed
    And the response body should be empty