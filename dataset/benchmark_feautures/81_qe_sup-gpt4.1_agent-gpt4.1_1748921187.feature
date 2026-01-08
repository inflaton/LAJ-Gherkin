Feature: List custom fields with pagination via GET /1.0/kb/customFields/pagination
As a KillBill API user,
I want to retrieve a paginated list of custom fields,
so that I can efficiently browse and manage custom fields across all objects.

  Background:
  Given the KillBill API is running and accessible
  And the database contains a diverse set of custom fields across multiple objects
  And the user has a valid authentication token
  And the API endpoint /1.0/kb/customFields/pagination is available

    @TC01
    Scenario: Successful retrieval of custom fields with default parameters
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with no query parameters
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects
    And the number of returned items should be less than or equal to 100
    And each CustomField should contain all required fields as per the API definition

    @TC02
    Scenario: Successful retrieval with specific offset and limit
    Given there are more than 150 custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with offset=50 and limit=75
    Then the response status code should be 200
    And the response body should be a JSON array of up to 75 CustomField objects starting from the 51st record

    @TC03
    Scenario: Successful retrieval with audit parameter set to FULL
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with audit=FULL
    Then the response status code should be 200
    And each CustomField object in the response should include full audit information

    @TC04
    Scenario: Successful retrieval with audit parameter set to MINIMAL
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with audit=MINIMAL
    Then the response status code should be 200
    And each CustomField object in the response should include minimal audit information

    @TC05
    Scenario: Successful retrieval with audit parameter set to NONE
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with audit=NONE
    Then the response status code should be 200
    And each CustomField object in the response should not include audit information

    @TC06
    Scenario: Successful retrieval with all parameters combined
    Given there are at least 200 custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with offset=100, limit=50, and audit=FULL
    Then the response status code should be 200
    And the response body should be a JSON array of up to 50 CustomField objects starting from the 101st record
    And each CustomField should include full audit information

    @TC07
    Scenario: Retrieval when no custom fields exist
    Given the database contains no custom fields
    When the user sends a GET request to /1.0/kb/customFields/pagination
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC08
    Scenario: Invalid offset parameter (negative value)
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with offset=-1
    Then the response status code should be 400 or higher
    And the response body should include an error message indicating invalid offset

    @TC09
    Scenario: Invalid limit parameter (zero value)
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with limit=0
    Then the response status code should be 400 or higher
    And the response body should include an error message indicating invalid limit

    @TC10
    Scenario: Invalid limit parameter (negative value)
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with limit=-10
    Then the response status code should be 400 or higher
    And the response body should include an error message indicating invalid limit

    @TC11
    Scenario: Invalid audit parameter value
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with audit=INVALID
    Then the response status code should be 400 or higher
    And the response body should include an error message indicating invalid audit parameter

    @TC12
    Scenario: Missing or invalid authentication token
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination without a valid authentication token
    Then the response status code should be 401
    And the response body should include an error message indicating authentication failure

    @TC13
    Scenario: System error or service unavailable
    Given the KillBill API service is down or unreachable
    When the user sends a GET request to /1.0/kb/customFields/pagination
    Then the response status code should be 503
    And the response body should include an error message indicating service unavailability

    @TC14
    Scenario: SQL injection attempt in audit parameter
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with audit="FULL; DROP TABLE custom_fields;"
    Then the response status code should be 400 or higher
    And the response body should not reveal sensitive system information

    @TC15
    Scenario: Extra unsupported query parameters
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with foo=bar
    Then the response status code should be 200
    And the response should ignore the extra parameter and return valid results

    @TC16
    Scenario: Edge case with maximum integer offset and limit
    Given there are more than 1000 custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with offset=9223372036854775807 and limit=9223372036854775807
    Then the response status code should be 200 or 400 depending on system constraints
    And the response should handle the boundary condition gracefully

    @TC17
    Scenario: Edge case with partial input (only offset provided)
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with offset=10
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects starting from the 11th record
    And the number of returned items should be less than or equal to 100

    @TC18
    Scenario: Edge case with partial input (only limit provided)
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with limit=10
    Then the response status code should be 200
    And the response body should be a JSON array of up to 10 CustomField objects

    @TC19
    Scenario: Timeout condition (long-running operation)
    Given the API is under heavy load or the database is slow
    When the user sends a GET request to /1.0/kb/customFields/pagination
    Then the response status code should be 504 or 503 if timeout occurs
    And the response body should include an error message indicating timeout

    @TC20
    Scenario: Large data volume retrieval
    Given there are more than 10,000 custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with limit=1000
    Then the response status code should be 200
    And the response body should be a JSON array of up to 1000 CustomField objects

    @TC21
    Scenario: Concurrent requests for pagination
    Given there are more than 500 custom fields in the system
    When multiple users send concurrent GET requests to /1.0/kb/customFields/pagination with varying offsets and limits
    Then all responses should have status code 200
    And each response should return the correct subset of CustomField objects as per the offset and limit

    @TC22
    Scenario: Regression - previously fixed issue with incorrect pagination
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination with offset=5 and limit=5
    Then the response status code should be 200
    And the response body should contain exactly 5 CustomField objects
    And the objects should correspond to the correct records as per the offset

    @TC23
    Scenario: Backward compatibility with existing clients
    Given there are custom fields in the system
    When an older client sends a GET request to /1.0/kb/customFields/pagination using only default parameters
    Then the response status code should be 200
    And the response body should be compatible with previous versions of the CustomField schema

    @TC24
    Scenario: Accessibility - API response structure is consistent and documented
    Given there are custom fields in the system
    When the user sends a GET request to /1.0/kb/customFields/pagination
    Then the response status code should be 200
    And the response body should follow the documented JSON schema for CustomField objects
    And all field names should be accessible and readable by assistive technologies