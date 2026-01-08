Feature: Retrieve custom fields for a bundle via GET /1.0/kb/bundles/{bundleId}/customFields
As a KillBill API user,
I want to retrieve custom fields for a specific bundle,
so that I can view metadata and audit information associated with that bundle.

  Background:
  Given the KillBill API is available
  And the database contains bundles with various custom fields
  And I have a valid authentication token
  And the endpoint /1.0/kb/bundles/{bundleId}/customFields is accessible

    @TC01
    Scenario: Successful retrieval of custom fields with default audit parameter
    Given a valid bundleId that exists in the system
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields without the audit query parameter
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects
    And each CustomField object should match the expected schema
    And the audit information should be at the default level (NONE)

    @TC02
    Scenario: Successful retrieval of custom fields with audit=FULL
    Given a valid bundleId that exists in the system
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields with query parameter audit=FULL
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects
    And each CustomField object should include full audit details

    @TC03
    Scenario: Successful retrieval of custom fields with audit=MINIMAL
    Given a valid bundleId that exists in the system
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields with query parameter audit=MINIMAL
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects
    And each CustomField object should include minimal audit details

    @TC04
    Scenario: Retrieval when bundle has no custom fields
    Given a valid bundleId that exists in the system and has no custom fields
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC05
    Scenario: Retrieval when no bundle exists with the given bundleId
    Given a bundleId that does not exist in the system
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields
    Then the response status code should be 404
    And the response body should contain an error message indicating bundle not found

    @TC06
    Scenario: Retrieval with invalid bundleId format
    Given a bundleId that does not conform to the uuid pattern
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid bundleId

    @TC07
    Scenario: Retrieval with unsupported audit parameter value
    Given a valid bundleId that exists in the system
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields with query parameter audit=INVALID
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid audit parameter

    @TC08
    Scenario: Unauthorized access attempt
    Given a valid bundleId that exists in the system
    And I do not provide a valid authentication token
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication failure

    @TC09
    Scenario: System error during retrieval (e.g., database unavailable)
    Given a valid bundleId that exists in the system
    And the database is temporarily unavailable
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailability

    @TC10
    Scenario: Retrieval with extra, unexpected query parameters
    Given a valid bundleId that exists in the system
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields with extra query parameter foo=bar
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects
    And the extra parameter should be ignored

    @TC11
    Scenario: Retrieval with maximum allowed custom fields
    Given a valid bundleId that exists in the system and has the maximum allowed number of custom fields
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields
    Then the response status code should be 200
    And the response body should be a JSON array containing the maximum allowed number of CustomField objects

    @TC12
    Scenario: Retrieval with minimum allowed custom fields (one field)
    Given a valid bundleId that exists in the system and has exactly one custom field
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields
    Then the response status code should be 200
    And the response body should be a JSON array containing exactly one CustomField object

    @TC13
    Scenario: Retrieval with partial or malformed audit parameter
    Given a valid bundleId that exists in the system
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields with query parameter audit=FUL
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid audit parameter

    @TC14
    Scenario: Retrieval with long-running operation (performance)
    Given a valid bundleId that exists in the system
    And the bundle has a large number of custom fields
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields
    Then the response status code should be 200
    And the response should be returned within acceptable response time thresholds

    @TC15
    Scenario: Regression - previously fixed issue for custom field retrieval
    Given a valid bundleId that previously failed to retrieve custom fields due to a known bug
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects
    And the issue should not reoccur

    @TC16
    Scenario: Integration - dependent service for audit information is unavailable
    Given a valid bundleId that exists in the system
    And the audit service is unavailable
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields with query parameter audit=FULL
    Then the response status code should be 503
    And the response body should contain an error message indicating audit service unavailability

    @TC17
    Scenario: Security - SQL injection attempt in bundleId
    Given a bundleId containing SQL injection payload
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid bundleId

    @TC18
    Scenario: Security - XSS attempt in audit parameter
    Given a valid bundleId that exists in the system
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields with query parameter audit=<script>alert(1)</script>
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid audit parameter

    @TC19
    Scenario: Retrieval with concurrent requests
    Given multiple valid bundleIds that exist in the system
    When I send concurrent GET requests to /1.0/kb/bundles/{bundleId}/customFields for each bundleId
    Then each response status code should be 200
    And each response body should be a JSON array of CustomField objects for the respective bundleId

    @TC20
    Scenario: Accessibility - response structure is machine-readable
    Given a valid bundleId that exists in the system
    When I send a GET request to /1.0/kb/bundles/{bundleId}/customFields
    Then the response Content-Type header should be application/json
    And the response body should be a valid JSON array