Feature: Retrieve all custom fields for an account via GET /1.0/kb/accounts/{accountId}/allCustomFields
As a KillBill API user,
I want to retrieve all custom fields associated with an account, optionally filtered by object type and audit level,
so that I can view relevant custom field data for an account efficiently and securely.

  Background:
  Given the KillBill API is running and accessible
  And the database contains accounts with various custom fields
  And valid and invalid account IDs are available for testing
  And the API authentication token is set in the request headers
  And the API endpoint base URL is configured

    @TC01
    Scenario: Successful retrieval with only required accountId
    Given an account exists with multiple custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with a valid accountId and no query parameters
    Then the API responds with HTTP 200
    And the response body is a JSON array of all CustomField objects associated with the account
    And each object matches the CustomField schema

    @TC02
    Scenario: Successful retrieval with objectType filter
    Given an account exists with custom fields attached to multiple object types
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with a valid accountId and objectType set to "INVOICE"
    Then the API responds with HTTP 200
    And the response body is a JSON array of CustomField objects where each objectType is "INVOICE"
    And each object matches the CustomField schema

    @TC03
    Scenario: Successful retrieval with audit parameter FULL
    Given an account exists with custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with audit set to "FULL"
    Then the API responds with HTTP 200
    And the response body contains audit information at the FULL level for each CustomField object

    @TC04
    Scenario: Successful retrieval with audit parameter MINIMAL
    Given an account exists with custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with audit set to "MINIMAL"
    Then the API responds with HTTP 200
    And the response body contains audit information at the MINIMAL level for each CustomField object

    @TC05
    Scenario: Successful retrieval with both objectType and audit parameters
    Given an account exists with custom fields of type "SUBSCRIPTION"
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with objectType set to "SUBSCRIPTION" and audit set to "FULL"
    Then the API responds with HTTP 200
    And the response body is a JSON array of CustomField objects where each objectType is "SUBSCRIPTION"
    And each object includes FULL audit information

    @TC06
    Scenario: Retrieval when no custom fields exist for the account
    Given an account exists with no custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 200
    And the response body is an empty JSON array

    @TC07
    Scenario: Retrieval with objectType that has no matching custom fields
    Given an account exists with custom fields but none with objectType "PAYMENT"
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with objectType set to "PAYMENT"
    Then the API responds with HTTP 200
    And the response body is an empty JSON array

    @TC08
    Scenario: Retrieval with all valid objectType enum values
    Given an account exists with custom fields for each possible objectType
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with objectType set to each enum value in turn
    Then the API responds with HTTP 200
    And the response body contains only custom fields matching the requested objectType

    @TC09
    Scenario: Retrieval with all valid audit enum values
    Given an account exists with custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with audit set to each enum value (FULL, MINIMAL, NONE)
    Then the API responds with HTTP 200
    And the response body contains audit information per the specified audit level

    @TC10
    Scenario: Retrieval with extra/unsupported query parameters
    Given an account exists with custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with an unsupported query parameter "foo=bar"
    Then the API responds with HTTP 200
    And the response body contains all custom fields (ignoring unsupported parameter)

    @TC11
    Scenario: Retrieval with large number of custom fields
    Given an account exists with more than 1000 custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 200
    And the response body contains all custom fields
    And the response time is within acceptable limits (e.g., < 2 seconds)

    @TC12
    Scenario: Retrieval with invalid accountId format
    Given an invalid accountId that does not match the UUID pattern
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid accountId

    @TC13
    Scenario: Retrieval for non-existent account
    Given a valid accountId that does not exist in the system
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 404
    And the response body contains an error message indicating account not found

    @TC14
    Scenario: Retrieval with missing authentication token
    Given an account exists with custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields without an authentication token
    Then the API responds with HTTP 401
    And the response body contains an error message indicating authentication is required

    @TC15
    Scenario: Retrieval with invalid authentication token
    Given an account exists with custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with an invalid authentication token
    Then the API responds with HTTP 401
    And the response body contains an error message indicating authentication is required

    @TC16
    Scenario: Retrieval when KillBill service is unavailable
    Given the KillBill API service is down
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 503
    And the response body contains an error message indicating service unavailable

    @TC17
    Scenario: Retrieval with SQL injection attempt in accountId
    Given a malicious accountId input containing SQL injection payload
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 400 or 404
    And the response body does not reveal sensitive information

    @TC18
    Scenario: Retrieval with XSS attempt in objectType
    Given an account exists with custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with objectType set to a string containing script tags
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid objectType

    @TC19
    Scenario: Retrieval with network timeout
    Given the network between client and server is slow or interrupted
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API should retry the request if configured
    And eventually respond with HTTP 504 if the timeout threshold is exceeded

    @TC20
    Scenario: Retrieval after a transient error (retry mechanism)
    Given the KillBill API was temporarily unavailable but is now restored
    When the user retries the GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 200
    And the response body contains all custom fields

    @TC21
    Scenario: Regression - previously fixed issue with audit parameter handling
    Given an account exists with custom fields
    And a previous bug caused the audit parameter to be ignored
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with audit set to "FULL"
    Then the API responds with HTTP 200
    And the response body contains FULL audit information as expected

    @TC22
    Scenario: Regression - backward compatibility with previous clients
    Given an account exists with custom fields
    When a legacy client sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields without audit or objectType
    Then the API responds with HTTP 200
    And the response body is consistent with previous versions

    @TC23
    Scenario: Integration - dependent service unavailable
    Given the audit service is unavailable
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with audit set to "FULL"
    Then the API responds with HTTP 503
    And the response body indicates the dependency failure

    @TC24
    Scenario: Integration - data consistency across services
    Given an account with custom fields is updated in another service
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 200
    And the custom fields data is consistent with the latest updates

    @TC25
    Scenario: Performance - concurrent requests for custom fields
    Given multiple users send concurrent GET requests to /1.0/kb/accounts/{accountId}/allCustomFields
    When the requests are processed
    Then all responses are HTTP 200
    And response times remain within acceptable limits

    @TC26
    Scenario: Performance - high resource utilization
    Given the system is under heavy load
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 200
    And resource utilization remains within safe thresholds

    @TC27
    Scenario: State variation - partially populated database
    Given the database contains some accounts with and some without custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields for both types
    Then the API responds accordingly with either a JSON array of custom fields or an empty array

    @TC28
    Scenario: State variation - degraded system performance
    Given the KillBill API is experiencing degraded performance
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API still responds with HTTP 200
    And response time is logged for monitoring

    @TC29
    Scenario: Edge case - minimum allowed values
    Given an account exists with a single custom field
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 200
    And the response body contains exactly one custom field

    @TC30
    Scenario: Edge case - maximum allowed values
    Given an account exists with the maximum number of custom fields allowed by the system
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 200
    And the response body contains all allowed custom fields

    @TC31
    Scenario: Edge case - partial input (missing objectType or audit)
    Given an account exists with custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with only one optional parameter
    Then the API responds with HTTP 200
    And the response body reflects the requested filter

    @TC32
    Scenario: Edge case - unexpected input format for objectType
    Given an account exists with custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with objectType set to an array or numeric value
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid parameter type

    @TC33
    Scenario: Edge case - extremely long accountId
    Given an accountId string exceeding the maximum allowed length
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid accountId

    @TC34
    Scenario: Edge case - empty accountId
    Given an empty accountId is provided
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating accountId is required

    @TC35
    Scenario: Edge case - whitespace in accountId
    Given an accountId with leading or trailing whitespace
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid accountId

    @TC36
    Scenario: Edge case - whitespace in objectType
    Given an account exists with custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields with objectType set to a valid enum value plus whitespace
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid objectType

    @TC37
    Scenario: Accessibility - proper response structure for screen readers
    Given an account exists with custom fields
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 200
    And the response body uses standard JSON structure and property names for accessibility

    @TC38
    Scenario: Accessibility - error messages are descriptive
    Given an invalid accountId is provided
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with an error code
    And the response body contains a descriptive, human-readable error message

    @TC39
    Scenario: Recovery - system returns to normal after error
    Given the KillBill API was returning HTTP 503 due to service outage
    When the service is restored and the user retries the GET request to /1.0/kb/accounts/{accountId}/allCustomFields
    Then the API responds with HTTP 200
    And the response body contains all custom fields