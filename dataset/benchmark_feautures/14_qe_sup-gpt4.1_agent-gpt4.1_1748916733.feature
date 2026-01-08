Feature: Retrieve Account by External Key via GET /1.0/kb/accounts
As a KillBill API user,
I want to retrieve an account by its external key using the GET /1.0/kb/accounts endpoint,
so that I can obtain account details, optionally including balance, CBA, and audit information.

  Background:
  Given the KillBill API server is running and accessible
  And the database is seeded with accounts having diverse external keys, balances, and CBA values
  And valid and invalid authentication tokens are available
  And the API endpoint /1.0/kb/accounts is reachable

    @TC01
    Scenario: Successful retrieval of account by valid external key with default parameters
    Given an account exists with externalKey "extKey123"
    And no additional query parameters are provided except externalKey
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123
    Then the response status should be 200
    And the response Content-Type should be application/json
    And the response body should contain the Account object for externalKey "extKey123"
    And the response should not include balance or CBA fields
    And the response should not include audit information

    @TC02
    Scenario: Successful retrieval with accountWithBalance=true
    Given an account exists with externalKey "extKey123"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123&accountWithBalance=true
    Then the response status should be 200
    And the response body should contain the Account object for externalKey "extKey123"
    And the response should include the balance field
    And the response should not include CBA field
    And the response should not include audit information

    @TC03
    Scenario: Successful retrieval with accountWithBalanceAndCBA=true
    Given an account exists with externalKey "extKey123"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123&accountWithBalanceAndCBA=true
    Then the response status should be 200
    And the response body should contain the Account object for externalKey "extKey123"
    And the response should include both balance and CBA fields
    And the response should not include audit information

    @TC04
    Scenario: Successful retrieval with audit=FULL
    Given an account exists with externalKey "extKey123"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123&audit=FULL
    Then the response status should be 200
    And the response body should contain the Account object for externalKey "extKey123"
    And the response should include audit information at FULL level

    @TC05
    Scenario: Successful retrieval with all optional parameters true and audit=MINIMAL
    Given an account exists with externalKey "extKey123"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123&accountWithBalance=true&accountWithBalanceAndCBA=true&audit=MINIMAL
    Then the response status should be 200
    And the response body should contain the Account object for externalKey "extKey123"
    And the response should include balance and CBA fields
    And the response should include audit information at MINIMAL level

    @TC06
    Scenario: Retrieval when no account exists for the external key
    Given no account exists with externalKey "nonexistentKey"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=nonexistentKey
    Then the response status should be 404
    And the response body should indicate account not found

    @TC07
    Scenario: Missing required parameter externalKey
    Given the externalKey parameter is missing from the request
    When the user sends a GET request to /1.0/kb/accounts
    Then the response status should be 400
    And the response body should indicate externalKey is required

    @TC08
    Scenario: Invalid externalKey value (malformed input)
    Given the externalKey parameter is set to an invalid value "!@#$%^&*()"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=!@#$%^&*()
    Then the response status should be 400
    And the response body should indicate invalid externalKey format

    @TC09
    Scenario: Invalid boolean parameters
    Given the accountWithBalance parameter is set to "notaboolean"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123&accountWithBalance=notaboolean
    Then the response status should be 400
    And the response body should indicate invalid boolean value

    @TC10
    Scenario: Invalid audit parameter value
    Given the audit parameter is set to "INVALID"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123&audit=INVALID
    Then the response status should be 400
    And the response body should indicate invalid audit value

    @TC11
    Scenario: Unauthorized access (missing authentication token)
    Given the request does not include an authentication token
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123
    Then the response status should be 401
    And the response body should indicate authentication is required

    @TC12
    Scenario: Unauthorized access (invalid authentication token)
    Given the request includes an invalid authentication token
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123
    Then the response status should be 401
    And the response body should indicate authentication failed

    @TC13
    Scenario: Service unavailable (dependency failure)
    Given the account service dependency is down
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123
    Then the response status should be 503
    And the response body should indicate service unavailable

    @TC14
    Scenario: SQL injection attempt in externalKey
    Given the externalKey parameter is set to "extKey123' OR '1'='1"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123'%20OR%20'1'='1
    Then the response status should be 400
    And the response body should indicate invalid externalKey format

    @TC15
    Scenario: XSS attempt in externalKey
    Given the externalKey parameter is set to "<script>alert('xss')</script>"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=%3Cscript%3Ealert('xss')%3C/script%3E
    Then the response status should be 400
    And the response body should indicate invalid externalKey format

    @TC16
    Scenario: Extra parameters provided
    Given an account exists with externalKey "extKey123"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123&foo=bar
    Then the response status should be 200
    And the response body should contain the Account object for externalKey "extKey123"
    And the extra parameter should be ignored

    @TC17
    Scenario: Empty database
    Given the database contains no accounts
    When the user sends a GET request to /1.0/kb/accounts?externalKey=anyKey
    Then the response status should be 404
    And the response body should indicate account not found

    @TC18
    Scenario: Large externalKey value (boundary test)
    Given an account exists with an externalKey of 255 characters
    When the user sends a GET request to /1.0/kb/accounts?externalKey=<255_char_key>
    Then the response status should be 200
    And the response body should contain the Account object for the 255 character externalKey

    @TC19
    Scenario: ExternalKey exceeds maximum allowed length
    Given the externalKey parameter is set to a value of 256 characters
    When the user sends a GET request to /1.0/kb/accounts?externalKey=<256_char_key>
    Then the response status should be 400
    And the response body should indicate externalKey exceeds maximum length

    @TC20
    Scenario: Response time under normal load
    Given an account exists with externalKey "extKey123"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123
    Then the response status should be 200
    And the response should be returned within 500ms

    @TC21
    Scenario: Response time under peak load (concurrent requests)
    Given 100 concurrent GET requests to /1.0/kb/accounts?externalKey=extKey123
    When the requests are sent simultaneously
    Then all responses should have status 200
    And each response should be returned within 1000ms

    @TC22
    Scenario: Regression - retrieval of account with previously problematic externalKey
    Given an account exists with externalKey "problematicKey!@#"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=problematicKey!@#
    Then the response status should be 200
    And the response body should contain the Account object for externalKey "problematicKey!@#"

    @TC23
    Scenario: Backward compatibility - legacy clients using only required parameter
    Given an account exists with externalKey "legacyKey"
    When a legacy client sends a GET request to /1.0/kb/accounts?externalKey=legacyKey
    Then the response status should be 200
    And the response body should contain the Account object for externalKey "legacyKey"

    @TC24
    Scenario: Integration - dependent service returns inconsistent data
    Given the account service dependency returns inconsistent data for externalKey "extKey123"
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123
    Then the response status should be 502
    And the response body should indicate bad gateway or data inconsistency

    @TC25
    Scenario: Timeout condition (long-running operation)
    Given the account service takes longer than 30 seconds to respond
    When the user sends a GET request to /1.0/kb/accounts?externalKey=extKey123
    Then the response status should be 504
    And the response body should indicate request timeout