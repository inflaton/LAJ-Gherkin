Feature: Search Accounts API (GET /1.0/kb/accounts/search/{searchKey})
As a KillBill API user,
I want to search for accounts using a search key and optional filters,
so that I can efficiently retrieve relevant account information with flexible options.

  Background:
  Given the KillBill API is available at the configured baseUrl
  And the API authentication token is valid and included in the request headers
  And the database contains a diverse set of accounts with varying balances, CBA values, and audit trails
  And the API endpoint /1.0/kb/accounts/search/{searchKey} is reachable

    @TC01
    Scenario: Successful search with only required path parameter (happy path)
    Given there are accounts in the system matching the search key "john"
    When the user sends a GET request to /1.0/kb/accounts/search/john with no query parameters
    Then the response status code should be 200
    And the response body should be a JSON array of Account objects matching the search key "john"
    And the response should not include balance or CBA fields
    And the audit field should not be present or should be set to NONE

    @TC02
    Scenario: Successful search with all valid query parameters individually
    Given there are accounts in the system matching the search key "smith"
    When the user sends a GET request to /1.0/kb/accounts/search/smith with offset=0
    Then the response status code should be 200
    And the response should contain the first page of Account objects matching the search key

    When the user sends a GET request to /1.0/kb/accounts/search/smith with limit=2
    Then the response status code should be 200
    And the response should contain at most 2 Account objects

    When the user sends a GET request to /1.0/kb/accounts/search/smith with accountWithBalance=true
    Then the response status code should be 200
    And each Account object should include a balance field

    When the user sends a GET request to /1.0/kb/accounts/search/smith with accountWithBalanceAndCBA=true
    Then the response status code should be 200
    And each Account object should include balance and CBA fields

    When the user sends a GET request to /1.0/kb/accounts/search/smith with audit=FULL
    Then the response status code should be 200
    And each Account object should include full audit information

    When the user sends a GET request to /1.0/kb/accounts/search/smith with audit=MINIMAL
    Then the response status code should be 200
    And each Account object should include minimal audit information

    @TC03
    Scenario: Successful search with combinations of query parameters
    Given there are accounts in the system matching the search key "doe"
    When the user sends a GET request to /1.0/kb/accounts/search/doe with offset=1 and limit=1
    Then the response status code should be 200
    And the response should contain exactly 1 Account object, starting from the second matching account

    When the user sends a GET request to /1.0/kb/accounts/search/doe with accountWithBalance=true and audit=FULL
    Then the response status code should be 200
    And each Account object should include balance and full audit information

    When the user sends a GET request to /1.0/kb/accounts/search/doe with accountWithBalanceAndCBA=true and audit=MINIMAL
    Then the response status code should be 200
    And each Account object should include balance, CBA, and minimal audit information

    When the user sends a GET request to /1.0/kb/accounts/search/doe with all parameters set: offset=2, limit=2, accountWithBalance=true, accountWithBalanceAndCBA=true, audit=FULL
    Then the response status code should be 200
    And the response should contain at most 2 Account objects, starting from the third matching account
    And each Account object should include balance, CBA, and full audit information

    @TC04
    Scenario: Search when no accounts match the search key
    Given there are no accounts in the system matching the search key "nonexistent"
    When the user sends a GET request to /1.0/kb/accounts/search/nonexistent
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC05
    Scenario: Search when the database is empty
    Given the database contains no accounts
    When the user sends a GET request to /1.0/kb/accounts/search/anykey
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC06
    Scenario: Invalid search key (malformed input)
    Given the search key contains invalid or unsupported characters (e.g., "<>*?%")
    When the user sends a GET request to /1.0/kb/accounts/search/<>*?%
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid search key

    @TC07
    Scenario: Invalid pagination parameters (negative or non-integer values)
    Given the user provides offset=-1 in the query parameters
    When the user sends a GET request to /1.0/kb/accounts/search/john?offset=-1
    Then the response status code should be 400
    And the response body should contain an error message about invalid offset

    When the user sends a GET request to /1.0/kb/accounts/search/john?limit=-5
    Then the response status code should be 400
    And the response body should contain an error message about invalid limit

    When the user sends a GET request to /1.0/kb/accounts/search/john?offset=abc
    Then the response status code should be 400
    And the response body should contain an error message about invalid offset

    When the user sends a GET request to /1.0/kb/accounts/search/john?limit=xyz
    Then the response status code should be 400
    And the response body should contain an error message about invalid limit

    @TC08
    Scenario: Invalid boolean and enum query parameters
    Given the user provides accountWithBalance=notaboolean
    When the user sends a GET request to /1.0/kb/accounts/search/john?accountWithBalance=notaboolean
    Then the response status code should be 400
    And the response body should contain an error message about invalid boolean value

    When the user sends a GET request to /1.0/kb/accounts/search/john?audit=INVALID
    Then the response status code should be 400
    And the response body should contain an error message about invalid audit value

    @TC09
    Scenario: Missing authentication token (unauthorized access)
    Given the API authentication token is missing from the request headers
    When the user sends a GET request to /1.0/kb/accounts/search/john
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC10
    Scenario: Invalid authentication token (unauthorized access)
    Given the API authentication token is invalid or expired
    When the user sends a GET request to /1.0/kb/accounts/search/john
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC11
    Scenario: System error conditions (service unavailable)
    Given the KillBill API service is down or unreachable
    When the user sends a GET request to /1.0/kb/accounts/search/john
    Then the response status code should be 503
    And the response body should indicate service unavailable

    @TC12
    Scenario: Security - SQL injection attempt in search key
    Given the search key contains SQL injection payload (e.g., "john'; DROP TABLE accounts;--")
    When the user sends a GET request to /1.0/kb/accounts/search/john'; DROP TABLE accounts;--
    Then the response status code should be 400 or 422
    And the response body should indicate invalid input or security violation
    And the database should remain unaffected

    @TC13
    Scenario: Security - XSS attempt in search key
    Given the search key contains a script tag (e.g., "<script>alert('xss')</script>")
    When the user sends a GET request to /1.0/kb/accounts/search/<script>alert('xss')</script>
    Then the response status code should be 400 or 422
    And the response body should indicate invalid input or security violation

    @TC14
    Scenario: Extra/unexpected query parameters
    Given the user provides an additional query parameter (e.g., foo=bar)
    When the user sends a GET request to /1.0/kb/accounts/search/john?foo=bar
    Then the response status code should be 200
    And the response should ignore the extra parameter and return matching accounts as normal

    @TC15
    Scenario: Large data volume (performance and pagination)
    Given the database contains 10,000+ accounts matching the search key "bulk"
    When the user sends a GET request to /1.0/kb/accounts/search/bulk with limit=1000
    Then the response status code should be 200
    And the response body should contain at most 1000 Account objects
    And the response time should be less than 2 seconds

    When the user sends concurrent GET requests to /1.0/kb/accounts/search/bulk from 20 clients
    Then all responses should have status code 200
    And the system should maintain acceptable response times and resource utilization

    @TC16
    Scenario: Timeout and long-running operation
    Given the search operation is expected to take a long time (e.g., due to slow database)
    When the user sends a GET request to /1.0/kb/accounts/search/slow
    Then the response status code should be 504 if the request times out
    Or the response status code should be 200 if the operation completes within the timeout threshold

    @TC17
    Scenario: Regression - previously fixed bug for empty searchKey
    Given the user sends a GET request to /1.0/kb/accounts/search/ with an empty searchKey
    When the request is processed
    Then the response status code should be 400
    And the response body should indicate that searchKey is required

    @TC18
    Scenario: Regression - backward compatibility with older clients
    Given the user sends a GET request to /1.0/kb/accounts/search/john with only the searchKey path parameter
    When the request is processed
    Then the response status code should be 200
    And the response body should be a JSON array of Account objects matching the search key

    @TC19
    Scenario: Integration - dependent service unavailable
    Given the account balance or audit information is fetched from a dependent service that is currently unavailable
    When the user sends a GET request to /1.0/kb/accounts/search/john with accountWithBalance=true or audit=FULL
    Then the response status code should be 502 or 503
    And the response body should indicate dependency failure

    @TC20
    Scenario: Accessibility - response payload structure
    Given the user is visually impaired and uses a screen reader
    When the response is returned for /1.0/kb/accounts/search/john
    Then the JSON structure should use clear, descriptive field names
    And all fields should be accessible and documented for assistive technologies