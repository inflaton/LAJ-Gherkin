Feature: Retrieve catalog as JSON via GET /1.0/kb/catalog
As a KillBill API user,
I want to retrieve the catalog as JSON, optionally for a specific date and/or account,
so that I can obtain the correct catalog version for my needs.

  Background:
  Given the KillBill API server is running and reachable
  And the /1.0/kb/catalog endpoint is available
  And the database contains catalogs with varying effective dates and versions
  And the database contains accounts with valid UUIDs
  And valid and invalid authentication tokens are available

    @TC01
    Scenario: Successful retrieval of the latest catalog without parameters
    Given the database contains at least one catalog version
    When the user sends a GET request to /1.0/kb/catalog without query parameters and with a valid authentication token
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array of Catalog objects representing the latest catalog version

    @TC02
    Scenario: Successful retrieval of catalog for a specific requestedDate
    Given the database contains catalog versions with varying effective dates
    When the user sends a GET request to /1.0/kb/catalog with the requestedDate parameter set to a valid ISO 8601 date-time and with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array of Catalog objects effective at the requested date

    @TC03
    Scenario: Successful retrieval of catalog for a specific accountId
    Given the database contains at least one catalog version and at least one valid account UUID
    When the user sends a GET request to /1.0/kb/catalog with the accountId parameter set to a valid UUID and with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array of Catalog objects for the specified account

    @TC04
    Scenario: Successful retrieval of catalog for both requestedDate and accountId
    Given the database contains catalog versions for multiple accounts and effective dates
    When the user sends a GET request to /1.0/kb/catalog with both requestedDate and accountId parameters set to valid values and with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array of Catalog objects for the specified account and effective at the requested date

    @TC05
    Scenario: Retrieval when no catalog exists in the system
    Given the database contains no catalog versions
    When the user sends a GET request to /1.0/kb/catalog with a valid authentication token
    Then the response status code should be 404
    And the response body should contain an error message indicating no catalog found

    @TC06
    Scenario: Retrieval with requestedDate for which no catalog exists
    Given the database contains catalog versions but none effective at the requestedDate
    When the user sends a GET request to /1.0/kb/catalog with requestedDate set to a valid ISO 8601 date-time and with a valid authentication token
    Then the response status code should be 404
    And the response body should contain an error message indicating no catalog found for the requested date

    @TC07
    Scenario: Retrieval with invalid requestedDate format
    Given the database contains at least one catalog version
    When the user sends a GET request to /1.0/kb/catalog with requestedDate set to an invalid date-time string and with a valid authentication token
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid date format

    @TC08
    Scenario: Retrieval with invalid accountId format
    Given the database contains at least one catalog version
    When the user sends a GET request to /1.0/kb/catalog with accountId set to an invalid UUID string and with a valid authentication token
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId format

    @TC09
    Scenario: Retrieval with missing authentication token
    Given the database contains at least one catalog version
    When the user sends a GET request to /1.0/kb/catalog without an authentication token
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication is required

    @TC10
    Scenario: Retrieval with invalid authentication token
    Given the database contains at least one catalog version
    When the user sends a GET request to /1.0/kb/catalog with an invalid authentication token
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication failed

    @TC11
    Scenario: Retrieval with extra unsupported query parameters
    Given the database contains at least one catalog version
    When the user sends a GET request to /1.0/kb/catalog with unsupported query parameters and with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array of Catalog objects representing the latest catalog version
    And the unsupported parameters should be ignored

    @TC12
    Scenario: Retrieval with large number of catalog versions (performance)
    Given the database contains a large number of catalog versions
    When the user sends a GET request to /1.0/kb/catalog with a valid authentication token
    Then the response status code should be 200
    And the response time should be less than 2 seconds
    And the response body should be a JSON array of Catalog objects

    @TC13
    Scenario: Retrieval with concurrent requests (performance)
    Given the database contains multiple catalog versions
    When multiple users send concurrent GET requests to /1.0/kb/catalog with valid authentication tokens
    Then all responses should have status code 200
    And response times should remain within acceptable limits

    @TC14
    Scenario: Retrieval when dependent service is unavailable
    Given the database contains at least one catalog version
    And a dependent service is unavailable
    When the user sends a GET request to /1.0/kb/catalog with a valid authentication token
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC15
    Scenario: Retrieval with malicious payload in query parameters (security)
    Given the database contains at least one catalog version
    When the user sends a GET request to /1.0/kb/catalog with a query parameter containing a SQL injection attempt and with a valid authentication token
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid input

    @TC16
    Scenario: Retrieval with partial input (only one parameter provided)
    Given the database contains at least one catalog version and one valid account UUID
    When the user sends a GET request to /1.0/kb/catalog with only accountId or only requestedDate and with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array of Catalog objects filtered by the provided parameter

    @TC17
    Scenario: Retrieval with minimum and maximum allowed values for requestedDate
    Given the database contains catalog versions with a wide range of effective dates
    When the user sends a GET request to /1.0/kb/catalog with requestedDate set to the earliest or latest possible date and with a valid authentication token
    Then the response status code should be 200 or 404 depending on data availability
    And the response body should be correct for the requested date

    @TC18
    Scenario: Retrieval with very large response payload (edge case)
    Given the database contains a catalog version with a very large number of products and plans
    When the user sends a GET request to /1.0/kb/catalog with a valid authentication token
    Then the response status code should be 200
    And the response body should be a large JSON array of Catalog objects
    And the response should not be truncated

    @TC19
    Scenario: Regression - Retrieval after previous bug fix for missing catalog on specific date
    Given the database contains catalog versions including the previously problematic date
    When the user sends a GET request to /1.0/kb/catalog with requestedDate set to the previously problematic date and with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array of Catalog objects effective at that date

    @TC20
    Scenario: Regression - Backward compatibility with existing clients
    Given the database contains at least one catalog version
    When an existing client sends a GET request to /1.0/kb/catalog with parameters as used in previous API versions and with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array of Catalog objects

    @TC21
    Scenario: Recovery from transient network error
    Given the database contains at least one catalog version
    And a transient network error occurs during the first request
    When the user retries the GET request to /1.0/kb/catalog with a valid authentication token
    Then the response status code should be 200
    And the response body should be a JSON array of Catalog objects

    @TC22
    Scenario: Timeout condition for long-running retrieval
    Given the database contains a very large catalog version
    When the user sends a GET request to /1.0/kb/catalog with a valid authentication token and the server takes too long to respond
    Then the response status code should be 504
    And the response body should contain an error message indicating timeout

    @TC23
    Scenario: Accessibility - Response structure is machine-readable
    Given the database contains at least one catalog version
    When the user sends a GET request to /1.0/kb/catalog with a valid authentication token
    Then the response Content-Type should be application/json
    And the response body should be a valid JSON array of Catalog objects as per the API schema