Feature: Retrieve account payment methods via GET /1.0/kb/accounts/{accountId}/paymentMethods
As a KillBill API user,
I want to retrieve payment methods for a specific account,
so that I can view, audit, and manage payment methods associated with the account.

  Background:
  Given the KillBill API is available at the configured baseUrl
  And the system contains a diverse set of accounts and payment methods
  And valid authentication credentials are provided in the request headers
  And the accountId used in tests is a valid UUID format

    @TC01
    Scenario: Successful retrieval of payment methods with no query parameters (happy path)
    Given an account exists with at least one active payment method
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods with only the accountId path parameter
    Then the response status code should be 200
    And the response body should be a JSON array of PaymentMethod objects for the account
    And the response should not include pluginInfo or deleted payment methods
    And the response should not include audit information

    @TC02
    Scenario: Successful retrieval with withPluginInfo=true
    Given an account exists with at least one payment method
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods?withPluginInfo=true
    Then the response status code should be 200
    And each PaymentMethod object should include pluginInfo details

    @TC03
    Scenario: Successful retrieval with includedDeleted=true
    Given an account exists with deleted payment methods
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods?includedDeleted=true
    Then the response status code should be 200
    And the response should include both active and deleted payment methods

    @TC04
    Scenario: Successful retrieval with pluginProperty parameter
    Given an account exists with payment methods
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods with pluginProperty=property1&pluginProperty=property2
    Then the response status code should be 200
    And the response should reflect any filtering or behavior changes based on pluginProperty values

    @TC05
    Scenario: Successful retrieval with audit=FULL
    Given an account exists with payment methods
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods?audit=FULL
    Then the response status code should be 200
    And each PaymentMethod object should include full audit information

    @TC06
    Scenario: Successful retrieval with audit=MINIMAL
    Given an account exists with payment methods
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods?audit=MINIMAL
    Then the response status code should be 200
    And each PaymentMethod object should include minimal audit information

    @TC07
    Scenario: Successful retrieval with all query parameters combined
    Given an account exists with active and deleted payment methods
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods?withPluginInfo=true&includedDeleted=true&pluginProperty=prop1&pluginProperty=prop2&audit=FULL
    Then the response status code should be 200
    And the response should include pluginInfo, deleted payment methods, pluginProperty effects, and full audit information

    @TC08
    Scenario: Retrieval when the account has no payment methods
    Given an account exists with no payment methods
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC09
    Scenario: Retrieval when the account does not exist
    Given the accountId does not correspond to any account in the system
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods
    Then the response status code should be 404
    And the response body should contain an error message indicating account not found

    @TC10
    Scenario: Retrieval with invalid accountId format
    Given the accountId path parameter is not a valid UUID (e.g., 'invalid-id')
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId

    @TC11
    Scenario: Retrieval with missing authentication token
    Given the request does not include a valid authentication token
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC12
    Scenario: Retrieval with unsupported audit value
    Given an account exists with payment methods
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods?audit=INVALID
    Then the response status code should be 400
    And the response body should indicate invalid audit parameter value

    @TC13
    Scenario: Retrieval with extra/unexpected query parameters
    Given an account exists with payment methods
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods?extraParam=unexpected
    Then the response status code should be 200
    And the response body should be a JSON array of PaymentMethod objects (ignoring extraParam)

    @TC14
    Scenario: Retrieval with large number of payment methods
    Given an account exists with more than 100 payment methods
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods
    Then the response status code should be 200
    And the response body should be a JSON array containing all payment methods
    And the response time should be within 2 seconds

    @TC15
    Scenario: System error during retrieval (service unavailable)
    Given the KillBill API service is temporarily unavailable
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods
    Then the response status code should be 503
    And the response body should indicate service unavailable

    @TC16
    Scenario: Network timeout during retrieval
    Given the network connection is disrupted or slow
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods
    Then the request should timeout after the configured threshold
    And the client should receive a timeout error

    @TC17
    Scenario: Security test - SQL injection attempt in accountId
    Given the accountId path parameter contains a SQL injection string (e.g., '1 OR 1=1')
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods
    Then the response status code should be 400
    And the response body should indicate invalid accountId

    @TC18
    Scenario: Security test - XSS attempt in pluginProperty
    Given the pluginProperty query parameter contains a script tag (e.g., '<script>alert(1)</script>')
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods?pluginProperty=%3Cscript%3Ealert(1)%3C%2Fscript%3E
    Then the response status code should be 400 or 422
    And the response body should indicate invalid pluginProperty value

    @TC19
    Scenario: Recovery from transient dependency failure
    Given a dependent service temporarily fails but recovers on retry
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods and retries after a short interval
    Then the initial response status code should be 503
    And upon retry, the response status code should be 200
    And the response body should be a JSON array of PaymentMethod objects

    @TC20
    Scenario: Regression - previously fixed bug for missing pluginInfo
    Given an account exists with payment methods and pluginInfo
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods?withPluginInfo=true
    Then the response status code should be 200
    And the response should include pluginInfo for all payment methods

    @TC21
    Scenario: Regression - backward compatibility with old clients (no query params)
    Given an account exists with payment methods
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods with no query parameters
    Then the response status code should be 200
    And the response body should match the previous API contract

    @TC22
    Scenario: Integration - dependent plugin service unavailable
    Given the plugin service is unavailable
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods?withPluginInfo=true
    Then the response status code should be 502 or 503
    And the response body should indicate plugin service is unavailable

    @TC23
    Scenario: State variation - partially populated database
    Given the database contains some accounts with payment methods and some without
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/paymentMethods for each account
    Then the response should return 200 with payment methods for populated accounts
    And 200 with an empty array for unpopulated accounts

    @TC24
    Scenario: Accessibility - response is readable by screen readers
    Given the API response is rendered in a UI
    When a screen reader parses the payment method data
    Then all payment method fields should be accessible and properly labeled