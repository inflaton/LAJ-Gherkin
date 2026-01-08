Feature: Invalidate Account-Level Caches via DELETE /1.0/kb/admin/cache/accounts/{accountId}
  As an administrator,
  I want to invalidate caches for a specific account,
  so that I can troubleshoot or apply configuration changes efficiently.

    Background:
    Given the KillBill API server is running and accessible
    And the requester has valid admin authentication credentials
    And the database is seeded with accounts including at least one valid account with a known UUID
    And the API endpoint /1.0/kb/admin/cache/accounts/{accountId} is available

      @TC01
      Scenario: Successful cache invalidation for a valid account
      Given an account exists with accountId "1111-2222-3333-4444-5555"
      And the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/1111-2222-3333-4444-5555
      Then the response status code should be 204
      And the response body should be empty
      And the caches for accountId "1111-2222-3333-4444-5555" should be invalidated

      @TC02
      Scenario: Attempt to invalidate cache with a non-existent accountId
      Given no account exists with accountId "9999-8888-7777-6666-5555"
      And the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/9999-8888-7777-6666-5555
      Then the response status code should be 404
      And the response body should contain an error message indicating account not found

      @TC03
      Scenario: Attempt to invalidate cache with an invalid accountId format
      Given the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/invalid-uuid
      Then the response status code should be 400
      And the response body should contain an error message indicating invalid accountId format

      @TC04
      Scenario: Attempt to invalidate cache with a missing accountId in the path
      Given the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/
      Then the response status code should be 404
      And the response body should contain an error message indicating missing accountId

      @TC05
      Scenario: Attempt to invalidate cache without authentication
      Given an account exists with accountId "1111-2222-3333-4444-5555"
      And the requester is not authenticated
      When the requester sends a DELETE request to /1.0/kb/admin/cache/accounts/1111-2222-3333-4444-5555
      Then the response status code should be 401
      And the response body should contain an error message indicating authentication failure

      @TC06
      Scenario: Attempt to invalidate cache with expired or invalid authentication token
      Given an account exists with accountId "1111-2222-3333-4444-5555"
      And the requester provides an expired or invalid authentication token
      When the requester sends a DELETE request to /1.0/kb/admin/cache/accounts/1111-2222-3333-4444-5555
      Then the response status code should be 401
      And the response body should contain an error message indicating authentication failure

      @TC07
      Scenario: Attempt to invalidate cache when the system is under degraded performance
      Given an account exists with accountId "1111-2222-3333-4444-5555"
      And the system is experiencing high load or degraded performance
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/1111-2222-3333-4444-5555
      Then the response status code should be 204 or 503
      And if 503, the response body should contain an error message indicating service unavailable

      @TC08
      Scenario: Attempt to invalidate cache when dependent cache service is unavailable
      Given an account exists with accountId "1111-2222-3333-4444-5555"
      And the cache service is down or unreachable
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/1111-2222-3333-4444-5555
      Then the response status code should be 503
      And the response body should contain an error message indicating cache service unavailable

      @TC09
      Scenario: Attempt to invalidate cache with extra query parameters
      Given an account exists with accountId "1111-2222-3333-4444-5555"
      And the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/1111-2222-3333-4444-5555?extra=param
      Then the response status code should be 204
      And the response body should be empty

      @TC10
      Scenario: Attempt to invalidate cache with a very large or maximum-length accountId
      Given the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
      Then the response status code should be 404 or 400
      And the response body should contain an appropriate error message

      @TC11
      Scenario: Attempt to invalidate cache using unsupported HTTP methods
      Given an account exists with accountId "1111-2222-3333-4444-5555"
      And the requester is authenticated as an admin
      When the admin sends a GET request to /1.0/kb/admin/cache/accounts/1111-2222-3333-4444-5555
      Then the response status code should be 405
      And the response body should contain an error message indicating method not allowed

      @TC12
      Scenario: Regression - Previously fixed issue with invalid UUID patterns
      Given the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/abcd
      Then the response status code should be 400
      And the response body should contain an error message indicating invalid accountId format

      @TC13
      Scenario: Performance - Invalidate cache under concurrent DELETE requests
      Given multiple valid accounts exist
      And the requester is authenticated as an admin
      When the admin sends concurrent DELETE requests to /1.0/kb/admin/cache/accounts/{accountId} for each account
      Then each response status code should be 204
      And each response body should be empty
      And the average response time should be within 500ms

      @TC14
      Scenario: Security - Attempt SQL injection via accountId
      Given the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/1111-2222-3333-4444-5555%27%20OR%20%271%27=%271
      Then the response status code should be 400
      And the response body should contain an error message indicating invalid accountId format

      @TC15
      Scenario: Security - Attempt XSS via accountId
      Given the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/<script>alert(1)</script>
      Then the response status code should be 400
      And the response body should contain an error message indicating invalid accountId format

      @TC16
      Scenario: Edge Case - No accounts in the system
      Given the database contains no accounts
      And the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/1111-2222-3333-4444-5555
      Then the response status code should be 404
      And the response body should contain an error message indicating account not found

      @TC17
      Scenario: Edge Case - System recovers from a transient network failure
      Given an account exists with accountId "1111-2222-3333-4444-5555"
      And the requester is authenticated as an admin
      And the network connection is temporarily lost and then restored
      When the admin retries the DELETE request to /1.0/kb/admin/cache/accounts/1111-2222-3333-4444-5555
      Then the response status code should be 204
      And the response body should be empty

      @TC18
      Scenario: State Variation - Partially populated database
      Given the database contains some accounts but not accountId "9999-8888-7777-6666-5555"
      And the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/9999-8888-7777-6666-5555
      Then the response status code should be 404
      And the response body should contain an error message indicating account not found

      @TC19
      Scenario: Regression - Backward compatibility with previous DELETE endpoint usage
      Given an account exists with accountId "1111-2222-3333-4444-5555"
      And the requester is authenticated as an admin
      When the admin sends a DELETE request to /1.0/kb/admin/cache/accounts/1111-2222-3333-4444-5555
      Then the response status code should be 204
      And the response body should be empty
      And no regression issues should occur compared to previous releases