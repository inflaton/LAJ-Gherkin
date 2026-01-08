Feature: List Subscription Bundles with Pagination
As a KillBill API user,
I want to list subscription bundles with pagination and optional audit levels,
so that I can efficiently retrieve and review bundle data.

  Background:
  Given the KillBill API is running and accessible at the baseUrl
  And the /1.0/kb/bundles/pagination endpoint is available
  And the database contains a diverse set of subscription bundles (including none, one, and many bundles)
  And a valid API authentication token is present in the request headers
  And the system clock is synchronized

    @TC01
    Scenario: Successful retrieval of bundles with default parameters
    Given the database contains multiple bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with no query parameters
    Then the response status code should be 200
    And the response body should be a JSON array of Bundle objects with up to 100 items
    And the audit information for each bundle should be NONE

    @TC02
    Scenario: Successful retrieval with explicit offset and limit
    Given the database contains more than 150 bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with offset=50 and limit=50
    Then the response status code should be 200
    And the response body should be a JSON array of 50 Bundle objects
    And the returned bundles should start from the 51st bundle in the dataset

    @TC03
    Scenario: Successful retrieval with audit=FULL
    Given the database contains at least one bundle
    When the user sends a GET request to /1.0/kb/bundles/pagination with audit=FULL
    Then the response status code should be 200
    And each Bundle object should include full audit information

    @TC04
    Scenario: Successful retrieval with audit=MINIMAL
    Given the database contains at least one bundle
    When the user sends a GET request to /1.0/kb/bundles/pagination with audit=MINIMAL
    Then the response status code should be 200
    And each Bundle object should include minimal audit information

    @TC05
    Scenario: Successful retrieval with all combinations of parameters
    Given the database contains 200 bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with offset=100, limit=50, and audit=FULL
    Then the response status code should be 200
    And the response body should be a JSON array of 50 Bundle objects
    And each Bundle object should include full audit information

    @TC06
    Scenario: Retrieval when no bundles exist
    Given the database contains no bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC07
    Scenario: Retrieval with offset beyond total number of bundles
    Given the database contains 10 bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with offset=1000
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC08
    Scenario: Error when limit is negative
    Given the database contains bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with limit=-10
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid pagination parameters

    @TC09
    Scenario: Error when offset is negative
    Given the database contains bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with offset=-5
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid pagination parameters

    @TC10
    Scenario: Error when audit parameter is invalid
    Given the database contains bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with audit=INVALID_AUDIT
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid audit parameter

    @TC11
    Scenario: Error when limit exceeds maximum allowed value
    Given the database contains bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with limit=1000000
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating limit exceeds maximum allowed value

    @TC12
    Scenario: Unauthorized access attempt
    Given the API authentication token is missing or invalid
    When the user sends a GET request to /1.0/kb/bundles/pagination
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication failure

    @TC13
    Scenario: System error - dependency failure
    Given the database service is unavailable
    When the user sends a GET request to /1.0/kb/bundles/pagination
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailability

    @TC14
    Scenario: Security - SQL injection attempt in query parameters
    Given the database contains bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with offset=0;DROP TABLE bundles
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid parameter value

    @TC15
    Scenario: Edge case - extra unexpected query parameters
    Given the database contains bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with an extra parameter foo=bar
    Then the response status code should be 200
    And the response body should be a JSON array of Bundle objects
    And the extra parameter should be ignored

    @TC16
    Scenario: Edge case - very large offset and limit values at integer boundary
    Given the database contains bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with offset=9223372036854775807 and limit=9223372036854775807
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid pagination parameters

    @TC17
    Scenario: Performance - response time under normal load
    Given the database contains 1000 bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with limit=100
    Then the response status code should be 200
    And the response time should be less than 500ms

    @TC18
    Scenario: Performance - response time under peak load
    Given the database contains 10000 bundles
    And 50 concurrent GET requests are sent to /1.0/kb/bundles/pagination with limit=100
    Then all responses should have status code 200
    And all response times should be less than 2 seconds

    @TC19
    Scenario: Regression - previously fixed issue with audit=MINIMAL and offset=0
    Given the database contains bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with offset=0 and audit=MINIMAL
    Then the response status code should be 200
    And each Bundle object should include minimal audit information

    @TC20
    Scenario: Regression - backward compatibility with previous clients (no audit param)
    Given the database contains bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination without the audit parameter
    Then the response status code should be 200
    And the audit information for each bundle should be NONE

    @TC21
    Scenario: State variation - partially populated database
    Given the database contains only 3 bundles
    When the user sends a GET request to /1.0/kb/bundles/pagination with limit=10
    Then the response status code should be 200
    And the response body should be a JSON array of 3 Bundle objects

    @TC22
    Scenario: Timeout - simulate slow database
    Given the database is responding slowly
    When the user sends a GET request to /1.0/kb/bundles/pagination
    Then the response status code should be 504 or appropriate timeout code
    And the response body should contain an error message indicating timeout