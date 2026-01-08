Feature: Add account email via POST /1.0/kb/accounts/{accountId}/emails
As a KillBill API user,
I want to add an email to a specific account,
so that the account can receive notifications or communications via email.

  Background:
  Given the KillBill API server is running and accessible
  And the API endpoint POST /1.0/kb/accounts/{accountId}/emails is available
  And the database contains a diverse set of accounts (some with emails, some without)
  And a valid authentication token is present (if required)
  And the AccountEmail schema is defined and available
  And the following headers are set as required:
    | Header                  | Value              |
    | X-Killbill-CreatedBy    | <valid user>       |
    | X-Killbill-Reason       | <any reason>       |
    | X-Killbill-Comment      | <any comment>      |

    @TC01
    Scenario: Successful addition of a new email to an existing account (happy path)
    Given an existing account with a valid accountId
    And a valid AccountEmail object in the request body with a unique email address
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201
    And the response body should be a JSON array containing the newly added AccountEmail object
    And the Location header should contain the URL of the new email resource
    And the email is associated with the account in the database

    @TC02
    Scenario: Add email with optional headers X-Killbill-Reason and X-Killbill-Comment
    Given an existing account with a valid accountId
    And a valid AccountEmail object in the request body
    And the request includes X-Killbill-Reason and X-Killbill-Comment headers
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201
    And the response body should contain the AccountEmail object
    And the Location header should be present

    @TC03
    Scenario: Add email when account has no existing emails
    Given an existing account with a valid accountId and no emails
    And a valid AccountEmail object in the request body
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201
    And the response body should contain the AccountEmail object
    And the Location header should be present

    @TC04
    Scenario: Add email when account already has emails
    Given an existing account with a valid accountId and at least one email
    And a valid AccountEmail object in the request body with a different email address
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201
    And the response body should include all emails for the account including the new one
    And the Location header should be present

    @TC05
    Scenario: Add email with only required headers (X-Killbill-CreatedBy)
    Given an existing account with a valid accountId
    And a valid AccountEmail object in the request body
    And only the X-Killbill-CreatedBy header is set
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201
    And the response body should contain the AccountEmail object
    And the Location header should be present

    @TC06
    Scenario: Add email with extra, unsupported parameters in the request body
    Given an existing account with a valid accountId
    And an AccountEmail object in the request body with extra fields not defined in the schema
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201 or 400 depending on API behavior
    And the response should document acceptance or rejection of extra fields

    @TC07
    Scenario: Add email with an invalid accountId format
    Given a non-UUID accountId (e.g., '1234')
    And a valid AccountEmail object in the request body
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId

    @TC08
    Scenario: Add email with a missing accountId in the path
    Given the accountId path parameter is omitted or empty
    And a valid AccountEmail object in the request body
    When the user sends a POST request to /1.0/kb/accounts//emails
    Then the response status code should be 400
    And the response body should indicate a missing or invalid accountId

    @TC09
    Scenario: Add email to a non-existent account
    Given a valid but non-existent accountId
    And a valid AccountEmail object in the request body
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 404
    And the response body should indicate the account was not found

    @TC10
    Scenario: Add email with malformed JSON in the request body
    Given an existing account with a valid accountId
    And a malformed JSON payload in the request body
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 400
    And the response body should indicate a malformed request body

    @TC11
    Scenario: Add email with missing required fields in AccountEmail object
    Given an existing account with a valid accountId
    And an AccountEmail object missing required fields (e.g., missing email address)
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 400
    And the response body should indicate which fields are missing

    @TC12
    Scenario: Add email with invalid email format in AccountEmail object
    Given an existing account with a valid accountId
    And an AccountEmail object with an invalid email address (e.g., 'not-an-email')
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 400
    And the response body should indicate invalid email format

    @TC13
    Scenario: Add email with missing X-Killbill-CreatedBy header
    Given an existing account with a valid accountId
    And a valid AccountEmail object in the request body
    And the X-Killbill-CreatedBy header is missing
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 400 or 401 depending on API behavior
    And the response body should indicate a missing required header

    @TC14
    Scenario: Add email with unauthorized access (invalid token or credentials)
    Given an existing account with a valid accountId
    And a valid AccountEmail object in the request body
    And an invalid or missing authentication token (if required)
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 401 or 403 depending on API behavior
    And the response body should indicate unauthorized access

    @TC15
    Scenario: Add email when external service (e.g., email validation or DB) is unavailable
    Given an existing account with a valid accountId
    And a valid AccountEmail object in the request body
    And the external dependency (e.g., DB or email validation service) is down
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 503
    And the response body should indicate service unavailability

    @TC16
    Scenario: Add email with large payload (boundary test)
    Given an existing account with a valid accountId
    And an AccountEmail object with maximum allowed field sizes
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201 or 400 depending on API limits
    And the response should document acceptance or rejection of large payload

    @TC17
    Scenario: Add email with empty request body
    Given an existing account with a valid accountId
    And an empty request body
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 400
    And the response body should indicate a missing or malformed request body

    @TC18
    Scenario: Add email with additional, unexpected query parameters
    Given an existing account with a valid accountId
    And a valid AccountEmail object in the request body
    And additional query parameters are present in the URL
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails?foo=bar
    Then the response status code should be 201 or 400 depending on API behavior
    And the response should document acceptance or rejection of extra query parameters

    @TC19
    Scenario: Add email with slow database or degraded system performance
    Given an existing account with a valid accountId
    And a valid AccountEmail object in the request body
    And the database is responding slowly
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201 (if successful) or 503 (if timeout)
    And the response time should be measured and within acceptable thresholds if successful

    @TC20
    Scenario: Add email with concurrent requests
    Given an existing account with a valid accountId
    And multiple valid AccountEmail objects
    When multiple users send concurrent POST requests to /1.0/kb/accounts/{accountId}/emails
    Then all requests should be handled correctly
    And each response should return 201 if successful
    And the database should reflect all added emails without duplication or data loss

    @TC21
    Scenario: Regression - Add email with previously problematic input (e.g., unicode characters)
    Given an existing account with a valid accountId
    And an AccountEmail object with unicode or special characters in the email
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201 or 400 depending on API validation
    And the response should document acceptance or rejection of such input

    @TC22
    Scenario: Regression - Add email to ensure backward compatibility
    Given an existing account created with an older API version
    And a valid AccountEmail object in the request body
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201
    And the response body should contain the AccountEmail object

    @TC23
    Scenario: Security - Add email with SQL injection attempt in email field
    Given an existing account with a valid accountId
    And an AccountEmail object with a SQL injection payload in the email field
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 400 or 422 depending on API behavior
    And the response should indicate rejection of malicious input

    @TC24
    Scenario: Security - Add email with XSS attempt in email field
    Given an existing account with a valid accountId
    And an AccountEmail object with a script tag in the email field
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 400 or 422 depending on API behavior
    And the response should indicate rejection of malicious input

    @TC25
    Scenario: Recovery from transient network failure
    Given an existing account with a valid accountId
    And a valid AccountEmail object in the request body
    And a transient network failure occurs during the request
    When the user retries the POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201 if successful after retry
    And the response body should contain the AccountEmail object

    @TC26
    Scenario: Integration - Add email and verify consistency across dependent systems
    Given an existing account with a valid accountId
    And a valid AccountEmail object in the request body
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201
    And the email should be visible via subsequent GET requests to the account's emails endpoint
    And the email should be propagated to integrated downstream systems if applicable

    @TC27
    Scenario: Accessibility - Ensure API documentation and error messages are clear
    Given an existing account with a valid accountId
    And a valid AccountEmail object in the request body
    When the user sends a POST request to /1.0/kb/accounts/{accountId}/emails
    Then the response status code should be 201
    And all error messages (if any) should be descriptive and accessible
    And API documentation should provide clear guidance on required fields and error handling