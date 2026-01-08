Feature: Retrieve account invoice payments via GET /1.0/kb/accounts/{accountId}/invoicePayments
As a KillBill API user,
I want to retrieve invoice payments for a specific account,
so that I can view payment history, attempts, and plugin information as needed.

  Background:
    Given the KillBill API is available at the configured baseUrl
    And a valid authentication token is provided in the request headers
    And the system contains accounts with diverse invoice payment data
    And the API endpoint /1.0/kb/accounts/{accountId}/invoicePayments is accessible
    And the response format is application/json

  @TC01
  Scenario: Successful retrieval of invoice payments with only required path parameter
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the account has multiple invoice payments
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments with no query parameters
    Then the API responds with HTTP status 200
    And the response body is a JSON array of InvoicePayment objects
    And each object contains required payment fields
    And pluginInfo, attempts, and audit fields are omitted or set to their default states

  @TC02
  Scenario: Successful retrieval with withPluginInfo=true
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the account has invoice payments with associated plugin info
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments?withPluginInfo=true
    Then the API responds with HTTP status 200
    And each InvoicePayment object includes pluginInfo details

  @TC03
  Scenario: Successful retrieval with withAttempts=true
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the account has invoice payments with multiple attempts
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments?withAttempts=true
    Then the API responds with HTTP status 200
    And each InvoicePayment object includes attempts information

  @TC04
  Scenario: Successful retrieval with pluginProperty filter
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the account has invoice payments with plugin properties "foo=bar" and "baz=qux"
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments?pluginProperty=foo%3Dbar&pluginProperty=baz%3Dqux
    Then the API responds with HTTP status 200
    And the response contains only InvoicePayment objects matching the specified plugin properties

  @TC05
  Scenario: Successful retrieval with audit=FULL
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments?audit=FULL
    Then the API responds with HTTP status 200
    And each InvoicePayment object includes full audit information

  @TC06
  Scenario: Successful retrieval with all query parameters combined
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the account has invoice payments with plugin info, attempts, and plugin properties "foo=bar"
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments?withPluginInfo=true&withAttempts=true&pluginProperty=foo%3Dbar&audit=MINIMAL
    Then the API responds with HTTP status 200
    And each InvoicePayment object includes pluginInfo, attempts, and minimal audit information
    And only payments matching pluginProperty "foo=bar" are returned

  @TC07
  Scenario: Successful retrieval when no invoice payments exist for the account
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the account has no invoice payments
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments
    Then the API responds with HTTP status 200
    And the response body is an empty JSON array

  @TC08
  Scenario: Error when accountId is invalid (malformed UUID)
    Given the user provides an invalid accountId "not-a-uuid"
    When the user sends a GET request to /1.0/kb/accounts/not-a-uuid/invoicePayments
    Then the API responds with HTTP status 400
    And the response contains an error message indicating invalid accountId format

  @TC09
  Scenario: Error when account does not exist (valid UUID, but not present)
    Given the user provides a non-existent accountId "00000000-0000-0000-0000-000000000000"
    When the user sends a GET request to /1.0/kb/accounts/00000000-0000-0000-0000-000000000000/invoicePayments
    Then the API responds with HTTP status 404
    And the response contains an error message indicating account not found

  @TC10
  Scenario: Error when authentication token is missing or invalid
    Given the user does not provide a valid authentication token
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments
    Then the API responds with HTTP status 401
    And the response contains an error message indicating unauthorized access

  @TC11
  Scenario: Error when system is unavailable
    Given the KillBill API service is down or unreachable
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments
    Then the API responds with HTTP status 503
    And the response contains an error message indicating service unavailable

  @TC12
  Scenario: Error when providing unsupported query parameter values
    Given the user provides an unsupported audit value "VERBOSE"
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments?audit=VERBOSE
    Then the API responds with HTTP status 400
    And the response contains an error message indicating invalid audit value

  @TC13
  Scenario: Edge case with extra unexpected query parameters
    Given the user provides an extra query parameter "foo=bar"
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments?foo=bar
    Then the API responds with HTTP status 200
    And the extra parameter is ignored
    And the response contains the default set of InvoicePayment objects

  @TC14
  Scenario: Edge case with maximum allowed pluginProperty values
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the account has invoice payments with multiple plugin properties
    When the user sends a GET request with pluginProperty repeated up to the maximum allowed number
    Then the API responds with HTTP status 200
    And the response contains only InvoicePayment objects matching all specified plugin properties

  @TC15
  Scenario: Edge case with very large number of invoice payments
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    And the account has more than 1000 invoice payments
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000/invoicePayments
    Then the API responds with HTTP status 200 within acceptable response time
    And the response body contains all invoice payments or is paginated as per API limits

  @TC16
  Scenario: Edge case with minimum allowed values (empty or missing optional parameters)
    Given an account exists with accountId "123e4567-e89b-12d3-a456-426614174000"
    When the user sends a GET request with no optional query parameters
    Then the API responds with HTTP status 200
    And the response body contains default InvoicePayment objects

  @TC17
  Scenario: State variation - partially populated database
    Given the system database contains only some accounts with invoice payments
    When the user sends a GET request for an account with payments
    Then the API responds with HTTP status 200 and returns the correct payments
    When the user sends a GET request for an account without payments
    Then the API responds with HTTP status 200 and returns an empty array

  @TC18
  Scenario: Integration - dependent service unavailable
    Given the plugin or payment attempt service is down
    When the user sends a GET request with withPluginInfo=true or withAttempts=true
    Then the API responds with HTTP status 503 or includes partial data with a warning

  @TC19
  Scenario: Regression - previously fixed issue with pluginProperty filtering
    Given a previous bug caused pluginProperty filtering to fail
    When the user sends a GET request with pluginProperty specified
    Then the API responds with HTTP status 200
    And the response contains only InvoicePayment objects matching the pluginProperty

  @TC20
  Scenario: Regression - backward compatibility with legacy clients (no query params)
    Given legacy clients do not send any query parameters
    When the user sends a GET request with only accountId
    Then the API responds with HTTP status 200
    And the response matches previous contract for InvoicePayment objects

  @TC21
  Scenario: Performance - response time under normal load
    Given the system is under normal usage conditions
    When the user sends a GET request for an account with 50 invoice payments
    Then the API responds with HTTP status 200 within 500ms

  @TC22
  Scenario: Performance - response time under peak load
    Given the system is under simulated peak load with concurrent requests
    When the user sends multiple GET requests for various accounts
    Then all responses are returned with HTTP status 200 within 2 seconds

  @TC23
  Scenario: Security - SQL injection attempt in accountId
    Given the user provides a malicious accountId "123e4567-e89b-12d3-a456-426614174000' OR '1'='1"
    When the user sends a GET request to /1.0/kb/accounts/123e4567-e89b-12d3-a456-426614174000'%20OR%20'1'='1/invoicePayments
    Then the API responds with HTTP status 400
    And the response contains an error message indicating invalid accountId

  @TC24
  Scenario: Security - XSS attempt in pluginProperty
    Given the user provides a pluginProperty value "<script>alert(1)</script>"
    When the user sends a GET request with pluginProperty=<script>alert(1)</script>
    Then the API responds with HTTP status 400 or sanitizes the input
    And the response contains an error message or sanitized data

  @TC25
  Scenario: Recovery from transient network failure
    Given a transient network failure occurs during the request
    When the user retries the GET request within a short interval
    Then the API responds with HTTP status 200 on retry
    And the response body is as expected

  @TC26
  Scenario: Accessibility - response structure for screen readers (if UI is involved)
    Given the API response is consumed by a UI component
    When the user accesses the invoice payment list with a screen reader
    Then all payment data is presented in a logical and accessible order
    And all fields have appropriate labels