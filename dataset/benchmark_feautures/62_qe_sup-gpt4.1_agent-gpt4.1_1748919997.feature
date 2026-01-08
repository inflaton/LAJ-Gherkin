Feature: Search Bundles API (GET /1.0/kb/bundles/search/{searchKey})
As a KillBill API user,
I want to search for subscription bundles using a search key,
so that I can retrieve relevant bundle information efficiently and with appropriate audit detail.

  Background:
  Given the KillBill API server is running and reachable
  And the database contains a diverse set of bundles with varying attributes
  And I have a valid authentication token
  And the API endpoint /1.0/kb/bundles/search/{searchKey} is available

    @TC01
    Scenario: Successful search with only required path parameter (happy path)
    Given a valid searchKey that matches at least one bundle
    When I send a GET request to /1.0/kb/bundles/search/{searchKey} with no query parameters
    Then the response status code should be 200
    And the response body should be an array of Bundle objects matching the searchKey
    And the response should be in application/json format

    @TC02
    Scenario: Successful search with offset and limit query parameters
    Given a valid searchKey that matches more than 100 bundles
    When I send a GET request with offset=10 and limit=20
    Then the response status code should be 200
    And the response body should contain at most 20 Bundle objects starting from the 11th match

    @TC03
    Scenario: Successful search with audit parameter set to FULL
    Given a valid searchKey that matches at least one bundle
    When I send a GET request with audit=FULL
    Then the response status code should be 200
    And each Bundle object in the response should include full audit information

    @TC04
    Scenario: Successful search with audit parameter set to MINIMAL
    Given a valid searchKey that matches at least one bundle
    When I send a GET request with audit=MINIMAL
    Then the response status code should be 200
    And each Bundle object in the response should include minimal audit information

    @TC05
    Scenario: Successful search with all query parameters combined
    Given a valid searchKey that matches at least 50 bundles
    When I send a GET request with offset=5, limit=10, and audit=FULL
    Then the response status code should be 200
    And the response body should contain at most 10 Bundle objects with full audit information

    @TC06
    Scenario: Search returns no results (empty response)
    Given a valid searchKey that matches no bundles
    When I send a GET request to /1.0/kb/bundles/search/{searchKey}
    Then the response status code should be 200
    And the response body should be an empty array

    @TC07
    Scenario: Search with offset greater than total matches
    Given a valid searchKey that matches 5 bundles
    When I send a GET request with offset=10
    Then the response status code should be 200
    And the response body should be an empty array

    @TC08
    Scenario: Search with limit set to zero
    Given a valid searchKey that matches at least one bundle
    When I send a GET request with limit=0
    Then the response status code should be 200
    And the response body should be an empty array

    @TC09
    Scenario: Invalid searchKey (malformed input)
    Given a searchKey containing invalid or unsupported characters
    When I send a GET request to /1.0/kb/bundles/search/{searchKey}
    Then the response status code should be 400 or appropriate 4xx
    And the response body should contain an error message indicating invalid search key

    @TC10
    Scenario: Invalid offset parameter (negative value)
    Given a valid searchKey
    When I send a GET request with offset=-1
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid pagination parameter

    @TC11
    Scenario: Invalid limit parameter (negative value)
    Given a valid searchKey
    When I send a GET request with limit=-10
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid pagination parameter

    @TC12
    Scenario: Invalid audit parameter value
    Given a valid searchKey
    When I send a GET request with audit=INVALID_AUDIT
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid audit parameter

    @TC13
    Scenario: Missing authentication token
    Given a valid searchKey
    When I send a GET request without an authentication token
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication failure

    @TC14
    Scenario: Invalid authentication token
    Given a valid searchKey
    When I send a GET request with an invalid authentication token
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication failure

    @TC15
    Scenario: Service unavailable (dependency failure)
    Given the KillBill backend service is down
    When I send a GET request to /1.0/kb/bundles/search/{searchKey}
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC16
    Scenario: System error (unexpected server error)
    Given the system encounters an unexpected error during processing
    When I send a GET request to /1.0/kb/bundles/search/{searchKey}
    Then the response status code should be 500
    And the response body should contain a generic error message

    @TC17
    Scenario: Injection attack attempt in searchKey
    Given a searchKey containing SQL injection payload
    When I send a GET request to /1.0/kb/bundles/search/{searchKey}
    Then the response status code should be 400 or 422
    And the response body should not expose sensitive information

    @TC18
    Scenario: Extra unexpected query parameters
    Given a valid searchKey
    When I send a GET request with an extra query parameter foo=bar
    Then the response status code should be 200
    And the response body should ignore the extra parameter and return correct results

    @TC19
    Scenario: Large data volume (performance)
    Given a searchKey that matches thousands of bundles
    When I send a GET request with limit=1000
    Then the response status code should be 200
    And the response time should be within acceptable thresholds (e.g., <2 seconds)
    And the response body should contain at most 1000 Bundle objects

    @TC20
    Scenario: Concurrent requests (performance and consistency)
    Given multiple valid searchKeys
    When I send 10 concurrent GET requests to /1.0/kb/bundles/search/{searchKey}
    Then all responses should have status code 200
    And each response should contain correct and consistent results

    @TC21
    Scenario: Backward compatibility (regression)
    Given the API has previously supported all query parameter combinations
    When I send requests with previously valid combinations
    Then the responses should remain consistent with prior behavior

    @TC22
    Scenario: Accessibility (if UI client exists)
    Given a UI client for bundle search exists
    When I use a screen reader to navigate the search results
    Then all results and controls should be accessible and labeled appropriately

    @TC23
    Scenario: Search with partially populated database
    Given the database contains only a few bundles
    When I send a GET request to /1.0/kb/bundles/search/{searchKey}
    Then the response status code should be 200
    And the response body should contain only the matching bundles

    @TC24
    Scenario: Search with empty database
    Given the database contains no bundles
    When I send a GET request to /1.0/kb/bundles/search/{searchKey}
    Then the response status code should be 200
    And the response body should be an empty array

    @TC25
    Scenario: Timeout condition (long-running operation)
    Given a searchKey that triggers a slow query
    When I send a GET request to /1.0/kb/bundles/search/{searchKey}
    Then the response status code should be 504 if timeout occurs
    And the response body should indicate a timeout error

    @TC26
    Scenario: Search with maximum allowed values for offset and limit
    Given a valid searchKey that matches more than 10000 bundles
    When I send a GET request with offset=10000 and limit=10000
    Then the response status code should be 200
    And the response body should contain at most 10000 Bundle objects

    @TC27
    Scenario: Search with partial input (searchKey is substring of bundle name)
    Given a searchKey that is a substring of multiple bundle names
    When I send a GET request to /1.0/kb/bundles/search/{searchKey}
    Then the response status code should be 200
    And the response body should contain all bundles whose names contain the substring