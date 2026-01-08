Feature: Add tags to invoice item via POST /1.0/kb/invoiceItems/{invoiceItemId}/tags
As a KillBill API user,
I want to add one or more tags to a specific invoice item,
so that I can categorize or annotate invoice items as needed.

  Background:
  Given the KillBill API server is running and accessible
  And the database contains a variety of invoice items, some with and some without existing tags
  And valid tag definition UUIDs exist in the system
  And I have a valid authentication token (if required)
  And API endpoint POST /1.0/kb/invoiceItems/{invoiceItemId}/tags is available

    @TC01
    Scenario: Successful addition of multiple tags to an invoice item (happy path)
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And valid tag definition UUIDs ["tag-definition-uuid-1", "tag-definition-uuid-2"]
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["tag-definition-uuid-1", "tag-definition-uuid-2"]
    Then the response status code should be 201
    And the response body should be a JSON array of Tag objects with tagDefinitionIds matching the request
    And each tag should be associated with the invoice item

    @TC02
    Scenario: Successful addition of a single tag to an invoice item
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And a valid tag definition UUID ["tag-definition-uuid-3"]
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["tag-definition-uuid-3"]
    Then the response status code should be 201
    And the response body should be a JSON array containing one Tag object with tagDefinitionId "tag-definition-uuid-3"

    @TC03
    Scenario: Successful addition with optional headers
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And valid tag definition UUIDs ["tag-definition-uuid-4"]
    And header X-Killbill-CreatedBy is set to "test-user"
    And header X-Killbill-Reason is set to "unit test"
    And header X-Killbill-Comment is set to "adding tag for testing"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["tag-definition-uuid-4"]
    Then the response status code should be 201
    And the response body should be a JSON array containing one Tag object
    And the created tag should be associated with the invoice item

    @TC04
    Scenario: Successful addition when invoice item has existing tags
    Given an existing invoice item with id "valid-invoice-item-uuid" that already has tags ["tag-definition-uuid-5"]
    And valid tag definition UUIDs ["tag-definition-uuid-6"]
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["tag-definition-uuid-6"]
    Then the response status code should be 201
    And the response body should include both the old and new tags for the invoice item

    @TC05
    Scenario: Successful addition when invoice item has no existing tags
    Given an existing invoice item with id "valid-invoice-item-uuid-no-tags" and no tags
    And valid tag definition UUIDs ["tag-definition-uuid-7"]
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid-no-tags/tags with body ["tag-definition-uuid-7"]
    Then the response status code should be 201
    And the response body should contain the newly created tag

    @TC06
    Scenario: Attempt to add tags with missing required header
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And valid tag definition UUIDs ["tag-definition-uuid-8"]
    And header X-Killbill-CreatedBy is missing
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["tag-definition-uuid-8"]
    Then the response status code should be 400
    And the response body should contain an error message indicating the missing required header

    @TC07
    Scenario: Attempt to add tags with invalid invoice item id format
    Given an invoice item id "invalid-format-id"
    And valid tag definition UUIDs ["tag-definition-uuid-9"]
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/invalid-format-id/tags with body ["tag-definition-uuid-9"]
    Then the response status code should be 400
    And the response body should contain an error message about invalid invoice item id format

    @TC08
    Scenario: Attempt to add tags to non-existent invoice item
    Given a non-existent invoice item id "non-existent-invoice-item-uuid"
    And valid tag definition UUIDs ["tag-definition-uuid-10"]
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/non-existent-invoice-item-uuid/tags with body ["tag-definition-uuid-10"]
    Then the response status code should be 404
    And the response body should contain an error message indicating invoice item not found

    @TC09
    Scenario: Attempt to add tags with malformed JSON body
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with a malformed JSON body
    Then the response status code should be 400
    And the response body should contain an error message indicating malformed request body

    @TC10
    Scenario: Attempt to add tags with empty tag definition list
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body []
    Then the response status code should be 400
    And the response body should indicate that at least one tag definition id is required

    @TC11
    Scenario: Attempt to add tags with invalid tag definition UUID
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And an invalid tag definition UUID ["invalid-tag-def-uuid"]
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["invalid-tag-def-uuid"]
    Then the response status code should be 400
    And the response body should contain an error message about invalid tag definition UUID

    @TC12
    Scenario: Attempt to add tags with extra, unsupported parameters in the request body
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["tag-definition-uuid-11"] and extra fields
    Then the response status code should be 400
    And the response body should indicate unsupported parameters

    @TC13
    Scenario: Attempt to add tags with duplicate tag definition UUIDs in the request
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["tag-definition-uuid-12", "tag-definition-uuid-12"]
    Then the response status code should be 201
    And the response body should only include one Tag object for the duplicate tag definition

    @TC14
    Scenario: Attempt to add tags when system is under heavy load (performance)
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And valid tag definition UUIDs ["tag-definition-uuid-13"]
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["tag-definition-uuid-13"] under simulated heavy load
    Then the response status code should be 201
    And the response time should be within acceptable thresholds (e.g., < 2 seconds)

    @TC15
    Scenario: Attempt to add tags when database is empty (no invoice items)
    Given the database contains no invoice items
    And valid tag definition UUIDs ["tag-definition-uuid-14"]
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/any-invoice-item-uuid/tags with body ["tag-definition-uuid-14"]
    Then the response status code should be 404
    And the response body should indicate invoice item not found

    @TC16
    Scenario: Attempt to add tags with unauthorized access
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And valid tag definition UUIDs ["tag-definition-uuid-15"]
    And authentication token is missing or invalid
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["tag-definition-uuid-15"]
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC17
    Scenario: Attempt to add tags when KillBill service is unavailable
    Given the KillBill API service is down
    When I POST to /1.0/kb/invoiceItems/any-invoice-item-uuid/tags with any valid body
    Then the response status code should be 503
    And the response body should indicate service unavailable

    @TC18
    Scenario: Attempt to add tags with malicious payload (security)
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with a body containing SQL injection or script tags
    Then the response status code should be 400 or 422
    And the response body should indicate invalid input or security violation

    @TC19
    Scenario: Attempt to add tags with extremely large request body
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with a body containing a very large array of tag definition UUIDs (e.g., 10,000 entries)
    Then the response status code should be 201 or 413
    And if 201, the response body should contain all created tags
    And if 413, the response body should indicate payload too large

    @TC20
    Scenario: Regression - previously fixed bug: adding a tag that already exists on the invoice item
    Given an existing invoice item with id "valid-invoice-item-uuid" that already has tag "tag-definition-uuid-16"
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["tag-definition-uuid-16"]
    Then the response status code should be 201
    And the response body should not duplicate the existing tag

    @TC21
    Scenario: Integration - dependent tag definition service is unavailable
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body ["tag-definition-uuid-17"] while the tag definition service is down
    Then the response status code should be 503
    And the response body should indicate dependency failure

    @TC22
    Scenario: State variation - partially populated database
    Given the database contains some invoice items and some tag definitions
    And an existing invoice item with id "partial-invoice-item-uuid"
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/partial-invoice-item-uuid/tags with body ["tag-definition-uuid-18"]
    Then the response status code should be 201
    And the response body should contain the newly created tag

    @TC23
    Scenario: State variation - invoice item with maximum allowed tags
    Given an existing invoice item with id "max-tag-invoice-item-uuid" that already has the maximum allowed number of tags
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/max-tag-invoice-item-uuid/tags with body ["tag-definition-uuid-19"]
    Then the response status code should be 400
    And the response body should indicate maximum tags reached

    @TC24
    Scenario: Attempt to add tags with partial input (null or empty string in array)
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with body [null, ""]
    Then the response status code should be 400
    And the response body should indicate invalid tag definition ids

    @TC25
    Scenario: Timeout condition - long-running operation
    Given an existing invoice item with id "valid-invoice-item-uuid"
    And header X-Killbill-CreatedBy is set to "test-user"
    When I POST to /1.0/kb/invoiceItems/valid-invoice-item-uuid/tags with a valid body and the operation takes longer than timeout threshold
    Then the response status code should be 504
    And the response body should indicate a timeout error