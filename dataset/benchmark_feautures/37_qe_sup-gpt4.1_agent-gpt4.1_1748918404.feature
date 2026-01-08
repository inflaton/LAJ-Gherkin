Feature: Delete email from account via DELETE /1.0/kb/accounts/{accountId}/emails/{email}
As a KillBill API user,
I want to delete an email from an account using the DELETE endpoint,
so that I can manage account email addresses efficiently and securely.

  Background:
  Given the KillBill API is available
  And the database contains accounts with various email addresses
  And I have a valid authentication token
  And the system clock is synchronized

    @TC01
    Scenario: Successful deletion of an email from an account
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'user@example.com'
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/user@example.com
    Then the response status code should be 204
    And the email 'user@example.com' should no longer exist for account 'valid-uuid-1234-5678-9012'

    @TC02
    Scenario: Successful deletion with optional headers
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'user2@example.com'
    And header 'X-Killbill-CreatedBy' is set to 'api-admin'
    And header 'X-Killbill-Reason' is set to 'user request'
    And header 'X-Killbill-Comment' is set to 'cleanup duplicate'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/user2@example.com
    Then the response status code should be 204
    And the email 'user2@example.com' should no longer exist for account 'valid-uuid-1234-5678-9012'

    @TC03
    Scenario: Attempt to delete an email from a non-existent account
    Given no account exists with accountId 'nonexistent-uuid-0000-0000-0000'
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/nonexistent-uuid-0000-0000-0000/emails/user@example.com
    Then the response status code should be 404
    And the response body should contain an error message indicating account not found

    @TC04
    Scenario: Attempt to delete a non-existent email from an existing account
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account does not have the email 'missing@example.com'
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/missing@example.com
    Then the response status code should be 404
    And the response body should contain an error message indicating email not found

    @TC05
    Scenario: Attempt to delete with invalid accountId format
    Given an accountId 'invalid_uuid' is not in the required uuid format
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/invalid_uuid/emails/user@example.com
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId

    @TC06
    Scenario: Attempt to delete with invalid email format
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And email 'not-an-email' is not a valid email address
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/not-an-email
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid email

    @TC07
    Scenario: Attempt to delete with missing X-Killbill-CreatedBy header
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'user@example.com'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/user@example.com without the X-Killbill-CreatedBy header
    Then the response status code should be 400
    And the response body should contain an error message indicating missing required header

    @TC08
    Scenario: Attempt to delete with extra, unsupported parameters
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'user@example.com'
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/user@example.com with an extra query parameter 'foo=bar'
    Then the response status code should be 204
    And the email 'user@example.com' should no longer exist for account 'valid-uuid-1234-5678-9012'

    @TC09
    Scenario: Attempt to delete when no emails exist for the account
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has no emails
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/any@example.com
    Then the response status code should be 404
    And the response body should contain an error message indicating email not found

    @TC10
    Scenario: Attempt to delete with unauthorized access (invalid token)
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'user@example.com'
    And the authentication token is invalid or expired
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/user@example.com
    Then the response status code should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC11
    Scenario: System error during deletion (dependency failure)
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'user@example.com'
    And the email service is temporarily unavailable
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/user@example.com
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC12
    Scenario: Attempt to delete with a very large email address
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'verylongemailaddress_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@example.com'
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/verylongemailaddress_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@example.com
    Then the response status code should be 204
    And the email should no longer exist for account 'valid-uuid-1234-5678-9012'

    @TC13
    Scenario: Attempt to delete with a minimal-length email address
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'a@b.co'
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/a@b.co
    Then the response status code should be 204
    And the email should no longer exist for account 'valid-uuid-1234-5678-9012'

    @TC14
    Scenario: Deletion response time under threshold
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'user@example.com'
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/user@example.com
    Then the response status code should be 204
    And the response time should be less than 500ms

    @TC15
    Scenario: Concurrent deletion requests for the same email
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'user@example.com'
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send 5 concurrent DELETE requests to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/user@example.com
    Then one response status code should be 204
    And the remaining responses should be 404

    @TC16
    Scenario: Attempt to delete email with XSS or injection in email parameter
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'user@example.com'
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/<script>alert(1)</script>
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid email

    @TC17
    Scenario: Regression - previously fixed bug: deleting email with uppercase letters
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'User@Example.com'
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/User@Example.com
    Then the response status code should be 204
    And the email 'User@Example.com' should no longer exist for account 'valid-uuid-1234-5678-9012'

    @TC18
    Scenario: Regression - backward compatibility with previous API clients
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'legacy@example.com'
    And header 'X-Killbill-CreatedBy' is set to 'legacy-client'
    When I send a DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/legacy@example.com
    Then the response status code should be 204
    And the email 'legacy@example.com' should no longer exist for account 'valid-uuid-1234-5678-9012'

    @TC19
    Scenario: System recovers from transient network failure
    Given an account exists with accountId 'valid-uuid-1234-5678-9012'
    And the account has an email 'user@example.com'
    And header 'X-Killbill-CreatedBy' is set to 'test-user'
    And a transient network failure occurs during the first request
    When I retry the DELETE request to /1.0/kb/accounts/valid-uuid-1234-5678-9012/emails/user@example.com
    Then the response status code should be 204
    And the email 'user@example.com' should no longer exist for account 'valid-uuid-1234-5678-9012'