Feature: Set Default Payment Method API
As a KillBill API user,
I want to set a specific payment method as the default for an account,
so that all future payments use the correct method and optionally pay all unpaid invoices.

  Background:
  Given the KillBill API is accessible and healthy
  And the database is seeded with accounts and payment methods in various states
  And valid and invalid UUIDs for accounts and payment methods are known
  And the user has a valid authentication token
  And required headers (X-Killbill-CreatedBy) are available

    @TC01
    Scenario: Successful set of default payment method with required parameters only
    Given an existing account with accountId and a valid paymentMethodId belonging to the account
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault with no query parameters
    Then the response status code should be 204
    And the payment method is set as default for the account
    And no unpaid invoices are paid automatically

    @TC02
    Scenario: Successful set of default payment method with payAllUnpaidInvoices true
    Given an existing account with unpaid invoices and a valid paymentMethodId
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault with query parameter payAllUnpaidInvoices=true
    Then the response status code should be 204
    And the payment method is set as default for the account
    And all unpaid invoices are attempted to be paid using the new default payment method

    @TC03
    Scenario: Successful set of default payment method with pluginProperty
    Given an existing account and a valid paymentMethodId
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault with query parameter pluginProperty=prop1&pluginProperty=prop2
    Then the response status code should be 204
    And the payment method is set as default for the account

    @TC04
    Scenario: Successful set of default payment method with all optional headers
    Given an existing account and a valid paymentMethodId
    And headers X-Killbill-CreatedBy, X-Killbill-Reason, and X-Killbill-Comment are set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 204
    And the payment method is set as default for the account
    And the audit log contains the correct reason and comment

    @TC05
    Scenario: Set default payment method for account with no unpaid invoices and payAllUnpaidInvoices true
    Given an existing account with no unpaid invoices and a valid paymentMethodId
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault with payAllUnpaidInvoices=true
    Then the response status code should be 204
    And the payment method is set as default for the account
    And no payment attempts are made

    @TC06
    Scenario: Set default payment method with invalid accountId format
    Given an invalid accountId that does not match UUID pattern and a valid paymentMethodId
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 400
    And the response body contains an error message indicating invalid accountId

    @TC07
    Scenario: Set default payment method with invalid paymentMethodId format
    Given a valid accountId and an invalid paymentMethodId that does not match UUID pattern
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 400
    And the response body contains an error message indicating invalid paymentMethodId

    @TC08
    Scenario: Set default payment method with non-existent accountId
    Given a non-existent but valid-format accountId and a valid paymentMethodId
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 404
    And the response body contains an error message indicating account not found

    @TC09
    Scenario: Set default payment method with non-existent paymentMethodId
    Given a valid accountId and a non-existent but valid-format paymentMethodId
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 404
    And the response body contains an error message indicating payment method not found

    @TC10
    Scenario: Set default payment method with paymentMethodId not belonging to account
    Given a valid accountId and a valid paymentMethodId that belongs to another account
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 404
    And the response body contains an error message indicating payment method not found for account

    @TC11
    Scenario: Set default payment method with missing X-Killbill-CreatedBy header
    Given a valid accountId and paymentMethodId
    And the X-Killbill-CreatedBy header is missing
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 400
    And the response body contains an error message indicating missing required header

    @TC12
    Scenario: Set default payment method with unauthorized user
    Given a valid accountId and paymentMethodId
    And the authentication token is invalid or missing
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 401
    And the response body contains an error message indicating unauthorized access

    @TC13
    Scenario: Set default payment method when KillBill service is unavailable
    Given a valid accountId and paymentMethodId
    And the KillBill API is unavailable
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 503
    And the response body contains an error message indicating service unavailable

    @TC14
    Scenario: Set default payment method with extra unexpected query parameters
    Given a valid accountId and paymentMethodId
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault with extra query parameter foo=bar
    Then the response status code should be 204
    And the payment method is set as default for the account

    @TC15
    Scenario: Set default payment method with maximum allowed pluginProperty entries
    Given a valid accountId and paymentMethodId
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault with pluginProperty array at maximum allowed length
    Then the response status code should be 204
    And the payment method is set as default for the account

    @TC16
    Scenario: Set default payment method with minimum and maximum allowed UUID values
    Given accountId and paymentMethodId at the minimum and maximum allowed UUID values
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 204 or 404 depending on existence

    @TC17
    Scenario: Set default payment method with very large number of unpaid invoices and payAllUnpaidInvoices true
    Given an existing account with a very large number of unpaid invoices and a valid paymentMethodId
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault with payAllUnpaidInvoices=true
    Then the response status code should be 204
    And the payment method is set as default for the account
    And all unpaid invoices are processed efficiently
    And the response time is within acceptable limits

    @TC18
    Scenario: Set default payment method with slow downstream dependency
    Given a valid accountId and paymentMethodId
    And a downstream dependency (e.g., payment plugin) is slow to respond
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 504 or 503 depending on timeout configuration
    And the response body contains an error message indicating timeout or service unavailable

    @TC19
    Scenario: Set default payment method with injection attack in header
    Given a valid accountId and paymentMethodId
    And header X-Killbill-CreatedBy contains a SQL injection attempt
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 400 or 422
    And the response body contains an error message indicating invalid input
    And no injection is executed

    @TC20
    Scenario: Regression - previously fixed bug: setting default payment method does not clear old default
    Given an account with an existing default payment method and a new valid paymentMethodId
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 204
    And the new payment method is set as default
    And the old default is no longer marked as default

    @TC21
    Scenario: Regression - previously fixed bug: setting default payment method for account with no payment methods
    Given an account with no payment methods
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 404
    And the response body contains an error message indicating payment method not found

    @TC22
    Scenario: Performance - set default payment method under concurrent requests
    Given an account with multiple valid payment methods
    And header X-Killbill-CreatedBy is set to a valid user
    When multiple concurrent PUT requests are sent to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault for different payment methods
    Then only one payment method is set as default at the end
    And the system remains consistent
    And response times are within acceptable limits

    @TC23
    Scenario: Set default payment method with partial UUIDs
    Given an accountId or paymentMethodId that is a substring of a valid UUID
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault
    Then the response status code should be 400
    And the response body contains an error message indicating invalid UUID format

    @TC24
    Scenario: Set default payment method with empty pluginProperty array
    Given a valid accountId and paymentMethodId
    And header X-Killbill-CreatedBy is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}/paymentMethods/{paymentMethodId}/setDefault with pluginProperty=
    Then the response status code should be 204
    And the payment method is set as default for the account

    @TC25
    Scenario: Accessibility - ensure API documentation and error messages are accessible
    Given a user with screen reader technology
    When the user reviews the API documentation and error responses
    Then all content is accessible and readable according to accessibility standards