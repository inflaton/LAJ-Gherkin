Feature: Trigger Payment Transaction via POST /1.0/kb/accounts/{accountId}/payments
As a KillBill API user,
I want to trigger a payment (authorization, purchase, or credit) for a specific account,
so that I can process payments using different methods and plugins with proper error handling.

  Background:
  Given the KillBill API is reachable at the configured baseUrl
  And the database contains accounts with valid and invalid accountIds
  And each account may have one or more payment methods (including a default)
  And available control plugins and plugin properties are configured
  And the API user has a valid authentication token
  And the "X-Killbill-CreatedBy" header is set for every request
  And the system supports the PaymentTransaction and Payment schemas

    @TC01
    Scenario: Successful payment creation with all required and optional parameters
    Given an account with id <validAccountId> exists and has a default payment method
    And a valid PaymentTransaction object with amount, currency, and transactionType is prepared
    And the request includes all headers: X-Killbill-CreatedBy, X-Killbill-Reason, X-Killbill-Comment
    And the request includes query parameters: paymentMethodId, controlPluginName, pluginProperty
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments with the PaymentTransaction in the body
    Then the response status code should be 201
    And the response body should be a valid Payment object representing the transaction
    And the Location header should contain the URL of the created payment resource
    And the response Content-Type should be application/json

    @TC02
    Scenario: Successful payment creation using default payment method and minimal headers
    Given an account with id <validAccountId> exists and has a default payment method
    And a valid PaymentTransaction object is prepared
    And only the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments with the PaymentTransaction in the body
    Then the response status code should be 201
    And the response body should be a valid Payment object
    And the Location header should contain the new payment URL

    @TC03
    Scenario: Successful payment creation with multiple control plugins and plugin properties
    Given an account with id <validAccountId> exists and has a default payment method
    And a valid PaymentTransaction object is prepared
    And the request includes multiple controlPluginName and pluginProperty query parameters
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 201
    And the Payment object should reflect the control plugins and plugin properties used

    @TC04
    Scenario: Payment creation when no data exists for the account
    Given an account with id <validAccountId> exists but has no payment methods
    And a valid PaymentTransaction object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 400
    And the response body should indicate a missing payment method error

    @TC05
    Scenario: Payment creation with large data payload
    Given an account with id <validAccountId> exists
    And a PaymentTransaction object with a large amount and maximum allowed fields is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 201 or 400 depending on system limits
    And the response should indicate success or a payload too large error

    @TC06
    Scenario: Payment creation with missing required header
    Given an account with id <validAccountId> exists
    And a valid PaymentTransaction object is prepared
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments without X-Killbill-CreatedBy header
    Then the response status code should be 400 or 401
    And the response body should indicate a missing or invalid header error

    @TC07
    Scenario: Payment creation with invalid accountId format
    Given an accountId of 'invalid-uuid' is used
    And a valid PaymentTransaction object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/invalid-uuid/payments
    Then the response status code should be 400
    And the response body should indicate an invalid accountId format

    @TC08
    Scenario: Payment creation with non-existent accountId
    Given an accountId <nonExistentAccountId> that does not exist in the system
    And a valid PaymentTransaction object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<nonExistentAccountId>/payments
    Then the response status code should be 404
    And the response body should indicate the account was not found

    @TC09
    Scenario: Payment creation with malformed request body
    Given an account with id <validAccountId> exists
    And the request body is not a valid PaymentTransaction object
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 400
    And the response body should indicate a malformed request

    @TC10
    Scenario: Payment declined by gateway
    Given an account with id <validAccountId> exists
    And a PaymentTransaction object that will be declined by the gateway is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 402
    And the response body should indicate the transaction was declined

    @TC11
    Scenario: Payment aborted by control plugin
    Given an account with id <validAccountId> exists
    And a PaymentTransaction object is prepared
    And a controlPluginName that will abort the payment is provided
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 422
    And the response body should indicate the payment was aborted by a control plugin

    @TC12
    Scenario: Payment gateway submission failure
    Given an account with id <validAccountId> exists
    And a PaymentTransaction object is prepared
    And the payment gateway is unavailable
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 502
    And the response body should indicate a gateway submission failure

    @TC13
    Scenario: Payment in unknown status due to gateway response failure
    Given an account with id <validAccountId> exists
    And a PaymentTransaction object is prepared
    And the payment gateway fails to respond
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 503
    And the response body should indicate an unknown payment status

    @TC14
    Scenario: Payment operation timed out
    Given an account with id <validAccountId> exists
    And a PaymentTransaction object is prepared
    And the payment operation exceeds the timeout threshold
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 504
    And the response body should indicate a timeout error

    @TC15
    Scenario: Payment creation with extra unexpected parameters
    Given an account with id <validAccountId> exists
    And a valid PaymentTransaction object is prepared
    And the request includes extra, unsupported query or body parameters
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 201 or 400 depending on system tolerance
    And the response should indicate success or ignore extra parameters

    @TC16
    Scenario: Payment creation with minimum allowed values
    Given an account with id <validAccountId> exists
    And a PaymentTransaction object with minimum allowed amount and valid currency is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 201
    And the Payment object should reflect the minimum amount

    @TC17
    Scenario: Payment creation with maximum allowed values
    Given an account with id <validAccountId> exists
    And a PaymentTransaction object with maximum allowed amount and valid currency is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 201 or 400 depending on system limits
    And the response should indicate success or a value too large error

    @TC18
    Scenario: Payment creation with partial input (missing optional fields)
    Given an account with id <validAccountId> exists
    And a PaymentTransaction object with only required fields is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 201
    And the Payment object should reflect default values for missing fields

    @TC19
    Scenario: Payment creation with unsupported currency
    Given an account with id <validAccountId> exists
    And a PaymentTransaction object with an unsupported currency is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 400
    And the response body should indicate an unsupported currency error

    @TC20
    Scenario: Payment creation with unauthorized access
    Given an account with id <validAccountId> exists
    And a valid PaymentTransaction object is prepared
    And the authentication token is missing or invalid
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC21
    Scenario: Payment creation with malicious payload (security test)
    Given an account with id <validAccountId> exists
    And a PaymentTransaction object containing script or SQL injection in a field is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 400 or 422 depending on validation
    And the response body should indicate input validation failure

    @TC22
    Scenario: Payment creation with concurrent requests
    Given an account with id <validAccountId> exists
    And multiple valid PaymentTransaction objects are prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs multiple concurrent requests to /1.0/kb/accounts/<validAccountId>/payments
    Then all responses should be 201 or appropriate error codes
    And the system should not create duplicate or inconsistent payments

    @TC23
    Scenario: Payment creation while dependent services are degraded
    Given an account with id <validAccountId> exists
    And a valid PaymentTransaction object is prepared
    And a dependent plugin or gateway is responding slowly or with errors
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 502, 503, or 504 depending on the failure
    And the response body should indicate the nature of the dependency failure

    @TC24
    Scenario: Regression - previously fixed issue with payment method selection
    Given an account with id <validAccountId> exists and has multiple payment methods
    And a valid PaymentTransaction object is prepared
    And a specific paymentMethodId is provided in the request
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 201
    And the Payment object should reflect the selected payment method

    @TC25
    Scenario: Backward compatibility - client using older API version
    Given an account with id <validAccountId> exists
    And a valid PaymentTransaction object is prepared
    And the client sends a request using the previous API version endpoint
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response status code should be 201 or an appropriate compatibility error
    And the response should indicate compatibility status

    @TC26
    Scenario: Performance - response time under normal load
    Given an account with id <validAccountId> exists
    And a valid PaymentTransaction object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs to /1.0/kb/accounts/<validAccountId>/payments
    Then the response should be received within <acceptableResponseTime> milliseconds
    And the response status code should be 201

    @TC27
    Scenario: Performance - response time under peak load
    Given an account with id <validAccountId> exists
    And a valid PaymentTransaction object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs many requests to /1.0/kb/accounts/<validAccountId>/payments in a short time
    Then 95% of responses should be received within <peakAcceptableResponseTime> milliseconds
    And no system resource exhaustion should occur

    @TC28
    Scenario: Resource utilization under stress
    Given an account with id <validAccountId> exists
    And a valid PaymentTransaction object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user POSTs a very high volume of requests to /1.0/kb/accounts/<validAccountId>/payments
    Then the system should not exceed memory, CPU, or network thresholds
    And no data corruption or loss should occur

    @TC29
    Scenario: Accessibility - API documentation and error messages
    Given the API documentation is available
    When a user reviews the documentation and error message formats
    Then all fields, error codes, and messages should be clearly described
    And error responses should be machine-readable and accessible

    @TC30
    Scenario: Accessibility - error messages for screen readers (if UI involved)
    Given a UI client consumes the API and renders error messages
    When an error occurs (e.g., 400, 404, 422)
    Then the error message should be accessible to screen readers
    And the UI should follow accessibility guidelines