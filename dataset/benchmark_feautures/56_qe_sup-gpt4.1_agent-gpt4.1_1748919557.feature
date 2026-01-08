Feature: Add custom fields to a bundle via POST /1.0/kb/bundles/{bundleId}/customFields
As a KillBill API user,
I want to add custom fields to a bundle,
so that I can associate additional metadata with bundles.

  Background:
  Given the KillBill API is available
  And a valid authentication token is present
  And the system has bundles with diverse and relevant data
  And the CustomField schema is known
  And the request will be sent to POST /1.0/kb/bundles/{bundleId}/customFields

    @TC01
    Scenario: Successful creation of custom fields with required headers and valid bundleId
    Given a valid bundleId exists in the system
    And a JSON array of valid CustomField objects is prepared
    And the X-Killbill-CreatedBy header is set to a valid username
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 201
    And the response body should be a JSON array of the created CustomField objects
    And each CustomField in the response should match the request payload

    @TC02
    Scenario: Successful creation with optional headers X-Killbill-Reason and X-Killbill-Comment
    Given a valid bundleId exists in the system
    And a JSON array of valid CustomField objects is prepared
    And the X-Killbill-CreatedBy header is set to a valid username
    And the X-Killbill-Reason header is set to a valid reason
    And the X-Killbill-Comment header is set to an additional comment
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 201
    And the response body should be a JSON array of the created CustomField objects

    @TC03
    Scenario: Successful creation when no custom fields previously exist for bundle
    Given a valid bundleId exists in the system with no custom fields
    And a JSON array of valid CustomField objects is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 201
    And the response body should contain the new CustomField objects

    @TC04
    Scenario: Successful creation when bundle already has existing custom fields
    Given a valid bundleId exists in the system with existing custom fields
    And a JSON array of new valid CustomField objects is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 201
    And the response body should include all newly created CustomField objects

    @TC05
    Scenario: Attempt to create custom fields with an invalid bundleId format
    Given the bundleId is not a valid UUID format
    And a JSON array of valid CustomField objects is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 400
    And the response body should contain an error message indicating invalid bundleId

    @TC06
    Scenario: Attempt to create custom fields for a non-existent bundle
    Given the bundleId does not exist in the system
    And a JSON array of valid CustomField objects is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 404
    And the response body should contain an error message indicating bundle not found

    @TC07
    Scenario: Attempt to create custom fields with missing X-Killbill-CreatedBy header
    Given a valid bundleId exists in the system
    And a JSON array of valid CustomField objects is prepared
    And the X-Killbill-CreatedBy header is missing
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 400
    And the response body should indicate the missing required header

    @TC08
    Scenario: Attempt to create custom fields with malformed JSON body
    Given a valid bundleId exists in the system
    And the request body is malformed JSON
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 400
    And the response body should indicate a malformed request body

    @TC09
    Scenario: Attempt to create custom fields with empty request body
    Given a valid bundleId exists in the system
    And the request body is empty
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 400
    And the response body should indicate a missing or empty request body

    @TC10
    Scenario: Attempt to create custom fields with invalid CustomField schema
    Given a valid bundleId exists in the system
    And the request body contains CustomField objects with missing required fields
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 400
    And the response body should indicate schema validation errors

    @TC11
    Scenario: Attempt to create custom fields with duplicate field names in the same request
    Given a valid bundleId exists in the system
    And the request body contains CustomField objects with duplicate field names
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 400
    And the response body should indicate duplicate field names are not allowed

    @TC12
    Scenario: Attempt to create custom fields with unsupported additional parameters in request body
    Given a valid bundleId exists in the system
    And the request body contains unsupported additional fields
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 400
    And the response body should indicate unsupported fields in the request

    @TC13
    Scenario: Attempt to create custom fields with extra query parameters
    Given a valid bundleId exists in the system
    And a JSON array of valid CustomField objects is prepared
    And the X-Killbill-CreatedBy header is set
    And extra query parameters are included in the request URL
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 201
    And the response body should be a JSON array of the created CustomField objects

    @TC14
    Scenario: Unauthorized access attempt (no authentication token)
    Given a valid bundleId exists in the system
    And a JSON array of valid CustomField objects is prepared
    And the authentication token is missing or invalid
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 401
    And the response body should indicate unauthorized access

    @TC15
    Scenario: Service unavailable during custom field creation
    Given a valid bundleId exists in the system
    And a JSON array of valid CustomField objects is prepared
    And the X-Killbill-CreatedBy header is set
    And the KillBill service is temporarily unavailable
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 503
    And the response body should indicate service unavailability

    @TC16
    Scenario: Network timeout during custom field creation
    Given a valid bundleId exists in the system
    And a JSON array of valid CustomField objects is prepared
    And the X-Killbill-CreatedBy header is set
    And the network connection is slow or interrupted
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with a timeout error
    And the request should be retried according to client policy

    @TC17
    Scenario: Large payload of custom fields
    Given a valid bundleId exists in the system
    And the request body contains a large number of CustomField objects approaching system limits
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 201 if within limits
    And the response time should be within acceptable thresholds
    And the response body should contain all created CustomField objects

    @TC18
    Scenario: Minimum allowed fields (empty array)
    Given a valid bundleId exists in the system
    And the request body is an empty array
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 400
    And the response body should indicate that at least one custom field is required

    @TC19
    Scenario: Partial input with missing optional headers
    Given a valid bundleId exists in the system
    And a JSON array of valid CustomField objects is prepared
    And only the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 201
    And the response body should be a JSON array of the created CustomField objects

    @TC20
    Scenario: Integration - Dependent service for bundle lookup is unavailable
    Given a valid bundleId exists in the system
    And a JSON array of valid CustomField objects is prepared
    And the X-Killbill-CreatedBy header is set
    And the dependent service for bundle lookup is unavailable
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 503
    And the response body should indicate service dependency failure

    @TC21
    Scenario: Regression - Previously fixed issue with field name casing
    Given a valid bundleId exists in the system
    And the request body contains CustomField objects with field names differing only in case
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond according to the latest specification (e.g., allow or reject based on case sensitivity)

    @TC22
    Scenario: Performance - Multiple concurrent requests to add custom fields
    Given multiple valid bundleIds exist in the system
    And each request contains a valid JSON array of CustomField objects
    And the X-Killbill-CreatedBy header is set for each request
    When multiple users send concurrent POST requests to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 201 for each successful request
    And the system should maintain data consistency
    And response times should remain within acceptable thresholds

    @TC23
    Scenario: Security - SQL injection attempt in CustomField value
    Given a valid bundleId exists in the system
    And the request body contains a CustomField object with a value attempting SQL injection
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 400 or sanitize the input
    And the response body should not expose sensitive information

    @TC24
    Scenario: Security - XSS attempt in CustomField value
    Given a valid bundleId exists in the system
    And the request body contains a CustomField object with a value containing script tags
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/customFields
    Then the API should respond with HTTP 400 or sanitize the input
    And the response body should not reflect the script content

    @TC25
    Scenario: Accessibility - Ensure API documentation is accessible
    Given the API documentation for POST /1.0/kb/bundles/{bundleId}/customFields is available
    When a screen reader user accesses the documentation
    Then the documentation should be navigable and all fields should be described
    And all required/optional fields should be clearly indicated