Feature: Refresh account payment methods via PUT /1.0/kb/accounts/{accountId}/paymentMethods/refresh
As a KillBill API user,
I want to refresh payment methods for a specific account,
so that the payment methods are updated, potentially by contacting an external gateway.

  Background:
  Given the KillBill API is running and accessible
  And the database contains accounts with diverse payment method states
  And I have a valid authentication token if required
  And the external payment gateway is available or appropriately mocked
  And the following headers are set for all requests:
    | Header                   | Value                |
    | X-Killbill-CreatedBy     | <valid_user>         |
    | X-Killbill-Reason        | <optional_reason>    |
    | X-Killbill-Comment       | <optional_comment>   |

  @TC01
  Scenario: Successful refresh with only required parameters
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set
    Then the response status code should be 204
    And the account's payment methods should be refreshed in the backend

  @TC02
  Scenario: Successful refresh with pluginName parameter
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set and query parameter pluginName=<valid_plugin>
    Then the response status code should be 204
    And the payment methods should be refreshed using the specified plugin

  @TC03
  Scenario: Successful refresh with pluginProperty parameter (single value)
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set and query parameter pluginProperty=<property1>
    Then the response status code should be 204
    And the payment methods should be refreshed with the specified plugin property

  @TC04
  Scenario: Successful refresh with multiple pluginProperty values
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set and query parameters pluginProperty=<property1>&pluginProperty=<property2>
    Then the response status code should be 204
    And the payment methods should be refreshed with all specified plugin properties

  @TC05
  Scenario: Successful refresh with all optional headers provided
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with headers X-Killbill-CreatedBy, X-Killbill-Reason, and X-Killbill-Comment set
    Then the response status code should be 204

  @TC06
  Scenario: Successful refresh when no payment methods exist for the account
    Given an existing account with ID <valid_accountId> and no payment methods
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set
    Then the response status code should be 204
    And the system should not fail or return an error

  @TC07
  Scenario: Successful refresh with large number of pluginProperty values
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set and many pluginProperty values
    Then the response status code should be 204
    And the system should process all plugin properties correctly

  @TC08
  Scenario: Error when invalid accountId format is provided
    Given an accountId value <invalid_accountId> that does not match the UUID pattern
    When I send a PUT request to /1.0/kb/accounts/<invalid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId format

  @TC09
  Scenario: Error when non-existent accountId is provided
    Given an accountId value <nonexistent_accountId> that does not exist in the system
    When I send a PUT request to /1.0/kb/accounts/<nonexistent_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set
    Then the response status code should be 404
    And the response body should contain an error message indicating account not found

  @TC10
  Scenario: Error when X-Killbill-CreatedBy header is missing
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh without the X-Killbill-CreatedBy header
    Then the response status code should be 400 or 401
    And the response body should indicate the missing required header

  @TC11
  Scenario: Error with unsupported pluginName value
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set and pluginName=<unsupported_plugin>
    Then the response status code should be 400
    And the response body should indicate an unsupported plugin

  @TC12
  Scenario: Error with malformed pluginProperty value
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set and pluginProperty=<malformed_value>
    Then the response status code should be 400
    And the response body should indicate invalid pluginProperty

  @TC13
  Scenario: Error when external gateway is unavailable
    Given an existing account with ID <valid_accountId> and the external gateway is down
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set
    Then the response status code should be 502 or 503
    And the response body should indicate gateway or dependency failure

  @TC14
  Scenario: Error when system is under degraded performance
    Given an existing account with ID <valid_accountId> and the system is under heavy load
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set
    Then the response time should not exceed the acceptable threshold
    And the request should still return 204 if successful

  @TC15
  Scenario: Unauthorized access attempt
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with an invalid or missing authentication token
    Then the response status code should be 401
    And the response body should indicate unauthorized access

  @TC16
  Scenario: Security - SQL injection attempt in pluginName
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with pluginName set to a malicious SQL string
    Then the response status code should be 400 or 422
    And the system should not execute any injected SQL

  @TC17
  Scenario: Security - XSS attempt in pluginProperty
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with pluginProperty set to a script tag
    Then the response status code should be 400 or 422
    And the system should sanitize or reject the input

  @TC18
  Scenario: Edge case - Extra unexpected query parameters
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set and extra query parameter foo=bar
    Then the response status code should be 204 or 400
    And the system should ignore or properly handle extra parameters

  @TC19
  Scenario: Edge case - Very large accountId value
    Given an accountId value <very_large_accountId> exceeding expected length
    When I send a PUT request to /1.0/kb/accounts/<very_large_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set
    Then the response status code should be 400
    And the response body should indicate invalid accountId

  @TC20
  Scenario: Edge case - Timeout due to long-running operation
    Given an existing account with ID <valid_accountId> and a slow external gateway
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set
    Then the response should timeout if the operation exceeds the configured timeout threshold
    And the response status code should be 504

  @TC21
  Scenario: Regression - Previously fixed issue with pluginProperty encoding
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with pluginProperty containing special characters
    Then the response status code should be 204
    And the pluginProperty should be correctly handled and encoded

  @TC22
  Scenario: Regression - Backward compatibility with older clients
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh using only required parameters as older clients would
    Then the response status code should be 204
    And the operation should succeed as expected

  @TC23
  Scenario: Performance - Multiple concurrent refresh requests
    Given multiple concurrent PUT requests to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh
    When the requests are processed
    Then all should complete within the acceptable response time
    And the system should maintain data integrity

  @TC24
  Scenario: Performance - Large payloads in pluginProperty
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with pluginProperty values approaching size limits
    Then the response status code should be 204 or 413
    And the system should handle or reject large payloads gracefully

  @TC25
  Scenario: Integration - Plugin service unavailable
    Given an existing account with ID <valid_accountId> and the specified plugin service is down
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with pluginName=<valid_plugin>
    Then the response status code should be 502 or 503
    And the response body should indicate plugin service failure

  @TC26
  Scenario: Integration - Data consistency after refresh
    Given an existing account with ID <valid_accountId>
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set
    Then the refreshed payment methods should be consistent across all dependent systems

  @TC27
  Scenario: State variation - Empty database
    Given the database contains no accounts
    When I send a PUT request to /1.0/kb/accounts/<any_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set
    Then the response status code should be 404
    And the response body should indicate account not found

  @TC28
  Scenario: State variation - Partially populated database
    Given the database contains some accounts with and without payment methods
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh with header X-Killbill-CreatedBy set
    Then the response status code should be 204

  @TC29
  Scenario: State variation - Degraded system performance
    Given the system is experiencing high CPU or memory usage
    When I send a PUT request to /1.0/kb/accounts/<valid_accountId>/paymentMethods/refresh
    Then the response should still complete within the acceptable threshold or provide a clear error if not

  @TC30
  Scenario: Accessibility - API documentation and error messages
    Given a user with assistive technology needs
    When reviewing API documentation and error responses
    Then all responses and documentation should be clear, descriptive, and accessible