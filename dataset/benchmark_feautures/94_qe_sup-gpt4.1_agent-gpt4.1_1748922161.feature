Feature: Retrieve tags for an invoice payment via GET /1.0/kb/invoicePayments/{paymentId}/tags
As a KillBill API user,
I want to retrieve tags for a specific invoice payment,
so that I can view all tags (including optionally deleted tags) associated with a payment and audit information as needed.

  Background:
  Given the KillBill API is running and accessible
  And a valid authentication token is provided in the request headers
  And the database contains diverse invoice payments, some with tags, some without, and some with deleted tags
  And the user has permission to view invoice payments and their tags

    @TC01
    Scenario: Successful retrieval of tags for an invoice payment with no query parameters (happy path)
    Given an invoice payment exists with paymentId 'valid-uuid-1' and has tags assigned
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-1/tags with no query parameters
    Then the API should respond with HTTP status 200
    And the response body should be a JSON array of Tag objects corresponding to the non-deleted tags for 'valid-uuid-1'
    And the response Content-Type should be 'application/json'

    @TC02
    Scenario: Successful retrieval of tags with includedDeleted=true
    Given an invoice payment exists with paymentId 'valid-uuid-2' and has both active and deleted tags
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-2/tags?includedDeleted=true
    Then the API should respond with HTTP status 200
    And the response body should include both active and deleted tags for 'valid-uuid-2'

    @TC03
    Scenario: Successful retrieval of tags with pluginProperty parameter
    Given an invoice payment exists with paymentId 'valid-uuid-3' and plugin properties are supported
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-3/tags?pluginProperty=prop1&pluginProperty=prop2
    Then the API should respond with HTTP status 200
    And the response body should be a JSON array of Tag objects for 'valid-uuid-3'
    And the plugin properties should be processed according to the plugin's logic

    @TC04
    Scenario: Successful retrieval of tags with audit=FULL
    Given an invoice payment exists with paymentId 'valid-uuid-4' and has tags
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-4/tags?audit=FULL
    Then the API should respond with HTTP status 200
    And the response body should include audit information at the FULL level for each tag

    @TC05
    Scenario: Successful retrieval of tags with all query parameters combined
    Given an invoice payment exists with paymentId 'valid-uuid-5' and has both active and deleted tags
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-5/tags?includedDeleted=true&pluginProperty=propA&pluginProperty=propB&audit=MINIMAL
    Then the API should respond with HTTP status 200
    And the response body should include both active and deleted tags for 'valid-uuid-5'
    And the audit information should be at the MINIMAL level
    And the plugin properties should be processed as specified

    @TC06
    Scenario: Retrieval of tags for an invoice payment with no tags
    Given an invoice payment exists with paymentId 'valid-uuid-6' and has no tags
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-6/tags
    Then the API should respond with HTTP status 200
    And the response body should be an empty JSON array

    @TC07
    Scenario: Retrieval of tags for an invoice payment when no payments exist
    Given the database contains no invoice payments
    When the user sends a GET request to /1.0/kb/invoicePayments/non-existent-uuid/tags
    Then the API should respond with HTTP status 404
    And the response body should indicate that the payment was not found

    @TC08
    Scenario: Retrieval with invalid paymentId format
    Given the user provides a paymentId 'invalid-format' that does not match the UUID pattern
    When the user sends a GET request to /1.0/kb/invoicePayments/invalid-format/tags
    Then the API should respond with HTTP status 400
    And the response body should indicate an invalid payment ID error

    @TC09
    Scenario: Retrieval with missing authentication token
    Given an invoice payment exists with paymentId 'valid-uuid-7'
    And the user omits the authentication token in the request headers
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-7/tags
    Then the API should respond with HTTP status 401
    And the response body should indicate an authentication error

    @TC10
    Scenario: Retrieval with unsupported audit parameter value
    Given an invoice payment exists with paymentId 'valid-uuid-8'
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-8/tags?audit=INVALID
    Then the API should respond with HTTP status 400
    And the response body should indicate an invalid audit parameter value

    @TC11
    Scenario: Retrieval with extra/unexpected query parameters
    Given an invoice payment exists with paymentId 'valid-uuid-9'
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-9/tags?extraParam=unexpected
    Then the API should respond with HTTP status 200
    And the response body should be a JSON array of Tag objects for 'valid-uuid-9'
    And the extra parameter should be ignored

    @TC12
    Scenario: Retrieval when system is under heavy load (performance)
    Given the system is under simulated heavy load
    And an invoice payment exists with paymentId 'valid-uuid-10' and has a large number of tags
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-10/tags
    Then the API should respond with HTTP status 200 within the acceptable response time threshold
    And the response body should include all tags for 'valid-uuid-10'

    @TC13
    Scenario: Retrieval when dependent tag service is unavailable (integration)
    Given the tag service dependency is down
    And an invoice payment exists with paymentId 'valid-uuid-11'
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-11/tags
    Then the API should respond with HTTP status 503
    And the response body should indicate a service unavailable error

    @TC14
    Scenario: Regression - previously fixed issue with deleted tags being omitted when includedDeleted=true
    Given an invoice payment exists with paymentId 'valid-uuid-12' and has deleted tags
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-12/tags?includedDeleted=true
    Then the API should respond with HTTP status 200
    And the response body should include deleted tags

    @TC15
    Scenario: Security - SQL injection attempt in paymentId
    Given the user provides a paymentId "' OR '1'='1' --" in the request
    When the user sends a GET request to /1.0/kb/invoicePayments/' OR '1'='1' --/tags
    Then the API should respond with HTTP status 400 or 404
    And the response body should not reveal sensitive information

    @TC16
    Scenario: Security - XSS attempt in pluginProperty
    Given an invoice payment exists with paymentId 'valid-uuid-13'
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-13/tags?pluginProperty=<script>alert(1)</script>
    Then the API should respond with HTTP status 200 or 400
    And the response body should not execute or reflect the script

    @TC17
    Scenario: Edge - Maximum allowed pluginProperty entries
    Given an invoice payment exists with paymentId 'valid-uuid-14'
    And the system supports up to N pluginProperty entries
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-14/tags with N pluginProperty parameters
    Then the API should respond with HTTP status 200
    And the response body should be correct and not truncated

    @TC18
    Scenario: Edge - Large payload of tags returned
    Given an invoice payment exists with paymentId 'valid-uuid-15' and has the maximum number of tags
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-15/tags
    Then the API should respond with HTTP status 200
    And the response body should contain all tags without truncation

    @TC19
    Scenario: State variation - partially populated database
    Given the database contains only some invoice payments, and paymentId 'valid-uuid-16' exists
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-16/tags
    Then the API should respond with HTTP status 200
    And the response body should reflect the tags for 'valid-uuid-16'

    @TC20
    Scenario: State variation - empty database
    Given the database is empty
    When the user sends a GET request to /1.0/kb/invoicePayments/any-uuid/tags
    Then the API should respond with HTTP status 404
    And the response body should indicate that the payment was not found

    @TC21
    Scenario: Recovery from transient network failure
    Given an invoice payment exists with paymentId 'valid-uuid-17'
    And a transient network failure occurs during the request
    When the user retries the GET request to /1.0/kb/invoicePayments/valid-uuid-17/tags
    Then the API should respond with HTTP status 200 on successful retry
    And the response body should be a JSON array of Tag objects for 'valid-uuid-17'

    @TC22
    Scenario: Backward compatibility with previous clients
    Given an invoice payment exists with paymentId 'valid-uuid-18' and has tags
    When a client using an older version of the API sends a GET request to /1.0/kb/invoicePayments/valid-uuid-18/tags
    Then the API should respond with HTTP status 200
    And the response body should be compatible with the previous Tag schema

    @TC23
    Scenario: Accessibility - response structure for screen readers
    Given an invoice payment exists with paymentId 'valid-uuid-19' and has tags
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-19/tags
    Then the API should respond with HTTP status 200
    And the JSON structure should be well-formed and accessible for screen readers

    @TC24
    Scenario: Error - service returns 500 Internal Server Error
    Given an invoice payment exists with paymentId 'valid-uuid-20'
    And an unexpected server error occurs
    When the user sends a GET request to /1.0/kb/invoicePayments/valid-uuid-20/tags
    Then the API should respond with HTTP status 500
    And the response body should indicate an internal server error