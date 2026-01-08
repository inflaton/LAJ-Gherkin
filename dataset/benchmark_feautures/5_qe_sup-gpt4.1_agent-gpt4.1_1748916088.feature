Feature: Add custom fields to account via POST /1.0/kb/accounts/{accountId}/customFields
As a KillBill API user,
I want to add custom fields to an account,
so that I can store additional metadata for accounts.

  Background:
  Given the KillBill API is running and accessible
  And the database contains accounts with diverse data (including at least one with no custom fields)
  And I have a valid authentication token (if required)
  And the CustomField definition is known and valid
  And the API endpoint /1.0/kb/accounts/{accountId}/customFields is available

    @TC01
    Scenario: Successful creation of custom fields with all required headers and valid body
    Given an existing account with id <valid_account_uuid>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 201
    And the response body should be a JSON array of CustomField objects matching the request
    And the created custom fields should be associated with the specified account

    @TC02
    Scenario: Successful creation with optional headers (X-Killbill-Reason, X-Killbill-Comment)
    Given an existing account with id <valid_account_uuid>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set to "test_user"
    And the X-Killbill-Reason header is set to "test_reason"
    And the X-Killbill-Comment header is set to "test_comment"
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 201
    And the response body should be a JSON array of CustomField objects matching the request

    @TC03
    Scenario: Successful creation with only required header
    Given an existing account with id <valid_account_uuid>
    And a valid JSON array of CustomField objects in the request body
    And only the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 201
    And the response body should be a JSON array of CustomField objects matching the request

    @TC04
    Scenario: Successful creation when account has no existing custom fields
    Given an existing account with id <valid_account_uuid_no_custom_fields>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid_no_custom_fields>/customFields
    Then the response code should be 201
    And the response body should be a JSON array of CustomField objects matching the request

    @TC05
    Scenario: Successful creation when account already has existing custom fields
    Given an existing account with id <valid_account_uuid_with_existing_custom_fields>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid_with_existing_custom_fields>/customFields
    Then the response code should be 201
    And the response body should include both the newly created and previously existing custom fields

    @TC06
    Scenario: Attempt to create custom fields with invalid accountId format
    Given an invalid account id "1234-invalid-uuid"
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/1234-invalid-uuid/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating invalid account id

    @TC07
    Scenario: Attempt to create custom fields with missing X-Killbill-CreatedBy header
    Given an existing account with id <valid_account_uuid>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is missing
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating missing required header

    @TC08
    Scenario: Attempt to create custom fields with malformed JSON body
    Given an existing account with id <valid_account_uuid>
    And a malformed JSON body
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating malformed request body

    @TC09
    Scenario: Attempt to create custom fields with empty request body
    Given an existing account with id <valid_account_uuid>
    And an empty request body
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating missing request body

    @TC10
    Scenario: Attempt to create custom fields for non-existent account
    Given a non-existent account id <non_existent_account_uuid>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<non_existent_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating account not found

    @TC11
    Scenario: Attempt to create custom fields with unsupported fields in CustomField object
    Given an existing account with id <valid_account_uuid>
    And a JSON array of CustomField objects containing unsupported fields
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating unsupported fields

    @TC12
    Scenario: Attempt to create custom fields with duplicate field names
    Given an existing account with id <valid_account_uuid>
    And a JSON array of CustomField objects with duplicate field names
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating duplicate fields

    @TC13
    Scenario: Attempt to create custom fields with extra query parameters
    Given an existing account with id <valid_account_uuid>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields?unexpectedParam=1
    Then the response code should be 201
    And the response body should be a JSON array of CustomField objects matching the request

    @TC14
    Scenario: Attempt to create custom fields with very large payload (boundary test)
    Given an existing account with id <valid_account_uuid>
    And a JSON array of CustomField objects at the maximum allowed payload size
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 201
    And the response body should be a JSON array of CustomField objects matching the request

    @TC15
    Scenario: Attempt to create custom fields with payload exceeding allowed size
    Given an existing account with id <valid_account_uuid>
    And a JSON array of CustomField objects exceeding the allowed payload size
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating payload too large

    @TC16
    Scenario: Unauthorized access attempt (if authentication required)
    Given an existing account with id <valid_account_uuid>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set
    And the authentication token is missing or invalid
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC17
    Scenario: Service unavailable or dependency failure
    Given the KillBill API or dependent service is down
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC18
    Scenario: Security test - SQL injection attempt in CustomField value
    Given an existing account with id <valid_account_uuid>
    And a JSON array of CustomField objects with value containing SQL injection payload
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating invalid input

    @TC19
    Scenario: Security test - XSS attempt in CustomField value
    Given an existing account with id <valid_account_uuid>
    And a JSON array of CustomField objects with value containing XSS payload
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating invalid input

    @TC20
    Scenario: Recovery from transient network failure
    Given an existing account with id <valid_account_uuid>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set
    And a transient network failure occurs during the request
    When I retry the POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 201
    And the response body should be a JSON array of CustomField objects matching the request

    @TC21
    Scenario: Performance - response time under normal load
    Given an existing account with id <valid_account_uuid>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response time should be less than 500ms
    And the response code should be 201

    @TC22
    Scenario: Performance - response time under peak load (concurrent requests)
    Given multiple concurrent POST requests to /1.0/kb/accounts/<valid_account_uuid>/customFields with valid bodies and headers
    When the requests are processed
    Then all responses should have status 201
    And no data corruption or loss should occur
    And response times should be within acceptable thresholds

    @TC23
    Scenario: Regression - previously fixed issue with custom field creation
    Given an existing account with id <valid_account_uuid>
    And a valid JSON array of CustomField objects in the request body that previously triggered a bug
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 201
    And the response body should be a JSON array of CustomField objects matching the request

    @TC24
    Scenario: Regression - backward compatibility with previous API clients
    Given an existing account with id <valid_account_uuid>
    And a valid JSON array of CustomField objects in the request body formatted as per previous API version
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 201
    And the response body should be a JSON array of CustomField objects matching the request

    @TC25
    Scenario: Integration - dependent service returns inconsistent data
    Given an existing account with id <valid_account_uuid>
    And a valid JSON array of CustomField objects in the request body
    And the X-Killbill-CreatedBy header is set
    And the dependent service returns inconsistent data
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the system should handle the inconsistency gracefully
    And the response code should be 201 or appropriate error code

    @TC26
    Scenario: Edge case - empty custom fields array
    Given an existing account with id <valid_account_uuid>
    And an empty JSON array in the request body
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating empty input

    @TC27
    Scenario: Edge case - partial input (missing required fields in CustomField object)
    Given an existing account with id <valid_account_uuid>
    And a JSON array of CustomField objects with missing required fields
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating missing required fields

    @TC28
    Scenario: Edge case - CustomField object with unexpected data types
    Given an existing account with id <valid_account_uuid>
    And a JSON array of CustomField objects with incorrect data types for fields
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 400
    And the response body should contain an error message indicating invalid data type

    @TC29
    Scenario: Edge case - CustomField object with maximum/minimum allowed values
    Given an existing account with id <valid_account_uuid>
    And a JSON array of CustomField objects with maximum and minimum allowed values for fields
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 201
    And the response body should be a JSON array of CustomField objects matching the request

    @TC30
    Scenario: Edge case - CustomField object with null values
    Given an existing account with id <valid_account_uuid>
    And a JSON array of CustomField objects with null values for optional fields
    And the X-Killbill-CreatedBy header is set
    When I POST to /1.0/kb/accounts/<valid_account_uuid>/customFields
    Then the response code should be 201 or 400 depending on field definition
    And the response body should reflect the handling of null values