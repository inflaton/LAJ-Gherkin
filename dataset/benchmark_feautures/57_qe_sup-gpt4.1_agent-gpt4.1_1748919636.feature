Feature: Modify custom fields for a bundle via PUT /1.0/kb/bundles/{bundleId}/customFields
As a KillBill API user,
I want to modify custom fields for a specific bundle,
so that I can update bundle metadata as needed.

  Background:
  Given the KillBill API is available
  And the API endpoint PUT /1.0/kb/bundles/{bundleId}/customFields is accessible
  And a valid authentication token is provided
  And the database contains bundles with and without existing custom fields
  And the system is seeded with bundles having various states (active, inactive, empty, with/without custom fields)

    @TC01
    Scenario: Successful modification of custom fields with all required headers and valid body
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid JSON array of CustomField objects
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204
    And the bundle's custom fields should be updated accordingly

    @TC02
    Scenario: Successful modification with optional headers (X-Killbill-Reason, X-Killbill-Comment)
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request header X-Killbill-Reason is set to "test-reason"
    And the request header X-Killbill-Comment is set to "test-comment"
    And the request body contains a valid JSON array of CustomField objects
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204
    And the bundle's custom fields should be updated accordingly

    @TC03
    Scenario: Successful modification with empty custom fields array (removing all custom fields)
    Given a bundle with id <valid_bundleId> exists with existing custom fields
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body is an empty JSON array
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204
    And the bundle should have no custom fields

    @TC04
    Scenario: Attempt to modify custom fields with invalid bundleId format
    Given the bundleId is set to "invalid-bundle-id"
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid JSON array of CustomField objects
    When the user sends a PUT request to /1.0/kb/bundles/invalid-bundle-id/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid bundleId

    @TC05
    Scenario: Attempt to modify custom fields for a non-existent bundle
    Given the bundleId is set to <nonexistent_bundleId>
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid JSON array of CustomField objects
    When the user sends a PUT request to /1.0/kb/bundles/<nonexistent_bundleId>/customFields
    Then the response status code should be 404
    And the response body should contain an error message indicating bundle not found

    @TC06
    Scenario: Attempt to modify custom fields with missing required header X-Killbill-CreatedBy
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is missing
    And the request body contains a valid JSON array of CustomField objects
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 400
    And the response body should indicate missing required header

    @TC07
    Scenario: Attempt to modify custom fields with malformed JSON body
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body is malformed JSON
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 400
    And the response body should indicate malformed request body

    @TC08
    Scenario: Attempt to modify custom fields with a missing request body
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body is missing
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 400
    And the response body should indicate missing request body

    @TC09
    Scenario: Attempt to modify custom fields with extra, unsupported parameters in the request body
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a JSON array of CustomField objects with extra fields
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 400
    And the response body should indicate unsupported fields in request body

    @TC10
    Scenario: Unauthorized access attempt
    Given a bundle with id <valid_bundleId> exists
    And the request is sent without a valid authentication token
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC11
    Scenario: System error (dependency/service unavailable)
    Given a bundle with id <valid_bundleId> exists
    And the dependent service is unavailable
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 503
    And the response body should indicate service unavailable

    @TC12
    Scenario: Security - SQL injection attempt in custom field value
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a CustomField object with value "'; DROP TABLE bundles;--"
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 400
    And the response body should indicate invalid input detected

    @TC13
    Scenario: Edge case - maximum allowed custom fields
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a JSON array with the maximum allowed number of CustomField objects
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204
    And the bundle's custom fields should be updated accordingly

    @TC14
    Scenario: Edge case - custom field with maximum allowed value length
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a CustomField object with value at maximum allowed length
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204
    And the bundle's custom fields should be updated accordingly

    @TC15
    Scenario: Edge case - custom field with empty value
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a CustomField object with an empty value
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204
    And the bundle's custom fields should be updated accordingly

    @TC16
    Scenario: Edge case - extra, unexpected parameters in the URL
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid JSON array of CustomField objects
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields?unexpected=param
    Then the response status code should be 204
    And the bundle's custom fields should be updated accordingly

    @TC17
    Scenario: Performance - modify custom fields under normal load
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid JSON array of CustomField objects
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields under normal load
    Then the response status code should be 204
    And the response time should be less than 2 seconds

    @TC18
    Scenario: Performance - modify custom fields under peak load
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid JSON array of CustomField objects
    When the user sends 100 concurrent PUT requests to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then all responses should have status code 204
    And the average response time should be within acceptable thresholds

    @TC19
    Scenario: Regression - previously fixed issue: custom fields with special characters
    Given a bundle with id <valid_bundleId> exists
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a CustomField object with special characters in the value
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204
    And the bundle's custom fields should be updated accordingly

    @TC20
    Scenario: Integration - dependent service returns inconsistent data
    Given a bundle with id <valid_bundleId> exists
    And the dependent service returns inconsistent data
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 500
    And the response body should indicate internal server error

    @TC21
    Scenario: Recovery from transient network failure
    Given a bundle with id <valid_bundleId> exists
    And a transient network failure occurs during the request
    When the user retries the PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204 on retry
    And the bundle's custom fields should be updated accordingly

    @TC22
    Scenario: State variation - bundle with no existing custom fields
    Given a bundle with id <valid_bundleId> exists and has no custom fields
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid JSON array of CustomField objects
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204
    And the bundle's custom fields should be created

    @TC23
    Scenario: State variation - bundle with existing custom fields (update scenario)
    Given a bundle with id <valid_bundleId> exists and has existing custom fields
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid JSON array of CustomField objects with updated values
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204
    And the bundle's custom fields should be updated accordingly

    @TC24
    Scenario: State variation - bundle with partially matching custom fields (partial update)
    Given a bundle with id <valid_bundleId> exists and has some matching and some non-matching custom fields
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid JSON array of CustomField objects with partial updates
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204
    And the bundle's custom fields should reflect the partial update

    @TC25
    Scenario: Regression - backward compatibility with existing clients
    Given a bundle with id <valid_bundleId> exists
    And the request is sent from an older client version
    And the request header X-Killbill-CreatedBy is set to "test-user"
    And the request body contains a valid JSON array of CustomField objects
    When the user sends a PUT request to /1.0/kb/bundles/<valid_bundleId>/customFields
    Then the response status code should be 204
    And the bundle's custom fields should be updated accordingly