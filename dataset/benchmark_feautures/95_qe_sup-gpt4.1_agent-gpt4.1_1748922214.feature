Feature: Add tags to an invoice payment via POST /1.0/kb/invoicePayments/{paymentId}/tags
As a KillBill API user,
I want to add tags to a specific invoice payment,
so that I can categorize or mark payments with relevant metadata.

  Background:
  Given the KillBill API is running and accessible
  And the database contains invoice payments with various states (existing, non-existing)
  And valid and invalid tag definition UUIDs are seeded in the system
  And I have a valid authentication token (if required)
  And the API endpoint POST /1.0/kb/invoicePayments/{paymentId}/tags is available

    @TC01
    Scenario: Successful addition of tags to an existing invoice payment with all required headers
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a valid JSON array of tag definition UUIDs ["tag-definition-uuid-1", "tag-definition-uuid-2"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags with the tag UUID array
    Then the response status code should be 201
    And the response body should be a JSON array of Tag objects corresponding to the input tag UUIDs
    And each Tag object should contain the paymentId, tagDefinitionId, and metadata

    @TC02
    Scenario: Successful addition of tags with optional headers X-Killbill-Reason and X-Killbill-Comment
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a valid JSON array of tag definition UUIDs ["tag-definition-uuid-1"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    And the X-Killbill-Reason header is set to "testing reason"
    And the X-Killbill-Comment header is set to "testing comment"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags with the tag UUID array
    Then the response status code should be 201
    And the response body should be a JSON array with one Tag object containing the correct metadata

    @TC03
    Scenario: Add tags with only required headers
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a valid JSON array of tag definition UUIDs ["tag-definition-uuid-1"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags with the tag UUID array
    Then the response status code should be 201
    And the response body should be a JSON array with one Tag object

    @TC04
    Scenario: Add tags with no tag definitions in the request body (empty array)
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And an empty JSON array []
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags with the empty array
    Then the response status code should be 201
    And the response body should be an empty JSON array

    @TC05
    Scenario: Add tags to a non-existent invoice payment
    Given a non-existent paymentId "nonexistent-payment-uuid"
    And a valid JSON array of tag definition UUIDs ["tag-definition-uuid-1"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/nonexistent-payment-uuid/tags with the tag UUID array
    Then the response status code should be 404
    And the response body should contain an error message indicating payment not found

    @TC06
    Scenario: Add tags with an invalid paymentId format
    Given an invalid paymentId "invalid-format"
    And a valid JSON array of tag definition UUIDs ["tag-definition-uuid-1"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/invalid-format/tags with the tag UUID array
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid paymentId

    @TC07
    Scenario: Add tags with a missing X-Killbill-CreatedBy header
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a valid JSON array of tag definition UUIDs ["tag-definition-uuid-1"]
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags without the X-Killbill-CreatedBy header
    Then the response status code should be 400
    And the response body should contain an error message indicating the missing required header

    @TC08
    Scenario: Add tags with a malformed JSON body
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a malformed JSON body "{tag: 'not-an-array'}"
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags with the malformed body
    Then the response status code should be 400
    And the response body should contain an error message indicating malformed request body

    @TC09
    Scenario: Add tags with an array containing an invalid tag definition UUID format
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a JSON array ["not-a-uuid"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags with the invalid tag UUID
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid tag definition UUID

    @TC10
    Scenario: Add tags with extra, unsupported parameters in the request body
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a JSON body {"extra": "value", "tags": ["tag-definition-uuid-1"]}
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags with the extra parameters
    Then the response status code should be 400
    And the response body should contain an error message about unexpected fields

    @TC11
    Scenario: Add tags with duplicate tag definition UUIDs in the array
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a JSON array ["tag-definition-uuid-1", "tag-definition-uuid-1"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags with duplicate tag UUIDs
    Then the response status code should be 201
    And the response body should contain only one Tag object for the unique tag definition

    @TC12
    Scenario: Add tags when the system is under heavy load (performance scenario)
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a valid JSON array of tag definition UUIDs ["tag-definition-uuid-1", "tag-definition-uuid-2", ..., "tag-definition-uuid-n"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags under peak load conditions
    Then the response status code should be 201
    And the response time should be within acceptable thresholds (e.g., < 2 seconds)

    @TC13
    Scenario: Add tags when the service is unavailable (dependency failure)
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a valid JSON array of tag definition UUIDs ["tag-definition-uuid-1"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    And the tag service is unavailable
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailability

    @TC14
    Scenario: Add tags with a very large array of tag definition UUIDs (boundary/edge case)
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a JSON array containing the maximum allowed number of tag definition UUIDs
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags with the large array
    Then the response status code should be 201
    And the response body should be a JSON array of Tag objects matching the input size

    @TC15
    Scenario: Add tags with an unauthorized user (security scenario)
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a valid JSON array of tag definition UUIDs ["tag-definition-uuid-1"]
    And the X-Killbill-CreatedBy header is set to "unauthorized-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags
    Then the response status code should be 401 or 403
    And the response body should contain an error message indicating unauthorized access

    @TC16
    Scenario: Add tags with malicious payload (security scenario)
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a JSON body containing a script injection attempt ["<script>alert('xss')</script>"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid input or security violation

    @TC17
    Scenario: Add tags with partial input (missing array elements, nulls)
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a JSON array [null, "tag-definition-uuid-1"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags with partial/invalid elements
    Then the response status code should be 400
    And the response body should indicate the invalid input

    @TC18
    Scenario: Add tags when the database is empty (no invoice payments)
    Given the database contains no invoice payments
    And a valid JSON array of tag definition UUIDs ["tag-definition-uuid-1"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/any-payment-uuid/tags
    Then the response status code should be 404
    And the response body should indicate payment not found

    @TC19
    Scenario: Add tags to a payment that already has the same tags (idempotency/regression)
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And the payment already has the tag "tag-definition-uuid-1"
    And a JSON array ["tag-definition-uuid-1"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When I POST to /1.0/kb/invoicePayments/valid-payment-uuid/tags with the same tag UUID
    Then the response status code should be 201
    And the response body should not duplicate the tag

    @TC20
    Scenario: Add tags with concurrent requests (concurrency/performance)
    Given an existing invoice payment with paymentId "valid-payment-uuid"
    And a valid JSON array of tag definition UUIDs ["tag-definition-uuid-1", "tag-definition-uuid-2"]
    And the X-Killbill-CreatedBy header is set to "test-user"
    When multiple POST requests are made concurrently to /1.0/kb/invoicePayments/valid-payment-uuid/tags
    Then all responses should be 201 or appropriate error codes in case of race conditions
    And the resulting tags on the payment should be consistent and without duplicates