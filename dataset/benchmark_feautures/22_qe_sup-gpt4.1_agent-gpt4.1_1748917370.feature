Feature: Rebalance Account CBA via PUT /1.0/kb/accounts/{accountId}/cbaRebalancing
As a KillBill API user,
I want to rebalance an account's Credit Balance Adjustment (CBA),
so that the account's CBA is correctly recalculated and updated.

  Background:
  Given the KillBill API is available
  And the database is seeded with accounts having various CBA states (zero, positive, negative, large, small)
  And the user has a valid authentication token
  And the API base URL is configured
  And the X-Killbill-CreatedBy header is set to a valid username

    @TC01
    Scenario: Successful CBA rebalancing with required headers
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is provided with value "qa_user"
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 204
    And the account's CBA should be rebalanced in the backend

    @TC02
    Scenario: Successful CBA rebalancing with all optional headers
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is provided with value "qa_user"
    And the X-Killbill-Reason header is provided with value "test_reason"
    And the X-Killbill-Comment header is provided with value "test_comment"
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 204
    And the account's CBA should be rebalanced in the backend

    @TC03
    Scenario: Successful CBA rebalancing with only required header
    Given an existing account with a valid accountId in the system
    And only the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 204
    And the account's CBA should be rebalanced in the backend

    @TC04
    Scenario: CBA rebalancing with account having zero CBA
    Given an existing account with a valid accountId and zero CBA
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 204
    And the account's CBA should remain zero

    @TC05
    Scenario: CBA rebalancing with account having negative CBA
    Given an existing account with a valid accountId and negative CBA
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 204
    And the account's CBA should be rebalanced to the correct value

    @TC06
    Scenario: CBA rebalancing with account having large positive CBA
    Given an existing account with a valid accountId and a large positive CBA
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 204
    And the account's CBA should be rebalanced to the correct value

    @TC07
    Scenario: CBA rebalancing with account having multiple transactions
    Given an existing account with a valid accountId and multiple CBA-impacting transactions
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 204
    And the account's CBA should be rebalanced according to all transactions

    @TC08
    Scenario: CBA rebalancing when account does not exist
    Given an accountId that does not exist in the system
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 400
    And the response body should indicate an invalid account ID error

    @TC09
    Scenario: CBA rebalancing with invalid accountId format
    Given an accountId with an invalid format (not matching uuid pattern)
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 400
    And the response body should indicate an invalid account ID error

    @TC10
    Scenario: CBA rebalancing with missing X-Killbill-CreatedBy header
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is missing
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 400
    And the response body should indicate the missing required header

    @TC11
    Scenario: CBA rebalancing with empty X-Killbill-CreatedBy header
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is empty
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 400
    And the response body should indicate the missing required header

    @TC12
    Scenario: CBA rebalancing with extra, unsupported headers
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is provided
    And an extra, unsupported header is included in the request
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 204
    And the account's CBA should be rebalanced in the backend

    @TC13
    Scenario: CBA rebalancing with network interruption (transient error)
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing and a network error occurs
    Then the client should retry the request as per retry policy
    And the API should respond with HTTP status 204 upon successful retry

    @TC14
    Scenario: CBA rebalancing when KillBill service is unavailable
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing and the KillBill service is down
    Then the API should respond with HTTP status 503
    And the response body should indicate service unavailable

    @TC15
    Scenario: CBA rebalancing with malicious header values (security test)
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header contains a SQL injection payload
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 400 or 422
    And the response body should not leak internal implementation details

    @TC16
    Scenario: CBA rebalancing with very large accountId value (boundary test)
    Given an accountId with a very large string exceeding normal uuid length
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 400
    And the response body should indicate an invalid account ID error

    @TC17
    Scenario: CBA rebalancing with empty database (no accounts)
    Given the accounts database is empty
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 400
    And the response body should indicate an invalid account ID error

    @TC18
    Scenario: CBA rebalancing with high concurrency
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is provided
    When multiple concurrent PUT requests are sent to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then all requests should respond with HTTP status 204
    And the account's CBA should remain consistent and correct

    @TC19
    Scenario: Regression - previously fixed bug with CBA rebalancing for specific account state
    Given an account in a previously problematic state (e.g., partial payment, credit applied)
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 204
    And the account's CBA should be rebalanced correctly

    @TC20
    Scenario: Performance - CBA rebalancing response time under normal load
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 204 within 2 seconds

    @TC21
    Scenario: Performance - CBA rebalancing response time under peak load
    Given multiple accounts with valid accountIds in the system
    And the X-Killbill-CreatedBy header is provided
    When multiple PUT requests are sent to /1.0/kb/accounts/{accountId}/cbaRebalancing in parallel
    Then all responses should be HTTP status 204 within 5 seconds

    @TC22
    Scenario: CBA rebalancing with unsupported HTTP method
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is provided
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 405
    And the response body should indicate method not allowed

    @TC23
    Scenario: CBA rebalancing with additional unexpected parameters
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is provided
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing with unexpected query parameters
    Then the API should respond with HTTP status 204
    And the account's CBA should be rebalanced in the backend

    @TC24
    Scenario: CBA rebalancing with XSS attempt in comment header
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is provided
    And the X-Killbill-Comment header contains a script tag
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 204 or 400
    And the response body should not execute or reflect the script

    @TC25
    Scenario: CBA rebalancing with whitespace-only header values
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is whitespace only
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 400
    And the response body should indicate the missing required header

    @TC26
    Scenario: CBA rebalancing with null header values (if possible)
    Given an existing account with a valid accountId in the system
    And the X-Killbill-CreatedBy header is null
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/cbaRebalancing
    Then the API should respond with HTTP status 400
    And the response body should indicate the missing required header