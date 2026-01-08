Feature: Update Account via PUT /1.0/kb/accounts/{accountId}
As a KillBill API user,
I want to update an existing account using the PUT /1.0/kb/accounts/{accountId} endpoint,
so that I can modify account details as needed.

  Background:
  Given the KillBill API is available
  And the database contains at least one valid account with a known accountId
  And a valid authentication token is present
  And the API endpoint PUT /1.0/kb/accounts/{accountId} is reachable

    @TC01
    Scenario: Successful update of account with minimal required fields
    Given a valid accountId exists
    And the request body contains valid Account fields to update
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 204
    And the account details should be updated in the database

    @TC02
    Scenario: Successful update with all possible fields including optional headers
    Given a valid accountId exists
    And the request body contains all updatable Account fields with valid values
    And the X-Killbill-CreatedBy header is set
    And the X-Killbill-Reason header is set
    And the X-Killbill-Comment header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 204
    And the account details should reflect all updated values

    @TC03
    Scenario: Update with treatNullAsReset true and null fields in body
    Given a valid accountId exists
    And the request body includes one or more fields set to null
    And the treatNullAsReset query parameter is true
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}?treatNullAsReset=true
    Then the API should respond with status code 204
    And the corresponding fields in the account should be reset to their default values

    @TC04
    Scenario: Update with treatNullAsReset false and null fields in body
    Given a valid accountId exists
    And the request body includes one or more fields set to null
    And the treatNullAsReset query parameter is false or omitted
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 204
    And the corresponding fields in the account should remain unchanged

    @TC05
    Scenario: Update with missing X-Killbill-CreatedBy header
    Given a valid accountId exists
    And the request body contains valid Account fields
    And the X-Killbill-CreatedBy header is missing
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 400
    And the response body should indicate the missing required header

    @TC06
    Scenario: Update with invalid accountId format
    Given the accountId is not a valid UUID
    And the request body contains valid Account fields
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{invalidAccountId}
    Then the API should respond with status code 400
    And the response body should indicate invalid accountId format

    @TC07
    Scenario: Update with invalid Account data in request body
    Given a valid accountId exists
    And the request body contains invalid Account data (e.g., required fields missing, invalid field values)
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 400
    And the response body should indicate invalid account data

    @TC08
    Scenario: Update non-existent account
    Given the accountId does not exist in the system
    And the request body contains valid Account fields
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{nonExistentAccountId}
    Then the API should respond with status code 400
    And the response body should indicate account not found

    @TC09
    Scenario: Unauthorized update attempt
    Given a valid accountId exists
    And the request body contains valid Account fields
    And the authentication token is missing or invalid
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 401
    And the response body should indicate unauthorized access

    @TC10
    Scenario: Update with extra, unsupported fields in request body
    Given a valid accountId exists
    And the request body contains valid Account fields plus extra unsupported fields
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 204 or ignore extra fields
    And the account should be updated only with supported fields

    @TC11
    Scenario: Update with empty request body
    Given a valid accountId exists
    And the request body is empty
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 400
    And the response body should indicate missing request body

    @TC12
    Scenario: System error during update (e.g., database unavailable)
    Given a valid accountId exists
    And the database is unavailable
    And the request body contains valid Account fields
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 500
    And the response body should indicate a server error

    @TC13
    Scenario: Update with large payload approaching size limit
    Given a valid accountId exists
    And the request body contains a large number of Account fields or large field values
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 204 if successful
    And the account should be updated accordingly
    And the response time should be within acceptable limits

    @TC14
    Scenario: Update with slow network or timeout condition
    Given a valid accountId exists
    And the request body contains valid Account fields
    And the X-Killbill-CreatedBy header is set
    And the network is experiencing high latency
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond within the configured timeout period or with a timeout error

    @TC15
    Scenario: Regression - previously fixed issue: updating email field does not overwrite other fields
    Given a valid accountId exists
    And the request body updates only the email field
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 204
    And only the email field should be changed in the account

    @TC16
    Scenario: Integration - update propagates to dependent services
    Given a valid accountId exists
    And the request body updates a field that is consumed by a dependent service
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 204
    And the dependent service should reflect the updated field

    @TC17
    Scenario: Performance - concurrent updates to the same account
    Given a valid accountId exists
    And multiple clients prepare valid update requests for the same accountId
    When the clients send concurrent PUT requests to /1.0/kb/accounts/{accountId}
    Then the API should handle concurrent updates gracefully
    And the final account state should be consistent

    @TC18
    Scenario: Security - injection attempt in Account fields
    Given a valid accountId exists
    And the request body contains Account fields with malicious input (e.g., SQL injection, script tags)
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 400 or sanitize the input
    And the malicious input should not be persisted

    @TC19
    Scenario: Update with partial input (only some fields provided)
    Given a valid accountId exists
    And the request body contains only a subset of Account fields
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 204
    And only the provided fields should be updated

    @TC20
    Scenario: Update with minimum and maximum allowed values for fields
    Given a valid accountId exists
    And the request body contains Account fields set to their minimum and maximum allowed values
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 204
    And the account should reflect the updated values within allowed limits

    @TC21
    Scenario: Update with unexpected input formats
    Given a valid accountId exists
    And the request body contains Account fields with unexpected input formats (e.g., wrong data types)
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}
    Then the API should respond with status code 400
    And the response body should indicate invalid input format

    @TC22
    Scenario: Update with extra query parameters
    Given a valid accountId exists
    And the request body contains valid Account fields
    And the X-Killbill-CreatedBy header is set
    When the user sends a PUT request to /1.0/kb/accounts/{accountId}?extraParam=unexpected
    Then the API should respond with status code 204 or ignore extra query parameters
    And the account should be updated as expected