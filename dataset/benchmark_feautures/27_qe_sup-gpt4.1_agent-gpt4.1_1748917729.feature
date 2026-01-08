Feature: Add a payment method to an account via POST /1.0/kb/accounts/{accountId}/paymentMethods
As a KillBill API user,
I want to add a payment method to an account,
so that I can enable payments and manage account billing options.

  Background:
  Given the KillBill API is reachable and healthy
  And a valid authentication token is provided
  And the database contains a diverse set of accounts (including accounts with and without payment methods)
  And the PaymentMethod schema is known and available
  And the required headers (X-Killbill-CreatedBy) are set
  And the system clock is set to a valid time

    @TC01
    Scenario: Successfully add a payment method with required fields only
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object with required fields (pluginName, pluginInfo)
    When the user sends a POST request to /1.0/kb/accounts/valid-account-uuid/paymentMethods with the PaymentMethod object and header X-Killbill-CreatedBy
    Then the response status code should be 201
    And the response body should contain the created PaymentMethod object with correct values
    And the Location header should contain the URL of the new payment method

    @TC02
    Scenario: Add a payment method and set as default
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    When the user sends a POST request with query parameter isDefault=true
    Then the response status code should be 201
    And the created payment method should be set as the default for the account

    @TC03
    Scenario: Add a payment method and pay all unpaid invoices
    Given an account with unpaid invoices and accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    When the user sends a POST request with query parameter payAllUnpaidInvoices=true
    Then the response status code should be 201
    And all unpaid invoices should be attempted to be paid using the new payment method

    @TC04
    Scenario: Add a payment method with control plugins and plugin properties
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    When the user sends a POST request with query parameters controlPluginName=pluginA&controlPluginName=pluginB and pluginProperty=key1:value1&pluginProperty=key2:value2
    Then the response status code should be 201
    And the specified control plugins should be invoked
    And the plugin properties should be passed to the plugin

    @TC05
    Scenario: Add a payment method with all optional headers
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    When the user sends a POST request with headers X-Killbill-Reason and X-Killbill-Comment
    Then the response status code should be 201
    And the response body should reflect the reason and comment in audit fields if applicable

    @TC06
    Scenario: Add a payment method to an account with no existing payment methods
    Given an existing account with accountId 'no-payment-methods-uuid' and no payment methods
    And a valid PaymentMethod object
    When the user sends a POST request
    Then the response status code should be 201
    And the account should now have one payment method

    @TC07
    Scenario: Add a payment method to an account with existing payment methods
    Given an existing account with accountId 'multiple-payment-methods-uuid' and multiple payment methods
    And a valid PaymentMethod object
    When the user sends a POST request
    Then the response status code should be 201
    And the account should have one more payment method than before

    @TC08
    Scenario: Add a payment method with all query parameters combined
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    When the user sends a POST request with isDefault=true, payAllUnpaidInvoices=true, controlPluginName=pluginA, pluginProperty=key1:value1
    Then the response status code should be 201
    And the payment method should be default
    And all unpaid invoices should be attempted to be paid
    And the control plugin should be invoked with the plugin property

    @TC09
    Scenario: Add a payment method with extra/unexpected query parameters
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    When the user sends a POST request with an unexpected query parameter foo=bar
    Then the response status code should be 201
    And the unexpected parameter should be ignored

    @TC10
    Scenario: Add a payment method with a large payload
    Given an existing account with accountId 'valid-account-uuid'
    And a PaymentMethod object with maximum allowed field sizes and pluginInfo details
    When the user sends a POST request
    Then the response status code should be 201
    And the system should handle the large payload without error

    @TC11
    Scenario: Add a payment method with minimal payload
    Given an existing account with accountId 'valid-account-uuid'
    And a PaymentMethod object with only required fields
    When the user sends a POST request
    Then the response status code should be 201

    @TC12
    Scenario: Add a payment method with malformed JSON body
    Given an existing account with accountId 'valid-account-uuid'
    And a malformed JSON body
    When the user sends a POST request
    Then the response status code should be 400
    And the response should contain an error message indicating a malformed body

    @TC13
    Scenario: Add a payment method with missing required fields in body
    Given an existing account with accountId 'valid-account-uuid'
    And a PaymentMethod object missing required fields
    When the user sends a POST request
    Then the response status code should be 400
    And the response should indicate the missing fields

    @TC14
    Scenario: Add a payment method with invalid accountId format
    Given a non-UUID accountId 'invalid-account-id'
    And a valid PaymentMethod object
    When the user sends a POST request
    Then the response status code should be 400
    And the response should indicate the accountId format is invalid

    @TC15
    Scenario: Add a payment method for a non-existent account
    Given a valid but non-existent accountId 'nonexistent-account-uuid'
    And a valid PaymentMethod object
    When the user sends a POST request
    Then the response status code should be 404
    And the response should indicate the account was not found

    @TC16
    Scenario: Add a payment method with missing X-Killbill-CreatedBy header
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    When the user sends a POST request without the X-Killbill-CreatedBy header
    Then the response status code should be 400
    And the response should indicate the missing required header

    @TC17
    Scenario: Add a payment method with unauthorized access
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    When the user sends a POST request with an invalid or missing authentication token
    Then the response status code should be 401
    And the response should indicate unauthorized access

    @TC18
    Scenario: Add a payment method when the payment plugin service is unavailable
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    And the payment plugin service is down
    When the user sends a POST request
    Then the response status code should be 503
    And the response should indicate a service unavailable error

    @TC19
    Scenario: Add a payment method with SQL injection attempt in pluginName
    Given an existing account with accountId 'valid-account-uuid'
    And a PaymentMethod object with pluginName set to a SQL injection string
    When the user sends a POST request
    Then the response status code should be 400 or 422
    And the response should indicate invalid input

    @TC20
    Scenario: Add a payment method with XSS attempt in pluginInfo
    Given an existing account with accountId 'valid-account-uuid'
    And a PaymentMethod object with pluginInfo containing script tags
    When the user sends a POST request
    Then the response status code should be 400 or 422
    And the response should indicate invalid input

    @TC21
    Scenario: Add a payment method with network failure during request
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    And the network connection is interrupted during the request
    When the user sends a POST request
    Then the client should receive a network error
    And the system should not create a duplicate payment method on retry

    @TC22
    Scenario: Add a payment method with slow response (timeout)
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    And the backend is under heavy load
    When the user sends a POST request
    Then the response should be received within the configured timeout threshold

    @TC23
    Scenario: Add a payment method with concurrent requests
    Given an existing account with accountId 'valid-account-uuid'
    And multiple valid PaymentMethod objects
    When multiple POST requests are sent concurrently to add payment methods
    Then all requests should be processed correctly
    And no duplicate payment methods should be created

    @TC24
    Scenario: Regression - previously fixed bug: pluginProperty with empty string
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    When the user sends a POST request with pluginProperty=""
    Then the response status code should be 201
    And the empty pluginProperty should be ignored

    @TC25
    Scenario: Regression - backward compatibility with older clients
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object structured as per previous API version
    When the user sends a POST request
    Then the response status code should be 201
    And the payment method should be created successfully

    @TC26
    Scenario: Integration - payment method creation triggers downstream sync
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    And downstream systems are integrated
    When the user sends a POST request
    Then the payment method should be created
    And downstream systems should reflect the new payment method

    @TC27
    Scenario: Integration - payment plugin returns inconsistent data
    Given an existing account with accountId 'valid-account-uuid'
    And a PaymentMethod object
    And the payment plugin returns inconsistent or malformed data
    When the user sends a POST request
    Then the response status code should be 500
    And the response should indicate an internal server error

    @TC28
    Scenario: Performance - add payment method under normal load
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    When the user sends a POST request
    Then the response time should be less than 500ms

    @TC29
    Scenario: Performance - add payment method under peak load
    Given an existing account with accountId 'valid-account-uuid'
    And a valid PaymentMethod object
    And the system is under simulated peak load
    When the user sends a POST request
    Then the response time should be less than 2s

    @TC30
    Scenario: Accessibility - API documentation and error messages
    Given the API documentation is available
    When a user with assistive technology accesses the documentation
    Then the documentation should be accessible and error messages should be clear and descriptive