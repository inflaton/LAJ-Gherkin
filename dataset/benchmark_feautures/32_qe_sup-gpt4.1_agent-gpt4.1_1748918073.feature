Feature: Trigger Payment via POST /1.0/kb/accounts/payments
As a KillBill API user,
I want to trigger a payment using an account's external key,
so that I can initiate payment transactions (authorization, purchase, or credit) for a specified account.

  Background:
  Given the KillBill API is available at the correct base URL
  And the system has seeded accounts with diverse external keys and payment methods
  And valid authentication and authorization tokens are set up
  And the PaymentTransaction and Payment object schemas are defined and known
  And the account(s) under test have both default and non-default payment methods
  And valid and invalid control plugins and plugin properties are available
  And the system clock is synchronized

    @TC01
    Scenario: Successful payment creation with required parameters only
    Given an account exists with external key "acc-key-123" and a default payment method
    And a valid PaymentTransaction object is prepared (amount, currency, transactionType)
    When the user sends a POST request to /1.0/kb/accounts/payments with query parameter externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 201
    And the response body should be a valid Payment object reflecting the transaction
    And the Location header should contain the URL of the new payment resource

    @TC02
    Scenario: Successful payment with all optional parameters and headers
    Given an account exists with external key "acc-key-456" and payment method ID "pm-uuid-789"
    And valid control plugins "pluginA" and "pluginB" exist
    And valid plugin properties "prop1=true" and "prop2=123" exist
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with
      | externalKey         | acc-key-456      |
      | paymentMethodId     | pm-uuid-789      |
      | controlPluginName   | pluginA,pluginB  |
      | pluginProperty      | prop1=true,prop2=123 |
    And sets headers:
      | X-Killbill-CreatedBy | test-user-2      |
      | X-Killbill-Reason    | "refund"        |
      | X-Killbill-Comment   | "test comment"  |
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 201
    And the response body should be a valid Payment object reflecting the transaction
    And the Location header should contain the URL of the new payment resource

    @TC03
    Scenario: Successful payment with only required header and all combinations of query parameters
    Given an account exists with external key "acc-key-789" and multiple payment methods
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with:
      | externalKey         | acc-key-789      |
      | paymentMethodId     | pm-uuid-101      |
    And sets header X-Killbill-CreatedBy="test-user-3"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 201
    And the response body should be a valid Payment object
    And the Location header should contain the URL of the new payment resource

    @TC04
    Scenario: Successful payment with controlPluginName only
    Given an account exists with external key "acc-key-321"
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-321" and controlPluginName="pluginA"
    And sets header X-Killbill-CreatedBy="test-user-4"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 201
    And the response body should be a valid Payment object
    And the Location header should contain the URL of the new payment resource

    @TC05
    Scenario: Successful payment with pluginProperty only
    Given an account exists with external key "acc-key-654"
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-654" and pluginProperty="customProp=42"
    And sets header X-Killbill-CreatedBy="test-user-5"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 201
    And the response body should be a valid Payment object
    And the Location header should contain the URL of the new payment resource

    @TC06
    Scenario: Successful payment when account has no default payment method but paymentMethodId is provided
    Given an account exists with external key "acc-key-999" and no default payment method
    And payment method ID "pm-uuid-999" is valid for the account
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-999" and paymentMethodId="pm-uuid-999"
    And sets header X-Killbill-CreatedBy="test-user-6"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 201
    And the response body should be a valid Payment object
    And the Location header should contain the URL of the new payment resource

    @TC07
    Scenario: Attempt payment with invalid external key
    Given no account exists with external key "invalid-key"
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="invalid-key"
    And sets header X-Killbill-CreatedBy="test-user-7"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 404
    And the response body should contain an error message indicating account not found

    @TC08
    Scenario: Attempt payment with missing required externalKey parameter
    Given a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments without the externalKey parameter
    And sets header X-Killbill-CreatedBy="test-user-8"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 400
    And the response body should contain an error message indicating missing required parameter

    @TC09
    Scenario: Attempt payment with malformed request body
    Given an account exists with external key "acc-key-123"
    And the request body is not a valid PaymentTransaction JSON object
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-9"
    And includes the malformed request body
    Then the response status code should be 400
    And the response body should contain an error message indicating malformed request

    @TC10
    Scenario: Attempt payment with missing required header X-Killbill-CreatedBy
    Given an account exists with external key "acc-key-123"
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123" but omits the X-Killbill-CreatedBy header
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 400
    And the response body should contain an error message indicating missing required header

    @TC11
    Scenario: Attempt payment with invalid paymentMethodId
    Given an account exists with external key "acc-key-123"
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123" and paymentMethodId="invalid-uuid"
    And sets header X-Killbill-CreatedBy="test-user-11"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid payment method ID

    @TC12
    Scenario: Attempt payment with transaction declined by gateway
    Given an account exists with external key "acc-key-123"
    And a PaymentTransaction object is prepared that will be declined by the gateway
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-12"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 402
    And the response body should contain an error message indicating transaction declined

    @TC13
    Scenario: Attempt payment aborted by control plugin
    Given an account exists with external key "acc-key-123"
    And a PaymentTransaction object is prepared
    And controlPluginName="abortPlugin" which is configured to abort the transaction
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123" and controlPluginName="abortPlugin"
    And sets header X-Killbill-CreatedBy="test-user-13"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 422
    And the response body should contain an error message indicating payment aborted by plugin

    @TC14
    Scenario: Attempt payment with gateway submission failure
    Given an account exists with external key "acc-key-123"
    And a PaymentTransaction object is prepared that will trigger a gateway submission failure
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-14"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 502
    And the response body should contain an error message indicating gateway submission failure

    @TC15
    Scenario: Attempt payment with unknown payment status (gateway no response)
    Given an account exists with external key "acc-key-123"
    And a PaymentTransaction object is prepared that will trigger an unknown payment status
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-15"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 503
    And the response body should contain an error message indicating unknown payment status

    @TC16
    Scenario: Attempt payment with payment operation timeout
    Given an account exists with external key "acc-key-123"
    And a PaymentTransaction object is prepared that will cause a timeout
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-16"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 504
    And the response body should contain an error message indicating timeout

    @TC17
    Scenario: Attempt payment with unauthorized access
    Given an account exists with external key "acc-key-123"
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And omits valid authentication or uses an invalid token
    Then the response status code should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC18
    Scenario: Attempt payment with malicious payload (security test)
    Given an account exists with external key "acc-key-123"
    And the PaymentTransaction object contains a malicious script as a value
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-18"
    And includes the malicious PaymentTransaction object in the request body as JSON
    Then the response status code should be 400 or 422
    And the response body should not execute or reflect the script
    And the system should log the attempt for review

    @TC19
    Scenario: Attempt payment with extra/unsupported parameters
    Given an account exists with external key "acc-key-123"
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123" and an unsupported query parameter foo=bar
    And sets header X-Killbill-CreatedBy="test-user-19"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 201 or 400 depending on API strictness
    And the response body should not include the unsupported parameter

    @TC20
    Scenario: Payment with empty database (no accounts)
    Given the system database contains no accounts
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="any-key"
    And sets header X-Killbill-CreatedBy="test-user-20"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 404
    And the response body should contain an error message indicating account not found

    @TC21
    Scenario: Payment with large payload (boundary test)
    Given an account exists with external key "acc-key-123"
    And a PaymentTransaction object is prepared with maximum allowed field sizes
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-21"
    And includes the large PaymentTransaction object in the request body as JSON
    Then the response status code should be 201 or 400 depending on size limits
    And the response body should reflect acceptance or error due to payload size

    @TC22
    Scenario: Payment with minimal allowed values (boundary test)
    Given an account exists with external key "acc-key-123"
    And a PaymentTransaction object is prepared with minimal allowed amount and required fields
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-22"
    And includes the minimal PaymentTransaction object in the request body as JSON
    Then the response status code should be 201
    And the response body should reflect the minimal transaction

    @TC23
    Scenario: Payment with partial input (missing optional fields)
    Given an account exists with external key "acc-key-123"
    And a PaymentTransaction object is prepared with only required fields
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-23"
    And includes the minimal PaymentTransaction object in the request body as JSON
    Then the response status code should be 201
    And the response body should reflect the transaction

    @TC24
    Scenario: Payment when dependent service is unavailable (integration test)
    Given an account exists with external key "acc-key-123"
    And a valid PaymentTransaction object is prepared
    And the payment gateway service is down
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-24"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 502 or 503
    And the response body should contain an error message indicating dependency failure

    @TC25
    Scenario: Regression - previously fixed issue with pluginProperty handling
    Given an account exists with external key "acc-key-123"
    And a valid PaymentTransaction object is prepared
    And pluginProperty="prevBug=true"
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123" and pluginProperty="prevBug=true"
    And sets header X-Killbill-CreatedBy="test-user-25"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response status code should be 201
    And the response body should reflect correct pluginProperty handling

    @TC26
    Scenario: Regression - backward compatibility with older clients
    Given an account exists with external key "acc-key-123"
    And a valid PaymentTransaction object is prepared using only fields supported by previous API versions
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-26"
    And includes the backward-compatible PaymentTransaction object in the request body as JSON
    Then the response status code should be 201
    And the response body should be backward compatible

    @TC27
    Scenario: Performance - response time under normal load
    Given the system is under normal load conditions
    And an account exists with external key "acc-key-123"
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-27"
    And includes the PaymentTransaction object in the request body as JSON
    Then the response time should be less than 2 seconds
    And the response status code should be 201

    @TC28
    Scenario: Performance - response time under peak load
    Given the system is under peak load with high concurrent requests
    And an account exists with external key "acc-key-123"
    And a valid PaymentTransaction object is prepared
    When the user sends multiple concurrent POST requests to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-28"
    And includes the PaymentTransaction object in the request body as JSON
    Then the 95th percentile response time should be less than 5 seconds
    And the response status code should be 201

    @TC29
    Scenario: Performance - resource utilization under stress
    Given the system is under stress with many concurrent payment requests
    And an account exists with external key "acc-key-123"
    And a valid PaymentTransaction object is prepared
    When the user sends a POST request to /1.0/kb/accounts/payments with externalKey="acc-key-123"
    And sets header X-Killbill-CreatedBy="test-user-29"
    And includes the PaymentTransaction object in the request body as JSON
    Then the system's CPU, memory, and network utilization should remain within acceptable thresholds
    And the response status code should be 201

    @TC30
    Scenario: Accessibility - API documentation and error messages
    Given the API documentation is available
    When a user reviews the documentation for /1.0/kb/accounts/payments
    Then all required parameters and error codes should be clearly documented
    And error messages in responses should be descriptive and actionable