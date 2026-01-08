Feature: Create Account API (POST /1.0/kb/accounts)
As a KillBill API user,
I want to create a new account via the API,
so that I can manage accounts programmatically.

  Background:
  Given the KillBill API server is running and accessible
  And the database is seeded with no conflicting accounts
  And valid authentication credentials are available
  And the API endpoint POST /1.0/kb/accounts is reachable
  And the Account object schema is known

    @TC01
    Scenario: Successful account creation with minimum required fields
    Given a valid Account object with all required fields
    And a valid X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 201
    And the response body should contain the created Account object in JSON format
    And the Location header should contain the URL of the new account

    @TC02
    Scenario: Successful account creation with all optional headers and fields
    Given a valid Account object with all required and optional fields
    And valid X-Killbill-CreatedBy, X-Killbill-Reason, and X-Killbill-Comment headers are provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 201
    And the response body should contain the created Account object in JSON format
    And the Location header should contain the URL of the new account

    @TC03
    Scenario: Successful account creation with only required header
    Given a valid Account object with all required fields
    And only the X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 201
    And the response body should contain the created Account object in JSON format
    And the Location header should contain the URL of the new account

    @TC04
    Scenario: Account creation with missing required header
    Given a valid Account object with all required fields
    And the X-Killbill-CreatedBy header is missing
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 400
    And the response body should indicate the missing required header error

    @TC05
    Scenario: Account creation with invalid Account object (malformed JSON)
    Given a malformed JSON as the request body
    And a valid X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 400
    And the response body should indicate invalid account data

    @TC06
    Scenario: Account creation with missing required Account object fields
    Given an Account object missing required fields
    And a valid X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 400
    And the response body should indicate invalid account data

    @TC07
    Scenario: Account creation with extra, unsupported fields in Account object
    Given a valid Account object with extra unsupported fields
    And a valid X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 201
    And the response body should ignore extra fields and return the created Account object

    @TC08
    Scenario: Account creation with invalid header value types
    Given a valid Account object
    And X-Killbill-CreatedBy header is an integer instead of a string
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 400
    And the response body should indicate header validation error

    @TC09
    Scenario: Account creation with unauthorized access
    Given a valid Account object
    And a missing or invalid authentication token
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 401
    And the response body should indicate unauthorized access

    @TC10
    Scenario: Account creation when system is down (dependency failure)
    Given a valid Account object
    And a valid X-Killbill-CreatedBy header is provided
    And the database is unavailable
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 503
    And the response body should indicate service unavailable

    @TC11
    Scenario: Account creation with large payload (boundary test)
    Given a valid Account object with maximum allowed field sizes
    And a valid X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 201
    And the response body should contain the created Account object

    @TC12
    Scenario: Account creation with empty payload
    Given an empty request body
    And a valid X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 400
    And the response body should indicate invalid account data

    @TC13
    Scenario: Account creation with duplicate account data
    Given an Account object with data identical to an existing account
    And a valid X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 201 or 409 depending on duplicate handling policy
    And the response body should reflect the system's duplicate handling (created or error)

    @TC14
    Scenario: Account creation with slow network (timeout)
    Given a valid Account object
    And a valid X-Killbill-CreatedBy header is provided
    And the network is artificially delayed beyond timeout threshold
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 504
    And the response body should indicate a timeout error

    @TC15
    Scenario: Account creation with XSS or injection attack in fields
    Given an Account object with script tags or SQL injection in text fields
    And a valid X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 400 or sanitized response
    And the response body should not execute or reflect the malicious input

    @TC16
    Scenario: Account creation with partial input (missing optional fields)
    Given a valid Account object with only required fields
    And a valid X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 201
    And the response body should contain the created Account object

    @TC17
    Scenario: Account creation with additional, unexpected headers
    Given a valid Account object
    And a valid X-Killbill-CreatedBy header is provided
    And additional unexpected headers are sent
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 201
    And the response body should contain the created Account object

    @TC18
    Scenario: Performance test - multiple concurrent account creations
    Given multiple valid Account objects
    And valid X-Killbill-CreatedBy headers for each
    When multiple POST requests are sent concurrently to /1.0/kb/accounts
    Then all requests should return 201 within the acceptable response time threshold
    And each response body should contain the created Account object

    @TC19
    Scenario: Regression - previously fixed issue with account creation (e.g., field truncation)
    Given a valid Account object with previously problematic field values
    And a valid X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 201
    And the response body should contain the correct, untruncated Account object

    @TC20
    Scenario: Integration - verify created account is retrievable
    Given a valid Account object
    And a valid X-Killbill-CreatedBy header is provided
    When the user sends a POST request to /1.0/kb/accounts
    Then the response status should be 201
    And the Location header is extracted
    When the user sends a GET request to the Location URL
    Then the response status should be 200
    And the response body should match the originally created Account object