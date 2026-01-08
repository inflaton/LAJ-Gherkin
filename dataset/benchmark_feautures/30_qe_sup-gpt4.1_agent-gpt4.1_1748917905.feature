Feature: Retrieve account payments via GET /1.0/kb/accounts/{accountId}/payments
As a KillBill API user,
I want to retrieve payments for a specific account using the GET /1.0/kb/accounts/{accountId}/payments endpoint,
so that I can view all payments (and optionally payment attempts and plugin info) for that account.

  Background:
  Given the KillBill API server is running and accessible
  And the database contains accounts with diverse payment histories (including accounts with no payments, some payments, and many payments)
  And valid authentication tokens are set in the request headers
  And the API endpoint /1.0/kb/accounts/{accountId}/payments is available

    @TC01
    Scenario: Successful retrieval of payments with only required path parameter
    Given an existing account with at least one payment and a valid accountId
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments without any query parameters
    Then the response status should be 200
    And the response body should be a JSON array of Payment objects for the account
    And each Payment object should contain the expected fields as per the Payment definition

    @TC02
    Scenario: Retrieve payments with withAttempts=true
    Given an account with multiple payments and at least one payment attempt per payment
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?withAttempts=true
    Then the response status should be 200
    And each Payment object in the response should include a non-empty paymentAttempts array

    @TC03
    Scenario: Retrieve payments with withPluginInfo=true
    Given an account with payments processed by plugins
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?withPluginInfo=true
    Then the response status should be 200
    And each Payment object should include a pluginInfo field with plugin-specific details

    @TC04
    Scenario: Retrieve payments with pluginProperty filter
    Given an account with payments and specific plugin properties set
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?pluginProperty=prop1&pluginProperty=prop2
    Then the response status should be 200
    And the response should include only payments matching the provided plugin properties if applicable

    @TC05
    Scenario: Retrieve payments with audit=FULL
    Given an account with payments
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?audit=FULL
    Then the response status should be 200
    And each Payment object should include full audit information

    @TC06
    Scenario: Retrieve payments with audit=MINIMAL
    Given an account with payments
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?audit=MINIMAL
    Then the response status should be 200
    And each Payment object should include minimal audit information

    @TC07
    Scenario: Retrieve payments with all query parameters combined
    Given an account with payments, payment attempts, and plugin info
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?withAttempts=true&withPluginInfo=true&pluginProperty=prop1&audit=FULL
    Then the response status should be 200
    And each Payment object should include paymentAttempts, pluginInfo, and full audit information
    And the response should include only payments matching the plugin properties if applicable

    @TC08
    Scenario: Retrieve payments for an account with no payments
    Given an existing accountId for an account with no payments
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments
    Then the response status should be 200
    And the response body should be an empty JSON array

    @TC09
    Scenario: Retrieve payments for a non-existent account
    Given a valid UUID format accountId that does not exist in the system
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments
    Then the response status should be 200
    And the response body should be an empty JSON array

    @TC10
    Scenario: Retrieve payments with invalid accountId format
    Given an accountId that does not match the required UUID pattern
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments
    Then the response status should be 400
    And the response body should contain an appropriate error message indicating invalid accountId

    @TC11
    Scenario: Retrieve payments with missing authentication token
    Given a valid accountId and no authentication token in the request headers
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments
    Then the response status should be 401
    And the response body should contain an authentication error message

    @TC12
    Scenario: Retrieve payments with expired or invalid authentication token
    Given a valid accountId and an expired or invalid authentication token in the request headers
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments
    Then the response status should be 401
    And the response body should contain an authentication error message

    @TC13
    Scenario: Retrieve payments when the KillBill service is unavailable
    Given a valid accountId and the KillBill service is down
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments
    Then the response status should be 503
    And the response body should contain a service unavailable error message

    @TC14
    Scenario: Retrieve payments with extra unsupported query parameters
    Given a valid accountId
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?foo=bar
    Then the response status should be 200
    And the response body should be a JSON array of Payment objects (ignoring unsupported parameters)

    @TC15
    Scenario: Retrieve payments with large data volume
    Given an account with a large number of payments (e.g., 10,000+ payments)
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments
    Then the response status should be 200
    And the response body should be a JSON array with all payments
    And the response time should be within acceptable performance thresholds (e.g., < 2 seconds)

    @TC16
    Scenario: Retrieve payments with maximum allowed pluginProperty values
    Given an account with payments
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments with the maximum number of pluginProperty query parameters allowed
    Then the response status should be 200
    And the response should include payments matching the plugin properties if applicable

    @TC17
    Scenario: Retrieve payments with partial or malformed pluginProperty values
    Given an account with payments
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?pluginProperty=
    Then the response status should be 200
    And the response should not fail and should return payments as per default behavior

    @TC18
    Scenario: Retrieve payments with unsupported audit value
    Given an account with payments
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?audit=INVALID
    Then the response status should be 400
    And the response body should contain an appropriate error message indicating invalid audit value

    @TC19
    Scenario: Retrieve payments with XSS or injection attempt in pluginProperty
    Given an account with payments
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?pluginProperty=<script>alert(1)</script>
    Then the response status should be 400 or 422
    And the response body should contain an error message indicating invalid input
    And the system should not execute any injected code

    @TC20
    Scenario: Retrieve payments with network timeout
    Given an account with payments and the network is experiencing high latency
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments
    Then the response should timeout after the configured threshold
    And the client should receive a timeout error

    @TC21
    Scenario: Regression - previously fixed bug: payments not returned when withAttempts=false
    Given an account with payments and payment attempts
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?withAttempts=false
    Then the response status should be 200
    And the response body should be a JSON array of Payment objects without paymentAttempts field

    @TC22
    Scenario: Regression - backward compatibility with older clients omitting optional parameters
    Given an account with payments
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments without any optional query parameters
    Then the response status should be 200
    And the response body should be a JSON array of Payment objects

    @TC23
    Scenario: Integration - dependent plugin service is unavailable
    Given an account with payments and withPluginInfo=true
    And the dependent plugin service is down
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments?withPluginInfo=true
    Then the response status should be 200
    And the pluginInfo field for each Payment object should be null or indicate plugin info is unavailable

    @TC24
    Scenario: Performance - concurrent requests for the same account
    Given an account with payments
    When multiple clients send concurrent GET requests to /1.0/kb/accounts/{accountId}/payments
    Then all responses should have status 200
    And response times should remain within acceptable thresholds

    @TC25
    Scenario: State variation - partially populated database
    Given an account with only some payment fields populated (e.g., missing optional fields)
    When I send a GET request to /1.0/kb/accounts/{accountId}/payments
    Then the response status should be 200
    And the response body should include Payment objects with null or missing optional fields as appropriate