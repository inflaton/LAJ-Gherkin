Feature: Create Credit via POST /1.0/kb/credits
As a KillBill API user,
I want to create one or more credits for an account using the POST /1.0/kb/credits API,
so that account balances and invoices can be adjusted as per business needs.

  Background:
  Given the KillBill API is available at the configured baseUrl
  And the API endpoint POST /1.0/kb/credits is reachable
  And valid and invalid account and invoice data is seeded in the database
  And a valid authentication context is available (X-Killbill-CreatedBy header is required)
  And the system clock is set to a known value
  And all dependent services (e.g., plugins) are available or properly mocked

    @TC01
    Scenario: Successful creation of a single credit with minimum required fields
    Given a valid accountId exists
    And a valid InvoiceItem object with accountId, negative amount, currency, and itemType CREDIT_ADJ is prepared
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/credits with the InvoiceItem in the body
    Then the response code should be 201
    And the response body should be a JSON array containing the created InvoiceItem with matching fields
    And the Location header should be present and point to the created resource

    @TC02
    Scenario: Successful creation of multiple credits in a single request
    Given a valid accountId exists
    And a request body with a JSON array of two valid InvoiceItem objects for the same accountId is prepared
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/credits with the array in the body
    Then the response code should be 201
    And the response body should be a JSON array containing both created InvoiceItems

    @TC03
    Scenario: Successful creation of a credit with invoiceId specified (adjusting a specific invoice)
    Given a valid accountId and a valid invoiceId for that account exist
    And a valid InvoiceItem with accountId, invoiceId, negative amount, currency, and itemType CREDIT_ADJ is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits with the item in the body
    Then the response code should be 201
    And the response body should include the created InvoiceItem with the specified invoiceId

    @TC04
    Scenario: Successful creation of a credit with autoCommit true
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits with autoCommit=true as a query parameter
    Then the response code should be 201
    And the created credit should be committed automatically (verify via subsequent GET if possible)

    @TC05
    Scenario: Successful creation of a credit with pluginProperty specified
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits with pluginProperty set to multiple string values as query parameters
    Then the response code should be 201
    And the plugin properties should be passed to the plugin system (verify via logs or plugin mock if possible)

    @TC06
    Scenario: Successful creation with all optional headers set
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy, X-Killbill-Reason, and X-Killbill-Comment headers are set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 201
    And the created credit should be associated with the provided reason and comment (verify via audit logs or GET if possible)

    @TC07
    Scenario: Creation of a credit when no invoiceId is specified (should create CBA)
    Given a valid accountId exists
    And a valid InvoiceItem object without invoiceId is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 201
    And the response should indicate a CBA_ADJ or CREDIT_ADJ itemType as appropriate

    @TC08
    Scenario: Creation of a credit when no data exists for the account
    Given an accountId that does not exist in the system
    And a valid InvoiceItem object with that accountId is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 404
    And the response body should indicate account not found

    @TC09
    Scenario: Creation of a credit when invoiceId does not exist
    Given a valid accountId exists
    And an invoiceId that does not exist is specified in the InvoiceItem
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 404
    And the response body should indicate invoice not found

    @TC10
    Scenario: Error when required header X-Killbill-CreatedBy is missing
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    When the user sends a POST request to /1.0/kb/credits without the X-Killbill-CreatedBy header
    Then the response code should be 400
    And the response body should indicate missing required header

    @TC11
    Scenario: Error when request body is malformed JSON
    Given a valid accountId exists
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits with a malformed JSON body
    Then the response code should be 400
    And the response body should indicate malformed request

    @TC12
    Scenario: Error when InvoiceItem object is missing required fields
    Given a valid accountId exists
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits with an InvoiceItem missing accountId or amount or currency
    Then the response code should be 400
    And the response body should indicate missing required fields

    @TC13
    Scenario: Error when amount is positive (should be negative or treated as such)
    Given a valid accountId exists
    And a valid InvoiceItem object with a positive amount is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 201 or 400 depending on system behavior
    And the created InvoiceItem should have a negative amount or the response should indicate invalid amount

    @TC14
    Scenario: Error when invalid accountId format is provided
    Given an invalid accountId (malformed UUID or string) is used in the InvoiceItem
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 400
    And the response body should indicate invalid accountId

    @TC15
    Scenario: Error when unsupported currency is provided
    Given a valid accountId exists
    And a valid InvoiceItem object with an unsupported currency value is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 400
    And the response body should indicate invalid currency

    @TC16
    Scenario: Error when pluginProperty is provided as a non-array or invalid type
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits with pluginProperty as a non-array or invalid type
    Then the response code should be 400
    And the response body should indicate invalid pluginProperty

    @TC17
    Scenario: Error when system is unavailable
    Given the KillBill API is down or unreachable
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 503
    And the response body should indicate service unavailable

    @TC18
    Scenario: Unauthorized access attempt
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set to a user without sufficient permissions
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 403
    And the response body should indicate insufficient permissions

    @TC19
    Scenario: Security - SQL injection attempt in fields
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared with SQL injection payloads in string fields
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 400 or 422
    And the response body should indicate invalid input

    @TC20
    Scenario: Security - XSS attempt in comment or reason headers
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set
    And the X-Killbill-Reason or X-Killbill-Comment header contains XSS payload
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 201 or 400 depending on sanitization
    And the response body or subsequent resource retrieval should not reflect the XSS payload unsanitized

    @TC21
    Scenario: Edge - Empty request body
    Given a valid accountId exists
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits with an empty body
    Then the response code should be 400
    And the response body should indicate missing request body

    @TC22
    Scenario: Edge - Extra unexpected fields in InvoiceItem
    Given a valid accountId exists
    And a valid InvoiceItem object with extra fields is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 201
    And the extra fields should be ignored in the response

    @TC23
    Scenario: Edge - Maximum allowed credits in a single request
    Given a valid accountId exists
    And a request body with the maximum allowed number of InvoiceItem objects is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 201
    And all credits should be created successfully

    @TC24
    Scenario: Edge - Large payload approaching system limits
    Given a valid accountId exists
    And a request body with a very large number of InvoiceItem objects is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 413 or 400 if payload is too large
    And the response body should indicate payload too large or similar error

    @TC25
    Scenario: Edge - Timeout condition on long-running operation
    Given a valid accountId exists
    And a request body with a large number of InvoiceItem objects is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 504 if the operation times out
    And the response body should indicate timeout

    @TC26
    Scenario: State - Database is empty except for the account
    Given only the accountId exists in the database with no invoices or credits
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 201
    And a new credit invoice should be created

    @TC27
    Scenario: State - Account has existing credits and invoices
    Given a valid accountId exists with multiple invoices and credits
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 201
    And the new credit should be reflected in the account balance

    @TC28
    Scenario: Integration - Plugin system is unavailable
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set
    And pluginProperty is specified
    And the plugin system is unavailable
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 503
    And the response body should indicate plugin system unavailable

    @TC29
    Scenario: Integration - Plugin system returns an error
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set
    And pluginProperty is specified
    And the plugin system returns an error
    When the user sends a POST request to /1.0/kb/credits
    Then the response code should be 400 or 500 depending on error type
    And the response body should indicate plugin error

    @TC30
    Scenario: Regression - Previously fixed bug: duplicate credits on retry
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    And the same request is retried (idempotency)
    Then only one credit should be created for the account

    @TC31
    Scenario: Regression - Backward compatibility with older clients (no pluginProperty, no autoCommit)
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits without pluginProperty or autoCommit parameters
    Then the response code should be 201
    And the credit should be created successfully

    @TC32
    Scenario: Performance - Response time under normal load
    Given a valid accountId exists
    And a valid InvoiceItem object is prepared
    And the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/credits
    Then the response time should be less than 500ms

    @TC33
    Scenario: Performance - Response time under peak load
    Given multiple concurrent POST requests to /1.0/kb/credits are sent
    And each has a valid InvoiceItem object and X-Killbill-CreatedBy header
    Then the response code for each should be 201
    And the response time should be within acceptable thresholds

    @TC34
    Scenario: Performance - Resource utilization under stress
    Given a test harness sends a high volume of POST requests to /1.0/kb/credits
    Then CPU and memory usage should remain within system limits
    And no resource leaks should occur

    @TC35
    Scenario: Accessibility - API documentation available and clear
    Given the API documentation is accessed
    Then the documentation should clearly describe required and optional parameters, headers, and response formats
    And examples should be accessible for screen readers