Feature: Remove custom fields from bundle via DELETE /1.0/kb/bundles/{bundleId}/customFields
As a KillBill API user,
I want to remove custom fields from a bundle,
so that I can manage and clean up bundle metadata as needed.

  Background:
  Given the KillBill API is available
  And the API endpoint DELETE /1.0/kb/bundles/{bundleId}/customFields is reachable
  And the database contains bundles with and without custom fields
  And valid and invalid authentication tokens are available
  And test bundles with multiple custom fields (with known UUIDs) exist
  And the required header X-Killbill-CreatedBy is set to a valid username

    @TC01
    Scenario: Successful removal of all custom fields from a bundle (no customField query parameter)
    Given a bundle with bundleId <valid_bundle_id> exists and has multiple custom fields
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields without any customField query parameter
    Then the API responds with HTTP 204 No Content
    And all custom fields for the bundle are removed
    And a subsequent GET request for custom fields on the bundle returns an empty list

    @TC02
    Scenario: Successful removal of a single custom field from a bundle
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields <cf1>, <cf2>
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields?customField=<cf1>
    Then the API responds with HTTP 204 No Content
    And custom field <cf1> is removed from the bundle
    And custom field <cf2> remains on the bundle
    And a subsequent GET request for custom fields on the bundle returns only <cf2>

    @TC03
    Scenario: Successful removal of multiple custom fields from a bundle
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields <cf1>, <cf2>, <cf3>
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields?customField=<cf1>&customField=<cf2>
    Then the API responds with HTTP 204 No Content
    And custom fields <cf1> and <cf2> are removed from the bundle
    And custom field <cf3> remains on the bundle
    And a subsequent GET request for custom fields on the bundle returns only <cf3>

    @TC04
    Scenario: Successful removal with optional headers X-Killbill-Reason and X-Killbill-Comment
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields
    And the request includes headers X-Killbill-CreatedBy set to "test-user", X-Killbill-Reason set to "cleanup", and X-Killbill-Comment set to "removing unused fields"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields
    Then the API responds with HTTP 204 No Content
    And all custom fields for the bundle are removed

    @TC05
    Scenario: Successful removal from a bundle that has no custom fields
    Given a bundle with bundleId <valid_bundle_id> exists and has no custom fields
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields
    Then the API responds with HTTP 204 No Content
    And a subsequent GET request for custom fields on the bundle returns an empty list

    @TC06
    Scenario: Attempt to remove custom fields with invalid bundleId format
    Given a bundleId <invalid_bundle_id> that does not match the required UUID pattern
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<invalid_bundle_id>/customFields
    Then the API responds with HTTP 400 Bad Request
    And the response body contains an error message indicating invalid bundleId format

    @TC07
    Scenario: Attempt to remove custom fields from a non-existent bundle
    Given a bundleId <nonexistent_bundle_id> that does not exist in the system
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<nonexistent_bundle_id>/customFields
    Then the API responds with HTTP 404 Not Found
    And the response body contains an error message indicating bundle not found

    @TC08
    Scenario: Attempt to remove custom fields without X-Killbill-CreatedBy header
    Given a bundle with bundleId <valid_bundle_id> exists
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields without the X-Killbill-CreatedBy header
    Then the API responds with HTTP 400 Bad Request
    And the response body contains an error message indicating missing required header

    @TC09
    Scenario: Attempt to remove custom fields with invalid customField UUID format
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields?customField=<invalid_cf_uuid>
    Then the API responds with HTTP 400 Bad Request
    And the response body contains an error message indicating invalid customField UUID format

    @TC10
    Scenario: Attempt to remove a custom field not present on the bundle
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields <cf1>, <cf2>
    And <cf3> is a valid custom field UUID not present on the bundle
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields?customField=<cf3>
    Then the API responds with HTTP 204 No Content
    And custom fields <cf1> and <cf2> remain on the bundle

    @TC11
    Scenario: Attempt to remove custom fields with extra, unsupported query parameters
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields?customField=<cf1>&foo=bar
    Then the API responds with HTTP 204 No Content
    And custom field <cf1> is removed from the bundle
    And the extra parameter is ignored

    @TC12
    Scenario: Attempt to remove custom fields while the service is unavailable
    Given the KillBill API service is temporarily unavailable
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields
    Then the API responds with HTTP 503 Service Unavailable
    And the response body contains an appropriate error message

    @TC13
    Scenario: Attempt to remove custom fields with expired or invalid authentication token
    Given a bundle with bundleId <valid_bundle_id> exists
    And the request includes an invalid or expired authentication token
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields
    Then the API responds with HTTP 401 Unauthorized
    And the response body contains an error message indicating authentication failure

    @TC14
    Scenario: Attempt to remove custom fields with injection or malicious payload in header
    Given a bundle with bundleId <valid_bundle_id> exists
    And the request includes header X-Killbill-CreatedBy set to a value containing SQL injection attempt "test-user; DROP TABLE users;"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields
    Then the API responds with HTTP 400 Bad Request or appropriate error code
    And the system does not execute any unintended commands

    @TC15
    Scenario: Performance - Remove all custom fields from a bundle with a large number of custom fields
    Given a bundle with bundleId <valid_bundle_id> exists and has 1000 custom fields
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields
    Then the API responds with HTTP 204 No Content within 2 seconds
    And all custom fields are removed

    @TC16
    Scenario: Concurrent removal requests for the same bundle
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields <cf1>, <cf2>, <cf3>
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When two clients simultaneously send DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields?customField=<cf1>
    Then both requests respond with HTTP 204 No Content
    And custom field <cf1> is removed and other custom fields remain

    @TC17
    Scenario: Regression - Previously fixed issue: Removing custom fields does not affect unrelated bundles
    Given two bundles <bundle_id1> and <bundle_id2> exist, each with their own custom fields
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<bundle_id1>/customFields?customField=<cf1>
    Then custom fields on <bundle_id2> remain unaffected
    And only <cf1> is removed from <bundle_id1>

    @TC18
    Scenario: Regression - Backward compatibility with older clients omitting optional headers
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields with only the required header X-Killbill-CreatedBy
    Then the API responds with HTTP 204 No Content
    And all custom fields are removed

    @TC19
    Scenario: Edge case - Attempt to remove custom fields with empty customField parameter
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields?customField=
    Then the API responds with HTTP 400 Bad Request
    And the response body contains an error message indicating invalid customField value

    @TC20
    Scenario: Edge case - Attempt to remove custom fields with maximum allowed length for X-Killbill-Comment
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    And the request includes header X-Killbill-Comment set to a string of maximum allowed length
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields
    Then the API responds with HTTP 204 No Content
    And all custom fields are removed

    @TC21
    Scenario: Edge case - Attempt to remove custom fields with minimum allowed length for X-Killbill-Comment
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    And the request includes header X-Killbill-Comment set to a single character
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields
    Then the API responds with HTTP 204 No Content
    And all custom fields are removed

    @TC22
    Scenario: Edge case - Attempt to remove custom fields with partial bundleId (truncated UUID)
    Given a bundleId <partial_uuid> that is a truncated UUID
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<partial_uuid>/customFields
    Then the API responds with HTTP 400 Bad Request
    And the response body contains an error message indicating invalid bundleId format

    @TC23
    Scenario: State variation - Removing custom fields when database is empty
    Given the database contains no bundles
    When the client sends DELETE /1.0/kb/bundles/<any_bundle_id>/customFields
    Then the API responds with HTTP 404 Not Found
    And the response body contains an error message indicating bundle not found

    @TC24
    Scenario: Integration - Remove custom fields when dependent service for custom field storage is degraded
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields
    And the custom field storage service is degraded (slow response)
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields
    Then the API responds with HTTP 504 Gateway Timeout or HTTP 503 Service Unavailable if timeout occurs
    And the response body contains an appropriate error message

    @TC25
    Scenario: Integration - Data consistency after removal of custom fields
    Given a bundle with bundleId <valid_bundle_id> exists and has custom fields <cf1>, <cf2>
    And the request includes header X-Killbill-CreatedBy set to "test-user"
    When the client sends DELETE /1.0/kb/bundles/<valid_bundle_id>/customFields?customField=<cf1>
    Then the API responds with HTTP 204 No Content
    And a subsequent GET request for custom fields on the bundle returns only <cf2>
    And no data inconsistency is observed in the database