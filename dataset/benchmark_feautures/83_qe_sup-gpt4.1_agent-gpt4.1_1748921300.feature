Feature: Search custom fields via GET /1.0/kb/customFields/search
As a KillBill API user,
I want to search for custom fields by object type, name, and value,
so that I can retrieve relevant custom field data with optional pagination and audit information.

  Background:
  Given the KillBill API is available at the configured baseUrl
  And the database contains a diverse set of custom fields with various object types, names, and values
  And valid API authentication headers are provided
  And the system clock is synchronized
  And any required dependent services (e.g., audit logs) are available or properly mocked

    @TC01
    Scenario: Successful search with no query parameters (fetch all custom fields)
    Given the system contains multiple custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with no query parameters
    Then the response status code should be 200
    And the response body should be a JSON array containing all custom fields
    And each object in the array should conform to the CustomField schema

    @TC02
    Scenario: Successful search by objectType only
    Given the system contains custom fields for multiple object types including ACCOUNT
    When the user sends a GET request to /1.0/kb/customFields/search with objectType=ACCOUNT
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects where objectType is ACCOUNT

    @TC03
    Scenario: Successful search by fieldName only
    Given the system contains custom fields with various field names including "custom_label"
    When the user sends a GET request to /1.0/kb/customFields/search with fieldName=custom_label
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects where fieldName is "custom_label"

    @TC04
    Scenario: Successful search by fieldValue only
    Given the system contains custom fields with various field values including "active"
    When the user sends a GET request to /1.0/kb/customFields/search with fieldValue=active
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects where fieldValue is "active"

    @TC05
    Scenario: Successful search by objectType and fieldName
    Given the system contains custom fields with objectType=INVOICE and fieldName="due_date"
    When the user sends a GET request to /1.0/kb/customFields/search with objectType=INVOICE and fieldName=due_date
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects where objectType is INVOICE and fieldName is "due_date"

    @TC06
    Scenario: Successful search by objectType, fieldName, and fieldValue
    Given the system contains a custom field with objectType=ACCOUNT, fieldName="vip", and fieldValue="true"
    When the user sends a GET request to /1.0/kb/customFields/search with objectType=ACCOUNT, fieldName=vip, and fieldValue=true
    Then the response status code should be 200
    And the response body should be a JSON array containing only the matching CustomField object

    @TC07
    Scenario: Successful search with pagination parameters (offset and limit)
    Given the system contains more than 5 custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with limit=5 and offset=2
    Then the response status code should be 200
    And the response body should be a JSON array containing at most 5 CustomField objects starting from the third record

    @TC08
    Scenario: Successful search with audit parameter FULL
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with audit=FULL
    Then the response status code should be 200
    And each CustomField object in the response should include full audit information

    @TC09
    Scenario: Successful search with audit parameter MINIMAL
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with audit=MINIMAL
    Then the response status code should be 200
    And each CustomField object in the response should include minimal audit information

    @TC10
    Scenario: Successful search with audit parameter NONE
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with audit=NONE
    Then the response status code should be 200
    And each CustomField object in the response should not include audit information

    @TC11
    Scenario: Search returns empty array when no custom fields match
    Given the system contains custom fields that do not match objectType=SUBSCRIPTION
    When the user sends a GET request to /1.0/kb/customFields/search with objectType=SUBSCRIPTION
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC12
    Scenario: Search with extra/unexpected query parameters
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with an extra query parameter foo=bar
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects
    And the extra parameter should be ignored

    @TC13
    Scenario: Search with invalid objectType value
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with objectType=INVALID_TYPE
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid objectType

    @TC14
    Scenario: Search with invalid offset value (negative number)
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with offset=-1
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid offset

    @TC15
    Scenario: Search with invalid limit value (zero or negative)
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with limit=0
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid limit

    @TC16
    Scenario: Search with invalid audit parameter value
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with audit=INVALID_AUDIT
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid audit value

    @TC17
    Scenario: Search with missing or invalid authentication
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search without authentication headers
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication is required

    @TC18
    Scenario: Search when dependent service (e.g., audit log) is unavailable
    Given the audit log service is unavailable
    When the user sends a GET request to /1.0/kb/customFields/search with audit=FULL
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC19
    Scenario: Search with SQL injection attempt in fieldName
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with fieldName="'; DROP TABLE custom_fields;--"
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid input
    And no data should be deleted from the database

    @TC20
    Scenario: Search with XSS attempt in fieldValue
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with fieldValue="<script>alert('xss')</script>"
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid input

    @TC21
    Scenario: Search with very large limit value
    Given the system contains more than 1000 custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with limit=1000
    Then the response status code should be 200
    And the response body should be a JSON array containing up to 1000 CustomField objects

    @TC22
    Scenario: Search with very large offset value that exceeds data size
    Given the system contains 10 custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with offset=100
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC23
    Scenario: Search with concurrent requests
    Given the system contains many custom fields
    When multiple users send concurrent GET requests to /1.0/kb/customFields/search with different query parameters
    Then all responses should have status code 200
    And each response should return the correct filtered data

    @TC24
    Scenario: Search with database under heavy load
    Given the system contains many custom fields and is under simulated heavy load
    When the user sends a GET request to /1.0/kb/customFields/search
    Then the response status code should be 200
    And the response time should be within acceptable thresholds (e.g., <2s)

    @TC25
    Scenario: Regression - previously fixed bug with fieldName filtering
    Given the system previously had a bug where fieldName filtering did not work
    When the user sends a GET request to /1.0/kb/customFields/search with fieldName set
    Then the response status code should be 200
    And the response body should only include custom fields matching the fieldName

    @TC26
    Scenario: Regression - previously fixed bug with audit=FULL response
    Given the system previously had a bug where audit=FULL did not include all audit fields
    When the user sends a GET request to /1.0/kb/customFields/search with audit=FULL
    Then the response status code should be 200
    And the response body should include all expected audit fields per schema

    @TC27
    Scenario: Backward compatibility - clients using only objectType parameter
    Given the system contains custom fields for multiple object types
    When a legacy client sends a GET request to /1.0/kb/customFields/search with only objectType
    Then the response status code should be 200
    And the response body should only include custom fields matching the objectType

    @TC28
    Scenario: State variation - empty database
    Given the database contains no custom fields
    When the user sends a GET request to /1.0/kb/customFields/search
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC29
    Scenario: State variation - partially populated database
    Given the database contains only a subset of custom fields
    When the user sends a GET request to /1.0/kb/customFields/search
    Then the response status code should be 200
    And the response body should contain only the available custom fields

    @TC30
    Scenario: Performance - response time under normal load
    Given the system contains 100 custom fields
    When the user sends a GET request to /1.0/kb/customFields/search
    Then the response status code should be 200
    And the response time should be less than 500ms

    @TC31
    Scenario: Performance - response time under peak load
    Given the system contains 10,000 custom fields
    When the user sends a GET request to /1.0/kb/customFields/search
    Then the response status code should be 200
    And the response time should be less than 2s

    @TC32
    Scenario: Integration - data consistency with dependent services
    Given the system contains custom fields and is integrated with audit log service
    When the user sends a GET request to /1.0/kb/customFields/search with audit=FULL
    Then the audit information in the response should match the records in the audit log service

    @TC33
    Scenario: Integration - behavior when audit log service is degraded
    Given the audit log service is responding slowly
    When the user sends a GET request to /1.0/kb/customFields/search with audit=FULL
    Then the response status code should be 200 or 503 depending on timeout policy
    And the response time should be within documented timeout limits

    @TC34
    Scenario: Accessibility - API documentation is accessible
    Given the user has access to the API documentation
    When the user reviews the documentation for /1.0/kb/customFields/search
    Then the documentation should clearly describe all query parameters, response structure, and error codes

    @TC35
    Scenario: Accessibility - error messages are descriptive
    Given the user sends a GET request with invalid parameters
    When the system returns an error response
    Then the error message should be descriptive and actionable
    And the error response should include an error code, message, and details if applicable

    @TC36
    Scenario: Recovery from transient network failure
    Given the user experiences a temporary network failure while making the request
    When the network recovers and the request is retried
    Then the response status code should be 200
    And the response body should contain the expected data

    @TC37
    Scenario: Search with partial input (only some parameters provided)
    Given the system contains custom fields
    When the user sends a GET request to /1.0/kb/customFields/search with only fieldName provided
    Then the response status code should be 200
    And the response body should only include custom fields with the specified fieldName