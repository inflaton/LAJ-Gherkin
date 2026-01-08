Feature: Retrieve an account by ID via GET /1.0/kb/accounts/{accountId}
As a KillBill API user,
I want to retrieve an account by its ID using the GET /1.0/kb/accounts/{accountId} endpoint,
so that I can access account information, optionally including balance, CBA, and audit details.

  Background:
  Given the KillBill API is running and accessible
  And the database is seeded with accounts having diverse data (with and without balances, CBA, and audit history)
  And valid and invalid authentication tokens are available
  And the API endpoint /1.0/kb/accounts/{accountId} is reachable

    @TC01
    Scenario: Successful retrieval of an account by valid ID (default parameters)
    Given a valid accountId exists in the system
    And the request is authenticated with a valid token
    When the user sends a GET request to /1.0/kb/accounts/{accountId} with no query parameters
    Then the response status code should be 200
    And the response body should contain the Account object for the given accountId
    And the response should not include balance or CBA fields
    And the audit field should be absent or set to NONE

    @TC02
    Scenario: Successful retrieval with accountWithBalance=true
    Given a valid accountId exists with a positive balance
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalance=true
    Then the response status code should be 200
    And the response body should include the balance field for the account
    And the CBA field should be absent

    @TC03
    Scenario: Successful retrieval with accountWithBalanceAndCBA=true
    Given a valid accountId exists with a balance and CBA
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalanceAndCBA=true
    Then the response status code should be 200
    And the response body should include both balance and CBA fields

    @TC04
    Scenario: Successful retrieval with audit=FULL
    Given a valid accountId exists
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?audit=FULL
    Then the response status code should be 200
    And the response body should include audit information at FULL level

    @TC05
    Scenario: Successful retrieval with audit=MINIMAL
    Given a valid accountId exists
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?audit=MINIMAL
    Then the response status code should be 200
    And the response body should include audit information at MINIMAL level

    @TC06
    Scenario: Successful retrieval with all query parameters set
    Given a valid accountId exists with balance and CBA
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalance=true&accountWithBalanceAndCBA=true&audit=FULL
    Then the response status code should be 200
    And the response body should include balance, CBA, and FULL audit information

    @TC07
    Scenario: Retrieval when no accounts exist in the system
    Given the database contains no accounts
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId} with any accountId
    Then the response status code should be 404
    And the response body should indicate account not found

    @TC08
    Scenario: Retrieval for a non-existent accountId
    Given a random valid UUID that does not match any account in the system
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}
    Then the response status code should be 404
    And the response body should indicate account not found

    @TC09
    Scenario: Invalid accountId format (malformed UUID)
    Given an accountId with an invalid format (e.g., not a UUID)
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}
    Then the response status code should be 400
    And the response body should indicate invalid accountId

    @TC10
    Scenario: Missing authentication token
    Given a valid accountId exists
    And the request is missing authentication
    When the user sends a GET request to /1.0/kb/accounts/{accountId}
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC11
    Scenario: Invalid authentication token
    Given a valid accountId exists
    And the request uses an invalid authentication token
    When the user sends a GET request to /1.0/kb/accounts/{accountId}
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC12
    Scenario: System error (service unavailable)
    Given the KillBill API service is temporarily unavailable
    When the user sends a GET request to /1.0/kb/accounts/{accountId}
    Then the response status code should be 503
    And the response body should indicate service unavailable

    @TC13
    Scenario: Injection attack attempt in accountId
    Given the accountId contains SQL injection payload (e.g., ' OR 1=1 --)
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}
    Then the response status code should be 400
    And the response body should indicate invalid accountId
    And no sensitive information should be leaked

    @TC14
    Scenario: XSS attack attempt in accountId
    Given the accountId contains XSS payload (e.g., <script>alert(1)</script>)
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}
    Then the response status code should be 400
    And the response body should indicate invalid accountId
    And no script should be executed or returned

    @TC15
    Scenario: Extra unexpected query parameters
    Given a valid accountId exists
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?foo=bar
    Then the response status code should be 200
    And the response body should contain the Account object
    And extra parameters should be ignored

    @TC16
    Scenario: Timeout condition (long-running operation)
    Given the database is under heavy load
    And a valid accountId exists
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}
    Then the response should be received within the configured timeout threshold
    And the response status code should be 200 or 504 if timeout occurs

    @TC17
    Scenario: Large payload returned (account with many fields/transactions)
    Given a valid accountId exists with a large number of associated transactions
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalanceAndCBA=true&audit=FULL
    Then the response status code should be 200
    And the response body should include all relevant fields and transactions
    And the response size should not exceed API limits

    @TC18
    Scenario: Concurrent requests for the same accountId
    Given a valid accountId exists
    And the request is authenticated
    When multiple users send concurrent GET requests to /1.0/kb/accounts/{accountId}
    Then all responses should have status code 200
    And all response bodies should be consistent and correct

    @TC19
    Scenario: Backward compatibility with previous API clients
    Given a valid accountId exists
    And the request is made using headers from an older client version
    When the user sends a GET request to /1.0/kb/accounts/{accountId}
    Then the response status code should be 200
    And the response body should be compatible with previous Account object schema

    @TC20
    Scenario: Data consistency after dependent service degradation
    Given a valid accountId exists
    And the balance service is degraded or returns stale data
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalance=true
    Then the response status code should be 200 or 206 (partial content) as per API design
    And the response should indicate any data inconsistency or partial data

    @TC21
    Scenario: Accessibility compliance for API documentation (if UI is present)
    Given the API documentation is available via a web UI
    When a screen reader accesses the documentation for /1.0/kb/accounts/{accountId}
    Then all fields and descriptions should be accessible and compliant with WCAG standards

    @TC22
    Scenario: Regression test for previously fixed bug (e.g., accountWithBalance ignored)
    Given a valid accountId exists
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalance=true
    Then the response status code should be 200
    And the response body should include the balance field (previous bug: field missing)

    @TC23
    Scenario: Partial input for boolean query parameters
    Given a valid accountId exists
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalance=
    Then the response status code should be 400
    And the response body should indicate invalid parameter value

    @TC24
    Scenario: Minimum and maximum allowed values for audit parameter
    Given a valid accountId exists
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?audit=NONE
    Then the response status code should be 200
    And the response body should not include audit information
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?audit=FULL
    Then the response status code should be 200
    And the response body should include full audit information

    @TC25
    Scenario: Unsupported value for audit parameter
    Given a valid accountId exists
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?audit=INVALID
    Then the response status code should be 400
    And the response body should indicate invalid audit value

    @TC26
    Scenario: Recovery from transient network failure
    Given a valid accountId exists
    And the request is authenticated
    And a transient network failure occurs during the request
    When the user retries the GET request to /1.0/kb/accounts/{accountId}
    Then the response status code should be 200
    And the response body should contain the Account object

    @TC27
    Scenario: API invocation with both accountWithBalance and accountWithBalanceAndCBA set to true
    Given a valid accountId exists with balance and CBA
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalance=true&accountWithBalanceAndCBA=true
    Then the response status code should be 200
    And the response body should include both balance and CBA fields

    @TC28
    Scenario: API invocation with only accountWithBalanceAndCBA=true (accountWithBalance not set)
    Given a valid accountId exists with balance and CBA
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalanceAndCBA=true
    Then the response status code should be 200
    And the response body should include both balance and CBA fields

    @TC29
    Scenario: API invocation with only accountWithBalance=true (accountWithBalanceAndCBA not set)
    Given a valid accountId exists with balance and CBA
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalance=true
    Then the response status code should be 200
    And the response body should include only the balance field
    And the CBA field should be absent

    @TC30
    Scenario: API invocation with no query parameters (all defaults)
    Given a valid accountId exists
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}
    Then the response status code should be 200
    And the response body should include the Account object with no balance, CBA, or audit fields

    @TC31
    Scenario: API invocation with all boolean query parameters set to false
    Given a valid accountId exists with balance and CBA
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalance=false&accountWithBalanceAndCBA=false
    Then the response status code should be 200
    And the response body should not include balance or CBA fields

    @TC32
    Scenario: API invocation with both boolean query parameters set to conflicting values
    Given a valid accountId exists with balance and CBA
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalance=true&accountWithBalanceAndCBA=false
    Then the response status code should be 200
    And the response body should include only the balance field and not the CBA field

    @TC33
    Scenario: API invocation with maximum allowed query parameter combinations
    Given a valid accountId exists with balance and CBA
    And the request is authenticated
    When the user sends a GET request to /1.0/kb/accounts/{accountId}?accountWithBalance=true&accountWithBalanceAndCBA=true&audit=FULL
    Then the response status code should be 200
    And the response body should include balance, CBA, and full audit information