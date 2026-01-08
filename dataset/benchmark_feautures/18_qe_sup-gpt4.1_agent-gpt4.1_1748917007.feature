Feature: List accounts with pagination via GET /1.0/kb/accounts/pagination
As a KillBill API user,
I want to retrieve a paginated list of accounts with optional balance, CBA, and audit information,
so that I can efficiently browse and analyze account data.

  Background:
  Given the KillBill API is running and accessible
  And valid authentication credentials are available
  And the database is seeded with a diverse set of accounts (including accounts with and without balances and CBA)
  And the API endpoint /1.0/kb/accounts/pagination is available

    @TC01
    Scenario: Successful retrieval of accounts with default parameters
    Given the database contains multiple accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with no query parameters
    Then the response status code should be 200
    And the response body should be a JSON array of Account objects (up to the default limit of 100)
    And each Account object should not include balance or CBA fields
    And audit information should not be present (audit = NONE)

    @TC02
    Scenario: Successful retrieval with offset and limit parameters
    Given the database contains more than 100 accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with offset=50 and limit=25
    Then the response status code should be 200
    And the response body should be a JSON array of up to 25 Account objects, starting from the 51st account

    @TC03
    Scenario: Retrieval with accountWithBalance=true
    Given the database contains accounts with and without balances
    When the user sends a GET request to /1.0/kb/accounts/pagination with accountWithBalance=true
    Then the response status code should be 200
    And each Account object in the response should include a balance field
    And CBA field should not be present

    @TC04
    Scenario: Retrieval with accountWithBalanceAndCBA=true
    Given the database contains accounts with and without CBA
    When the user sends a GET request to /1.0/kb/accounts/pagination with accountWithBalanceAndCBA=true
    Then the response status code should be 200
    And each Account object in the response should include both balance and CBA fields

    @TC05
    Scenario: Retrieval with audit=FULL
    Given the database contains accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with audit=FULL
    Then the response status code should be 200
    And each Account object should include full audit information

    @TC06
    Scenario: Retrieval with audit=MINIMAL
    Given the database contains accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with audit=MINIMAL
    Then the response status code should be 200
    And each Account object should include minimal audit information

    @TC07
    Scenario: Retrieval with all parameters combined
    Given the database contains accounts with balances and CBA
    When the user sends a GET request to /1.0/kb/accounts/pagination with offset=10, limit=5, accountWithBalance=true, accountWithBalanceAndCBA=true, and audit=FULL
    Then the response status code should be 200
    And the response body should be a JSON array of up to 5 Account objects starting from the 11th account
    And each Account object should include balance and CBA fields
    And each Account object should include full audit information

    @TC08
    Scenario: Retrieval when no accounts exist
    Given the database contains no accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC09
    Scenario: Retrieval with offset beyond available data
    Given the database contains 10 accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with offset=20
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC10
    Scenario: Retrieval with invalid offset value (negative number)
    Given the user provides offset=-5
    When the user sends a GET request to /1.0/kb/accounts/pagination with offset=-5
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid offset

    @TC11
    Scenario: Retrieval with invalid limit value (zero)
    Given the user provides limit=0
    When the user sends a GET request to /1.0/kb/accounts/pagination with limit=0
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid limit

    @TC12
    Scenario: Retrieval with invalid limit value (negative number)
    Given the user provides limit=-10
    When the user sends a GET request to /1.0/kb/accounts/pagination with limit=-10
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid limit

    @TC13
    Scenario: Retrieval with invalid audit parameter
    Given the user provides audit=INVALID
    When the user sends a GET request to /1.0/kb/accounts/pagination with audit=INVALID
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid audit value

    @TC14
    Scenario: Retrieval with unsupported extra parameter
    Given the user provides an unsupported query parameter foo=bar
    When the user sends a GET request to /1.0/kb/accounts/pagination with foo=bar
    Then the response status code should be 200
    And the response body should be a JSON array of Account objects (ignoring the extra parameter)

    @TC15
    Scenario: Unauthorized access attempt
    Given the user omits authentication credentials
    When the user sends a GET request to /1.0/kb/accounts/pagination
    Then the response status code should be 401
    And the response body should contain an authentication error message

    @TC16
    Scenario: Access with invalid authentication token
    Given the user provides an invalid authentication token
    When the user sends a GET request to /1.0/kb/accounts/pagination
    Then the response status code should be 401
    And the response body should contain an authentication error message

    @TC17
    Scenario: Service unavailable error
    Given the KillBill API service is down
    When the user sends a GET request to /1.0/kb/accounts/pagination
    Then the response status code should be 503
    And the response body should contain a service unavailable error message

    @TC18
    Scenario: Simulate network timeout
    Given the network connection is disrupted during the request
    When the user sends a GET request to /1.0/kb/accounts/pagination
    Then the request should time out
    And the user should receive a timeout error message

    @TC19
    Scenario: Large data volume retrieval (performance)
    Given the database contains 10,000 accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with limit=1000
    Then the response status code should be 200
    And the response body should be a JSON array of up to 1000 Account objects
    And the response time should be within acceptable performance thresholds (e.g., <2 seconds)

    @TC20
    Scenario: Concurrent requests for pagination
    Given the database contains sufficient accounts
    When multiple users send GET requests to /1.0/kb/accounts/pagination concurrently with different offsets and limits
    Then each response status code should be 200
    And each response should return the correct subset of Account objects without data leakage or overlap

    @TC21
    Scenario: Regression - previously fixed bug: offset+limit boundary
    Given the database contains exactly 100 accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with offset=95 and limit=10
    Then the response status code should be 200
    And the response body should be a JSON array of 5 Account objects (accounts 96-100)

    @TC22
    Scenario: Regression - backward compatibility
    Given the API has previously supported pagination with offset and limit
    When the user sends a GET request to /1.0/kb/accounts/pagination with only offset and limit
    Then the response status code should be 200
    And the response body should match the previous API contract for Account objects

    @TC23
    Scenario: Security - SQL injection attempt in parameters
    Given the user provides offset='1 OR 1=1' and limit='100; DROP TABLE accounts;'
    When the user sends a GET request to /1.0/kb/accounts/pagination with these values
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid parameter values
    And no data or schema should be compromised

    @TC24
    Scenario: Security - XSS attempt in parameters
    Given the user provides audit='<script>alert(1)</script>'
    When the user sends a GET request to /1.0/kb/accounts/pagination with audit='<script>alert(1)</script>'
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid audit value
    And no script should be executed or reflected in the response

    @TC25
    Scenario: Edge case - partial input (only one parameter provided)
    Given the database contains accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with only limit=10
    Then the response status code should be 200
    And the response body should be a JSON array of up to 10 Account objects

    @TC26
    Scenario: Edge case - all boolean parameters set to true
    Given the database contains accounts with balances and CBA
    When the user sends a GET request to /1.0/kb/accounts/pagination with accountWithBalance=true and accountWithBalanceAndCBA=true
    Then the response status code should be 200
    And each Account object should include both balance and CBA fields

    @TC27
    Scenario: Edge case - maximum allowed values for offset and limit
    Given the system defines maximum allowed values for offset and limit (e.g., offset=9223372036854775807, limit=10000)
    When the user sends a GET request to /1.0/kb/accounts/pagination with these values
    Then the response status code should be 200 or 400 depending on system constraints
    And the response body should reflect appropriate handling (empty array or error message)

    @TC28
    Scenario: Edge case - minimum allowed values for offset and limit
    Given the system defines minimum allowed values for offset=0 and limit=1
    When the user sends a GET request to /1.0/kb/accounts/pagination with offset=0 and limit=1
    Then the response status code should be 200
    And the response body should be a JSON array with at most 1 Account object

    @TC29
    Scenario: Edge case - extra parameters provided
    Given the user provides extra parameters not defined in the API spec
    When the user sends a GET request to /1.0/kb/accounts/pagination with limit=10 and foo=bar
    Then the response status code should be 200
    And the response body should be a JSON array of up to 10 Account objects
    And the extra parameter should be ignored

    @TC30
    Scenario: State variation - partially populated database
    Given the database contains only 3 accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with limit=10
    Then the response status code should be 200
    And the response body should be a JSON array of 3 Account objects

    @TC31
    Scenario: State variation - degraded system performance
    Given the system is under heavy load
    When the user sends a GET request to /1.0/kb/accounts/pagination
    Then the response status code should be 200
    And the response time should not exceed acceptable thresholds (e.g., <5 seconds)

    @TC32
    Scenario: Integration - dependency service unavailable
    Given the account balance service is unavailable
    When the user sends a GET request to /1.0/kb/accounts/pagination with accountWithBalance=true
    Then the response status code should be 503
    And the response body should contain an error message indicating dependency failure

    @TC33
    Scenario: Integration - data consistency with audit log
    Given the audit log service is available
    When the user sends a GET request to /1.0/kb/accounts/pagination with audit=FULL
    Then the audit information in each Account object should match the audit log records

    @TC34
    Scenario: Accessibility - response structure is compatible with screen readers
    Given the user relies on assistive technology
    When the user receives the JSON response from /1.0/kb/accounts/pagination
    Then the response structure should be valid JSON and compatible with screen readers

    @TC35
    Scenario: Accessibility - response includes descriptive error messages
    Given the user provides invalid parameters
    When the user sends a GET request to /1.0/kb/accounts/pagination
    Then the error response should include a descriptive error message and error code

    @TC36
    Scenario: Recovery from transient network error
    Given a transient network error occurs during the request
    When the user retries the GET request to /1.0/kb/accounts/pagination
    Then the response status code should be 200
    And the response body should be a JSON array of Account objects as expected

    @TC37
    Scenario: Recovery from dependency failure
    Given the account balance service was previously unavailable
    When the user retries the GET request to /1.0/kb/accounts/pagination with accountWithBalance=true after recovery
    Then the response status code should be 200
    And each Account object should include a balance field

    @TC38
    Scenario: Edge case - malformed boolean parameters
    Given the user provides accountWithBalance='notaboolean'
    When the user sends a GET request to /1.0/kb/accounts/pagination with accountWithBalance='notaboolean'
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid boolean value

    @TC39
    Scenario: Edge case - malformed integer parameters
    Given the user provides offset='abc'
    When the user sends a GET request to /1.0/kb/accounts/pagination with offset='abc'
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid integer value

    @TC40
    Scenario: Edge case - malformed request (invalid HTTP method)
    Given the user sends a POST request to /1.0/kb/accounts/pagination
    When the request is made
    Then the response status code should be 405
    And the response body should contain a method not allowed error message

    @TC41
    Scenario: Edge case - large payload in query string
    Given the user provides a very large query string in the request
    When the user sends a GET request to /1.0/kb/accounts/pagination
    Then the response status code should be 414 or 400 depending on system constraints
    And the response body should contain an appropriate error message

    @TC42
    Scenario: Edge case - simultaneous use of both accountWithBalance and accountWithBalanceAndCBA
    Given the user provides accountWithBalance=true and accountWithBalanceAndCBA=true
    When the user sends a GET request to /1.0/kb/accounts/pagination
    Then the response status code should be 200
    And each Account object should include both balance and CBA fields

    @TC43
    Scenario: Edge case - no query parameters provided
    Given the database contains accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with no query parameters
    Then the response status code should be 200
    And the response body should be a JSON array of Account objects (up to the default limit)

    @TC44
    Scenario: Edge case - boolean parameters set to false
    Given the database contains accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with accountWithBalance=false and accountWithBalanceAndCBA=false
    Then the response status code should be 200
    And the response body should be a JSON array of Account objects without balance or CBA fields

    @TC45
    Scenario: Edge case - audit parameter not provided
    Given the database contains accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination without audit parameter
    Then the response status code should be 200
    And the response body should not include audit information

    @TC46
    Scenario: Edge case - limit exceeds total number of accounts
    Given the database contains 5 accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with limit=10
    Then the response status code should be 200
    And the response body should be a JSON array of 5 Account objects

    @TC47
    Scenario: Edge case - offset is zero
    Given the database contains accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with offset=0
    Then the response status code should be 200
    And the response body should be a JSON array of Account objects (up to the default or provided limit)

    @TC48
    Scenario: Edge case - limit is maximum allowed value
    Given the system allows a maximum limit of 10000
    When the user sends a GET request to /1.0/kb/accounts/pagination with limit=10000
    Then the response status code should be 200
    And the response body should be a JSON array of up to 10000 Account objects

    @TC49
    Scenario: Edge case - offset is maximum allowed value
    Given the system allows a maximum offset of 9223372036854775807
    When the user sends a GET request to /1.0/kb/accounts/pagination with offset=9223372036854775807
    Then the response status code should be 200 or 400 depending on system constraints
    And the response body should reflect appropriate handling (empty array or error message)

    @TC50
    Scenario: Edge case - all parameters omitted
    Given the database contains accounts
    When the user sends a GET request to /1.0/kb/accounts/pagination with no parameters
    Then the response status code should be 200
    And the response body should be a JSON array of Account objects (up to the default limit)