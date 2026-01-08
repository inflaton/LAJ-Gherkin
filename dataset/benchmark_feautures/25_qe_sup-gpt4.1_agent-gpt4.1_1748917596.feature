Feature: Trigger payment for all unpaid invoices via POST /1.0/kb/accounts/{accountId}/invoicePayments
As a KillBill API user,
I want to trigger payment for all unpaid invoices of an account,
so that I can settle outstanding balances efficiently.

  Background:
  Given the KillBill API is accessible at the configured baseUrl
  And the database contains accounts with various invoice states (no unpaid invoices, some unpaid invoices, all invoices unpaid)
  And valid and invalid account IDs are available for testing
  And valid and invalid payment method IDs are available for testing
  And valid authentication tokens and required headers (X-Killbill-CreatedBy) are prepared
  And the system clock and time zones are consistent
  And service dependencies (payment gateways, plugins) are available or properly mocked

    @TC01
    Scenario: Successful payment trigger with only required fields
    Given an account with unpaid invoices exists
    And a valid accountId is provided in the path
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments with no query parameters
    Then the API responds with HTTP 204
    And all unpaid invoices for the account are marked as paid
    And the payment is processed using the account's default payment method

    @TC02
    Scenario: Successful payment trigger with all optional parameters
    Given an account with unpaid invoices exists
    And a valid accountId is provided in the path
    And a valid paymentMethodId is specified as a query parameter
    And externalPayment is set to true
    And paymentAmount is set to a valid partial amount less than the total outstanding
    And targetDate is set to a valid date string
    And pluginProperty is set to multiple valid string values
    And X-Killbill-CreatedBy, X-Killbill-Reason, and X-Killbill-Comment headers are set
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments with all parameters
    Then the API responds with HTTP 204
    And only the specified paymentAmount is applied to the unpaid invoices
    And the payment is processed as an external payment
    And plugin properties are passed to the plugin layer

    @TC03
    Scenario: Successful payment trigger with paymentAmount equal to total outstanding
    Given an account with unpaid invoices exists
    And paymentAmount equals the total outstanding balance
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments with paymentAmount
    Then the API responds with HTTP 204
    And all unpaid invoices are paid in full

    @TC04
    Scenario: Successful payment trigger with paymentAmount greater than total outstanding
    Given an account with unpaid invoices exists
    And paymentAmount is greater than the total outstanding balance
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments with paymentAmount
    Then the API responds with HTTP 204
    And only the outstanding balance is paid (no overpayment occurs)

    @TC05
    Scenario: Successful payment trigger with pluginProperty array
    Given an account with unpaid invoices exists
    And pluginProperty is specified as multiple values
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments with pluginProperty
    Then the API responds with HTTP 204
    And all plugin properties are passed to the plugin system

    @TC06
    Scenario: Successful payment trigger for account with no unpaid invoices
    Given an account exists with all invoices paid
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 204
    And no payment is processed

    @TC07
    Scenario: Successful payment trigger for account with no invoices
    Given an account exists with no invoices
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 204
    And no payment is processed

    @TC08
    Scenario: Error when accountId is invalid (malformed UUID)
    Given an invalid accountId format is provided in the path
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 404
    And the response body contains an error message indicating invalid accountId

    @TC09
    Scenario: Error when accountId does not exist
    Given a well-formed but non-existent accountId is provided
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 404
    And the response body contains an error message indicating account not found

    @TC10
    Scenario: Error when X-Killbill-CreatedBy header is missing
    Given a valid accountId is provided
    And the X-Killbill-CreatedBy header is omitted
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 400 or 401 (depending on implementation)
    And the response body contains an error message indicating missing required header

    @TC11
    Scenario: Error when paymentMethodId is invalid
    Given an account with unpaid invoices exists
    And an invalid paymentMethodId is provided as a query parameter
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 400 or 404
    And the response body contains an error message indicating invalid payment method

    @TC12
    Scenario: Error when paymentAmount is negative or zero
    Given an account with unpaid invoices exists
    And paymentAmount is set to zero or a negative number
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid payment amount

    @TC13
    Scenario: Error when targetDate is malformed
    Given an account with unpaid invoices exists
    And targetDate is set to an invalid date string
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid date format

    @TC14
    Scenario: Error when externalPayment is not a boolean
    Given an account with unpaid invoices exists
    And externalPayment is set to an invalid value (e.g., 'notabool')
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid boolean value

    @TC15
    Scenario: Error when pluginProperty is not an array or contains invalid types
    Given an account with unpaid invoices exists
    And pluginProperty is set to an invalid type (e.g., integer)
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid pluginProperty

    @TC16
    Scenario: Error when required headers are present but empty
    Given a valid accountId is provided
    And X-Killbill-CreatedBy header is present but empty
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 400
    And the response body contains an error message indicating missing createdBy value

    @TC17
    Scenario: Unauthorized access attempt
    Given a valid accountId is provided
    And authentication tokens are missing or invalid
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 401
    And the response body contains an error message indicating unauthorized access

    @TC18
    Scenario: System error - payment gateway unavailable
    Given an account with unpaid invoices exists
    And the payment gateway is down or unreachable
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 502 or 503
    And the response body contains an error message indicating dependency failure

    @TC19
    Scenario: System error - database unavailable
    Given the database is down or unreachable
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 500
    And the response body contains an error message indicating internal server error

    @TC20
    Scenario: Security - SQL injection attempt in accountId
    Given an accountId contains SQL injection payload (e.g., '1; DROP TABLE invoices;')
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 404 or 400
    And the response body does not reveal sensitive information

    @TC21
    Scenario: Security - XSS attempt in pluginProperty
    Given pluginProperty contains a string with script tags
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 400
    And the response body does not execute or reflect the script

    @TC22
    Scenario: Recovery from transient network error
    Given a network timeout occurs during payment processing
    When the user retries the POST request
    Then the API responds with HTTP 204 if successful on retry
    And payments are not duplicated

    @TC23
    Scenario: Edge case - extremely large paymentAmount
    Given an account with a very large outstanding balance
    And paymentAmount is set to the maximum allowed value
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 204 or 400 (if above allowed limit)
    And the payment is processed up to system limits

    @TC24
    Scenario: Edge case - extremely large pluginProperty array
    Given pluginProperty is set to an array with the maximum allowed number of entries
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 204 or 400 (if above allowed limit)
    And all valid plugin properties are processed

    @TC25
    Scenario: Edge case - extra unexpected query parameters
    Given extra query parameters are included in the request
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 204 (ignoring unknown parameters) or 400 (if strict)

    @TC26
    Scenario: State variation - partially populated database
    Given the database contains accounts with mixed invoice states
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments for each account
    Then the API responds appropriately based on the account's invoice state

    @TC27
    Scenario: Integration - plugin system unavailable
    Given the plugin system is down or unresponsive
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments with pluginProperty
    Then the API responds with HTTP 502 or 503
    And the response body contains an error message indicating plugin system failure

    @TC28
    Scenario: Regression - previously fixed bug: duplicate payments on retry
    Given a network error occurs after payment is processed but before response is sent
    When the user retries the POST request
    Then the API responds with HTTP 204
    And no duplicate payment is created

    @TC29
    Scenario: Regression - backward compatibility with older clients omitting optional params
    Given a valid accountId is provided
    And only required headers are set
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments with no optional parameters
    Then the API responds with HTTP 204
    And payments are processed correctly

    @TC30
    Scenario: Performance - response time under normal load
    Given the system is under normal operational load
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API responds with HTTP 204 within 2 seconds

    @TC31
    Scenario: Performance - response time under peak load
    Given the system is under simulated peak load with concurrent requests
    When multiple users POST to /1.0/kb/accounts/{accountId}/invoicePayments concurrently
    Then the API responds with HTTP 204 within 5 seconds for each request

    @TC32
    Scenario: Performance - resource utilization under stress
    Given the system is under stress test conditions
    When the user POSTs to /1.0/kb/accounts/{accountId}/invoicePayments
    Then the API does not exceed defined memory and CPU thresholds

    @TC33
    Scenario: Accessibility - API documentation is accessible
    Given the API documentation is available
    When a screen reader is used to navigate the documentation for this endpoint
    Then all parameters, responses, and error codes are clearly described
    And documentation meets accessibility standards