Feature: Modify custom fields for an account via PUT /1.0/kb/accounts/{accountId}/customFields
As a KillBill API user,
I want to modify custom fields for a specific account,
so that I can update account metadata as needed.

  Background:
  Given the KillBill API is available
  And the database contains a set of accounts with diverse custom fields
  And I have a valid authentication token
  And the API endpoint PUT /1.0/kb/accounts/{accountId}/customFields is reachable

    @TC01
    Scenario: Successful modification of custom fields for an account with all required headers
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a valid JSON array of CustomField objects is provided in the request body
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 204
    And the account's custom fields should be updated in the database

    @TC02
    Scenario: Successful modification with optional headers (X-Killbill-Reason and X-Killbill-Comment)
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And valid X-Killbill-CreatedBy, X-Killbill-Reason, and X-Killbill-Comment headers are provided
    And a valid JSON array of CustomField objects is provided in the request body
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 204
    And the account's custom fields should be updated in the database

    @TC03
    Scenario: Successful modification when account has no existing custom fields
    Given an existing account with accountId 'valid-uuid-0000-0000-0000-0000' and no custom fields
    And a valid X-Killbill-CreatedBy header is provided
    And a valid JSON array of CustomField objects is provided in the request body
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-0000-0000-0000-0000/customFields
    Then the API should respond with HTTP status code 204
    And the custom fields should be created for the account

    @TC04
    Scenario: Successful modification with a large array of custom fields
    Given an existing account with accountId 'valid-uuid-9999-8888-7777-6666'
    And a valid X-Killbill-CreatedBy header is provided
    And a valid JSON array of 100 CustomField objects is provided in the request body
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-9999-8888-7777-6666/customFields
    Then the API should respond with HTTP status code 204
    And all custom fields should be updated accordingly

    @TC05
    Scenario: Modification with extra, unsupported headers
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And unsupported headers are included in the request
    And a valid JSON array of CustomField objects is provided in the request body
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 204
    And the unsupported headers should be ignored

    @TC06
    Scenario: Error when accountId is invalid format
    Given an invalid accountId 'not-a-uuid'
    And a valid X-Killbill-CreatedBy header is provided
    And a valid JSON array of CustomField objects is provided in the request body
    When the user sends a PUT request to /1.0/kb/accounts/not-a-uuid/customFields
    Then the API should respond with HTTP status code 400
    And the response body should contain an error message indicating invalid accountId

    @TC07
    Scenario: Error when accountId does not exist
    Given a non-existent accountId '00000000-0000-0000-0000-000000000000'
    And a valid X-Killbill-CreatedBy header is provided
    And a valid JSON array of CustomField objects is provided in the request body
    When the user sends a PUT request to /1.0/kb/accounts/00000000-0000-0000-0000-000000000000/customFields
    Then the API should respond with HTTP status code 400
    And the response body should contain an error message indicating the account was not found

    @TC08
    Scenario: Error when X-Killbill-CreatedBy header is missing
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And the X-Killbill-CreatedBy header is not provided
    And a valid JSON array of CustomField objects is provided in the request body
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 400
    And the response body should contain an error message indicating missing required header

    @TC09
    Scenario: Error when request body is missing
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And the request body is missing
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 400
    And the response body should contain an error message indicating missing request body

    @TC10
    Scenario: Error when request body is malformed JSON
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And the request body contains malformed JSON
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 400
    And the response body should contain an error message indicating malformed JSON

    @TC11
    Scenario: Error when CustomField objects are invalid (missing required fields)
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And the request body contains CustomField objects missing required fields
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 400
    And the response body should contain an error message indicating invalid CustomField schema

    @TC12
    Scenario: Error when unauthorized (invalid or missing authentication token)
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a valid JSON array of CustomField objects is provided in the request body
    And no authentication token is provided
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 401
    And the response body should contain an error message indicating unauthorized access

    @TC13
    Scenario: Error when server is unavailable
    Given the KillBill API service is down
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 503
    And the response body should indicate service unavailability

    @TC14
    Scenario: Error when dependency service fails during update
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a valid JSON array of CustomField objects is provided in the request body
    And a dependent service is unavailable
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 502
    And the response body should indicate a dependency failure

    @TC15
    Scenario: Edge case with empty array of CustomField objects
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And the request body is an empty JSON array
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 204
    And all custom fields for the account should be removed

    @TC16
    Scenario: Edge case with maximum allowed field values and lengths
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a JSON array of CustomField objects with maximum allowed field lengths is provided
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 204
    And the custom fields should be updated with the maximum values

    @TC17
    Scenario: Edge case with additional, unexpected properties in CustomField objects
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a JSON array of CustomField objects with extra properties is provided
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 204
    And extra properties should be ignored

    @TC18
    Scenario: Edge case with partial input (some CustomField objects valid, some invalid)
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And the request body contains a mix of valid and invalid CustomField objects
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 400
    And the response body should indicate which objects were invalid

    @TC19
    Scenario: Edge case with timeout (long-running operation)
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a valid JSON array of CustomField objects is provided in the request body
    And the backend is artificially slowed down
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 504
    And the response body should indicate a timeout occurred

    @TC20
    Scenario: Security test - SQL injection attempt in CustomField values
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a JSON array of CustomField objects with SQL injection payloads in field values is provided
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 400
    And the response body should indicate invalid input detected

    @TC21
    Scenario: Security test - XSS attempt in CustomField values
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a JSON array of CustomField objects with XSS payloads in field values is provided
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 400
    And the response body should indicate invalid input detected

    @TC22
    Scenario: Recovery from transient network error
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a valid JSON array of CustomField objects is provided in the request body
    And a transient network error occurs during the request
    When the user retries the PUT request within a short interval
    Then the API should respond with HTTP status code 204 if the retry is successful

    @TC23
    Scenario: Regression - previously fixed issue with duplicate custom field names
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a JSON array of CustomField objects with duplicate field names is provided
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 400
    And the response body should indicate duplicate field names are not allowed

    @TC24
    Scenario: Regression - backward compatibility with previous API clients
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a JSON array of CustomField objects formatted as per previous API version is provided
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 204
    And the custom fields should be updated as expected

    @TC25
    Scenario: Performance - multiple concurrent requests to modify custom fields
    Given multiple valid accounts each with a valid X-Killbill-CreatedBy header
    And valid JSON arrays of CustomField objects for each account
    When the user sends concurrent PUT requests to /1.0/kb/accounts/{accountId}/customFields
    Then all requests should respond with HTTP status code 204
    And the system should maintain data consistency

    @TC26
    Scenario: Performance - large payload size near system limit
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a JSON array of CustomField objects with total payload size near the API's maximum allowed size is provided
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the API should respond with HTTP status code 204 if within limits
    And the API should respond with HTTP status code 413 if the payload exceeds the limit

    @TC27
    Scenario: Integration - dependent service updates custom field audit logs
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a valid JSON array of CustomField objects is provided in the request body
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the dependent audit log service should record the changes
    And the API should respond with HTTP status code 204

    @TC28
    Scenario: Integration - data consistency with external reporting system
    Given an existing account with accountId 'valid-uuid-1234-5678-9012-3456'
    And a valid X-Killbill-CreatedBy header is provided
    And a valid JSON array of CustomField objects is provided in the request body
    When the user sends a PUT request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/customFields
    Then the external reporting system should reflect the updated custom fields
    And the API should respond with HTTP status code 204

    @TC29
    Scenario: Accessibility - API documentation and error messages are accessible
    Given the API documentation and error messages are available
    When a screen reader is used to access the documentation and error responses
    Then all information should be accessible and understandable
    And error messages should be descriptive and actionable