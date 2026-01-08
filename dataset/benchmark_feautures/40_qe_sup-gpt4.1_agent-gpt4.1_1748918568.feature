Feature: Transfer credit from child account to parent account via PUT /1.0/kb/accounts/{childAccountId}/transferCredit
As a KillBill API user,
I want to transfer credit from a child account to its parent account,
so that the parent account can utilize the available credit.

  Background:
  Given the KillBill API server is running
  And the API endpoint /1.0/kb/accounts/{childAccountId}/transferCredit is available
  And the database contains both child and parent accounts with various credit states
  And valid authentication and authorization tokens are configured
  And the required headers (X-Killbill-CreatedBy) are available for requests

    @TC01
    Scenario: Successful credit transfer from child to parent account
    Given a child account with a valid UUID and available credit
    And the child account has a valid parent account
    And the request includes header X-Killbill-CreatedBy with a valid value
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 204
    And the child's credit balance should be reduced by the transferred amount
    And the parent's credit balance should be increased by the transferred amount

    @TC02
    Scenario: Successful credit transfer with optional headers
    Given a child account with a valid UUID and available credit
    And the child account has a valid parent account
    And the request includes headers X-Killbill-CreatedBy, X-Killbill-Reason, and X-Killbill-Comment
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 204
    And the transfer reason and comment are recorded in the audit logs

    @TC03
    Scenario: Attempt to transfer credit when child account has no credit
    Given a child account with a valid UUID and zero credit
    And the child account has a valid parent account
    And the request includes header X-Killbill-CreatedBy
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 400
    And the response body should include an error message indicating insufficient credit

    @TC04
    Scenario: Attempt to transfer credit from non-existent child account
    Given a non-existent childAccountId
    And the request includes header X-Killbill-CreatedBy
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 404
    And the response body should include an error message indicating child account not found

    @TC05
    Scenario: Attempt to transfer credit when parent account does not exist
    Given a child account with a valid UUID and available credit
    And the child account references a non-existent parent account
    And the request includes header X-Killbill-CreatedBy
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 404
    And the response body should include an error message indicating parent account not found

    @TC06
    Scenario: Attempt to transfer credit with missing required header X-Killbill-CreatedBy
    Given a child account with a valid UUID and available credit
    And the child account has a valid parent account
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit without X-Killbill-CreatedBy
    Then the response status code should be 400
    And the response body should include an error message indicating missing required header

    @TC07
    Scenario: Attempt to transfer credit with malformed childAccountId
    Given a malformed childAccountId that does not match the UUID pattern
    And the request includes header X-Killbill-CreatedBy
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 400
    And the response body should include an error message indicating invalid childAccountId format

    @TC08
    Scenario: Attempt to transfer credit with extra, unsupported headers
    Given a child account with a valid UUID and available credit
    And the child account has a valid parent account
    And the request includes header X-Killbill-CreatedBy and extra unsupported headers
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 204
    And the extra headers are ignored

    @TC09
    Scenario: Attempt to transfer credit when API is unavailable
    Given the KillBill API server is down or unreachable
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 503 or appropriate network error
    And the response body should indicate service unavailable

    @TC10
    Scenario: Attempt to transfer credit with unauthorized access
    Given a child account with a valid UUID and available credit
    And the user does not have valid authentication or authorization
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 401 or 403
    And the response body should indicate unauthorized or forbidden access

    @TC11
    Scenario: Attempt to transfer credit with injection or malicious payload in headers
    Given a child account with a valid UUID and available credit
    And the child account has a valid parent account
    And the request includes header X-Killbill-CreatedBy with a malicious payload
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 400 or 422
    And the response body should indicate invalid input or security violation

    @TC12
    Scenario: Attempt to transfer credit when database is empty
    Given the database has no child or parent accounts
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 404
    And the response body should indicate account not found

    @TC13
    Scenario: Attempt to transfer credit with very large number of accounts (performance)
    Given the database contains a large number of child and parent accounts
    And a child account with available credit is selected
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 204
    And the response time should be within acceptable thresholds (e.g., < 2 seconds)

    @TC14
    Scenario: Attempt to transfer credit concurrently from the same child account
    Given a child account with a valid UUID and available credit
    And multiple concurrent PUT requests are sent to /1.0/kb/accounts/{childAccountId}/transferCredit
    When the requests are processed
    Then only one request should succeed with status code 204
    And the others should fail with status code 400 due to insufficient credit

    @TC15
    Scenario: Attempt to transfer credit with partial or unexpected input formats in headers
    Given a child account with a valid UUID and available credit
    And the child account has a valid parent account
    And the request includes header X-Killbill-CreatedBy with unexpected format (e.g., empty string, special characters)
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 400 or 422
    And the response body should indicate invalid header value

    @TC16
    Scenario: Regression: Previously fixed bug - double transfer of same credit
    Given a child account with a valid UUID and available credit
    And the child account has a valid parent account
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit twice in succession
    Then the first request should succeed with status code 204
    And the second request should fail with status code 400 due to insufficient credit

    @TC17
    Scenario: API backward compatibility
    Given a child account with a valid UUID and available credit
    And the child account has a valid parent account
    And the request is made with a client using a previous API version (if supported)
    When the user sends a PUT request to /1.0/kb/accounts/{childAccountId}/transferCredit
    Then the response status code should be 204
    And the transfer should process as expected