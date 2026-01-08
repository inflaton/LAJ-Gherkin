Feature: Retrieve account custom fields via GET /1.0/kb/accounts/{accountId}/customFields
As a KillBill API user,
I want to retrieve custom fields for a given account,
so that I can view or process custom metadata associated with that account.

  Background:
  Given the KillBill API is running and accessible
  And the database contains multiple accounts with and without custom fields
  And valid and invalid authentication tokens are available
  And the API endpoint GET /1.0/kb/accounts/{accountId}/customFields is reachable

    @TC01
    Scenario: Successful retrieval of custom fields with valid accountId and default audit parameter
    Given an account exists with accountId "{validAccountId}"
    And the account has multiple custom fields
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields with no audit parameter
    Then the API responds with HTTP 200
    And the response body is a JSON array of CustomField objects for the account
    And the audit information is not included in the response (audit=NONE)

    @TC02
    Scenario: Successful retrieval of custom fields with audit=FULL
    Given an account exists with accountId "{validAccountId}"
    And the account has custom fields
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields with query parameter audit=FULL
    Then the API responds with HTTP 200
    And each CustomField object includes full audit information

    @TC03
    Scenario: Successful retrieval of custom fields with audit=MINIMAL
    Given an account exists with accountId "{validAccountId}"
    And the account has custom fields
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields with query parameter audit=MINIMAL
    Then the API responds with HTTP 200
    And each CustomField object includes minimal audit information

    @TC04
    Scenario: Successful retrieval when account has no custom fields
    Given an account exists with accountId "{validAccountIdNoFields}"
    And the account has no custom fields
    When the user sends a GET request to /1.0/kb/accounts/{validAccountIdNoFields}/customFields
    Then the API responds with HTTP 200
    And the response body is an empty JSON array

    @TC05
    Scenario: Retrieval with non-existent accountId
    Given an account does not exist with accountId "{nonExistentAccountId}"
    When the user sends a GET request to /1.0/kb/accounts/{nonExistentAccountId}/customFields
    Then the API responds with HTTP 200
    And the response body is an empty JSON array

    @TC06
    Scenario: Invalid accountId format
    Given the user provides an accountId "invalid-format-id" that does not match the required uuid pattern
    When the user sends a GET request to /1.0/kb/accounts/invalid-format-id/customFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid accountId

    @TC07
    Scenario: Invalid audit parameter value
    Given an account exists with accountId "{validAccountId}"
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields with query parameter audit=INVALID
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid audit value

    @TC08
    Scenario: Missing authentication token
    Given an account exists with accountId "{validAccountId}"
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields without authentication
    Then the API responds with HTTP 401
    And the response body contains an authentication error message

    @TC09
    Scenario: Invalid authentication token
    Given an account exists with accountId "{validAccountId}"
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields with an invalid authentication token
    Then the API responds with HTTP 401
    And the response body contains an authentication error message

    @TC10
    Scenario: Extra, unsupported query parameters
    Given an account exists with accountId "{validAccountId}"
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields with an extra query parameter foo=bar
    Then the API responds with HTTP 200
    And the response body is a JSON array of CustomField objects (ignoring unsupported parameters)

    @TC11
    Scenario: Service unavailable
    Given the KillBill API service is down
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields
    Then the API responds with HTTP 503
    And the response body contains a service unavailable error message

    @TC12
    Scenario: Large number of custom fields
    Given an account exists with accountId "{validAccountIdManyFields}"
    And the account has 10,000 custom fields
    When the user sends a GET request to /1.0/kb/accounts/{validAccountIdManyFields}/customFields
    Then the API responds with HTTP 200 within 2 seconds
    And the response body is a JSON array containing 10,000 CustomField objects

    @TC13
    Scenario: SQL Injection attempt in accountId
    Given the user provides an accountId "1234'; DROP TABLE accounts;--"
    When the user sends a GET request to /1.0/kb/accounts/1234'; DROP TABLE accounts;--/customFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid accountId

    @TC14
    Scenario: XSS attempt in accountId
    Given the user provides an accountId "<script>alert('xss')</script>"
    When the user sends a GET request to /1.0/kb/accounts/<script>alert('xss')</script>/customFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid accountId

    @TC15
    Scenario: Network timeout
    Given the network is experiencing high latency
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields
    Then the API responds with HTTP 504 or times out after a configured threshold

    @TC16
    Scenario: Backward compatibility with previous API clients
    Given an account exists with accountId "{validAccountId}"
    When a legacy client sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields
    Then the API responds with HTTP 200
    And the response body is compatible with previous CustomField JSON schema

    @TC17
    Scenario: Concurrent requests for the same accountId
    Given an account exists with accountId "{validAccountId}"
    When 100 concurrent GET requests are sent to /1.0/kb/accounts/{validAccountId}/customFields
    Then all requests respond with HTTP 200
    And the response bodies are consistent and correct

    @TC18
    Scenario: Integration - dependent service unavailable (e.g., database down)
    Given the database service is unavailable
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields
    Then the API responds with HTTP 500
    And the response body contains an appropriate error message

    @TC19
    Scenario: Regression - previously fixed issue with audit parameter
    Given an account exists with accountId "{validAccountId}"
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields with audit=NONE
    Then the API responds with HTTP 200
    And the response body does not include audit information

    @TC20
    Scenario: Accessibility - response is valid JSON and parsable by assistive tools
    Given an account exists with accountId "{validAccountId}"
    When the user sends a GET request to /1.0/kb/accounts/{validAccountId}/customFields
    Then the API responds with HTTP 200
    And the response body is well-formed JSON and can be parsed by standard accessibility tools