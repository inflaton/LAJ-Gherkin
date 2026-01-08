Feature: Close Account API (DELETE /1.0/kb/accounts/{accountId})
As a KillBill API user,
I want to close an account via the API,
so that the account is deactivated and optional cleanup actions are performed as specified.

  Background:
  Given the KillBill API service is running and accessible
  And the database is seeded with a variety of accounts, including:
    | accountId (valid) | accountId (invalid) | accountId (already closed) |
    | ---------------- | ------------------ | ------------------------- |
    | valid-uuid-1     | invalid-uuid-1     | closed-uuid-1             |
  And all dependent services (subscriptions, invoices, notifications) are mocked or available
  And an authentication token is present and valid
  And the following headers are set for all requests:
    | Header                   | Value           |
    | ------------------------| --------------- |
    | X-Killbill-CreatedBy    | test-user       |
    | X-Killbill-Reason       | (optional)      |
    | X-Killbill-Comment      | (optional)      |

  @TC01
  Scenario: Successful account closure with default parameters
    Given an account with id 'valid-uuid-1' exists and is active
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with no query parameters
    Then the response status should be 204
    And the account 'valid-uuid-1' should be marked as closed in the database
    And no subscriptions should be cancelled
    And no unpaid invoices should be written off or item adjusted
    And all future notifications for the account should be removed

  @TC02
  Scenario: Successful account closure with all optional parameters set to true
    Given an account with id 'valid-uuid-1' exists and is active
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameters:
      | cancelAllSubscriptions=true |
      | writeOffUnpaidInvoices=true |
      | itemAdjustUnpaidInvoices=true |
      | removeFutureNotifications=true |
    Then the response status should be 204
    And all active subscriptions for 'valid-uuid-1' should be cancelled
    And all unpaid invoices should be written off and item adjusted
    And all future notifications should be removed

  @TC03
  Scenario: Successful account closure with all optional parameters set to false
    Given an account with id 'valid-uuid-1' exists and is active
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameters:
      | cancelAllSubscriptions=false |
      | writeOffUnpaidInvoices=false |
      | itemAdjustUnpaidInvoices=false |
      | removeFutureNotifications=false |
    Then the response status should be 204
    And no subscriptions should be cancelled
    And no unpaid invoices should be written off or item adjusted
    And future notifications for the account should not be removed

  @TC04
  Scenario: Successful account closure with each optional parameter individually set to true
    Given an account with id 'valid-uuid-1' exists and is active
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameter cancelAllSubscriptions=true
    Then the response status should be 204
    And all active subscriptions for 'valid-uuid-1' should be cancelled
    And other default actions should occur as per default values

    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameter writeOffUnpaidInvoices=true
    Then the response status should be 204
    And all unpaid invoices should be written off
    And other default actions should occur as per default values

    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameter itemAdjustUnpaidInvoices=true
    Then the response status should be 204
    And all unpaid invoices should be item adjusted
    And other default actions should occur as per default values

    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameter removeFutureNotifications=false
    Then the response status should be 204
    And future notifications for the account should not be removed
    And other default actions should occur as per default values

  @TC05
  Scenario: Successful account closure with all combinations of two optional parameters set to true
    Given an account with id 'valid-uuid-1' exists and is active
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameters:
      | cancelAllSubscriptions=true | writeOffUnpaidInvoices=true |
    Then the response status should be 204
    And all active subscriptions cancelled and all unpaid invoices written off

    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameters:
      | cancelAllSubscriptions=true | itemAdjustUnpaidInvoices=true |
    Then the response status should be 204
    And all active subscriptions cancelled and all unpaid invoices item adjusted

    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameters:
      | cancelAllSubscriptions=true | removeFutureNotifications=false |
    Then the response status should be 204
    And all active subscriptions cancelled and future notifications not removed

    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameters:
      | writeOffUnpaidInvoices=true | itemAdjustUnpaidInvoices=true |
    Then the response status should be 204
    And all unpaid invoices written off and item adjusted

    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameters:
      | writeOffUnpaidInvoices=true | removeFutureNotifications=false |
    Then the response status should be 204
    And all unpaid invoices written off and future notifications not removed

    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameters:
      | itemAdjustUnpaidInvoices=true | removeFutureNotifications=false |
    Then the response status should be 204
    And all unpaid invoices item adjusted and future notifications not removed

  @TC06
  Scenario: Account closure when account has no subscriptions or invoices
    Given an account with id 'valid-uuid-2' exists, is active, and has no subscriptions or invoices
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-2
    Then the response status should be 204
    And the account should be marked as closed
    And no errors should occur

  @TC07
  Scenario: Account closure when account has large number of subscriptions and invoices
    Given an account with id 'valid-uuid-3' exists, is active, and has 1000 subscriptions and 1000 invoices
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-3 with cancelAllSubscriptions=true and writeOffUnpaidInvoices=true
    Then the response status should be 204
    And all subscriptions and invoices should be processed accordingly within acceptable response time

  @TC08
  Scenario: Attempt to close account with invalid accountId format
    Given the user sends a DELETE request to /1.0/kb/accounts/invalid-uuid-1
    When the accountId does not match the required uuid pattern
    Then the response status should be 400
    And the response body should contain an error message indicating invalid accountId

  @TC09
  Scenario: Attempt to close account with missing X-Killbill-CreatedBy header
    Given an account with id 'valid-uuid-1' exists and is active
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 without the X-Killbill-CreatedBy header
    Then the response status should be 400
    And the response body should indicate the missing required header

  @TC10
  Scenario: Attempt to close account with missing or invalid authentication
    Given an account with id 'valid-uuid-1' exists and is active
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 without authentication
    Then the response status should be 401
    And the response body should indicate unauthorized access

    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with an invalid authentication token
    Then the response status should be 401
    And the response body should indicate unauthorized access

  @TC11
  Scenario: Attempt to close an already closed account
    Given an account with id 'closed-uuid-1' exists and is already closed
    When the user sends a DELETE request to /1.0/kb/accounts/closed-uuid-1
    Then the response status should be 204
    And the operation should be idempotent (no further changes)

  @TC12
  Scenario: Attempt to close a non-existent account
    Given the user sends a DELETE request to /1.0/kb/accounts/nonexistent-uuid-1
    When the account does not exist in the system
    Then the response status should be 204
    And the operation should be idempotent (no error, no changes)

  @TC13
  Scenario: Attempt to close account with extra, unsupported query parameters
    Given an account with id 'valid-uuid-1' exists and is active
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with query parameter foo=bar
    Then the response status should be 204
    And the extra parameter should be ignored

  @TC14
  Scenario: System error during account closure (e.g., database unavailable)
    Given an account with id 'valid-uuid-1' exists and is active
    And the database is unavailable
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1
    Then the response status should be 500
    And the response body should indicate an internal server error

  @TC15
  Scenario: Security test - SQL injection attempt in accountId
    Given the user sends a DELETE request to /1.0/kb/accounts/1;DROP TABLE accounts;
    When the accountId contains SQL injection payload
    Then the response status should be 400
    And the response body should indicate invalid accountId
    And no data should be compromised

  @TC16
  Scenario: Security test - XSS attempt in header values
    Given an account with id 'valid-uuid-1' exists and is active
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-1 with X-Killbill-Comment set to '<script>alert(1)</script>'
    Then the response status should be 204
    And the input should be sanitized or ignored
    And no XSS vulnerability should be present

  @TC17
  Scenario: Timeout and retry on transient network failure
    Given an account with id 'valid-uuid-1' exists and is active
    And a transient network failure occurs during the DELETE request
    When the user retries the request
    Then the response status should be 204
    And the operation should be idempotent

  @TC18
  Scenario: Performance test - concurrent account closures
    Given 10 accounts with unique ids exist and are active
    When 10 users concurrently send DELETE requests to /1.0/kb/accounts/{accountId}
    Then all responses should be 204
    And all accounts should be closed within acceptable response time

  @TC19
  Scenario: Regression - previously fixed bug: account closure with unpaid invoices
    Given an account with id 'valid-uuid-4' exists, is active, and has unpaid invoices
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-4 with writeOffUnpaidInvoices=true
    Then the response status should be 204
    And all unpaid invoices should be written off
    And no regression of previous bug

  @TC20
  Scenario: Regression - backward compatibility with old clients (no optional headers)
    Given an account with id 'valid-uuid-5' exists and is active
    When the user sends a DELETE request to /1.0/kb/accounts/valid-uuid-5 with only required headers
    Then the response status should be 204
    And the account should be closed successfully

  @TC21
  Scenario: Accessibility - verify API documentation and error responses
    Given the API documentation is available
    When a user with assistive technology accesses the documentation and error responses
    Then all documentation and responses should be readable and accessible
    And error messages should be clear and descriptive