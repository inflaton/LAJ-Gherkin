Feature: Invalidate System Caches via DELETE /1.0/kb/admin/cache
As an administrator,
I want to invalidate specific or all system caches via an API,
so that I can manage cache consistency and system performance.

  Background:
  Given the KillBill system is running and accessible
  And I am authenticated as an admin user with valid credentials
  And the API endpoint DELETE /1.0/kb/admin/cache is reachable
  And the system contains multiple caches with known names and states

    @TC01
    Scenario: Successfully invalidate all caches (no cacheName parameter)
    Given there are multiple caches populated in the system
    When I send a DELETE request to /1.0/kb/admin/cache without any query parameters
    Then the response status code should be 204
    And all caches should be invalidated
    And the response body should be empty

    @TC02
    Scenario: Successfully invalidate a specific cache by name
    Given a cache named "accounts" exists and is alive in the system
    When I send a DELETE request to /1.0/kb/admin/cache?cacheName=accounts
    Then the response status code should be 204
    And only the "accounts" cache should be invalidated
    And the response body should be empty

    @TC03
    Scenario: Attempt to invalidate a cache that does not exist
    Given a cache named "nonexistent" does not exist in the system
    When I send a DELETE request to /1.0/kb/admin/cache?cacheName=nonexistent
    Then the response status code should be 400
    And the response should contain an error message indicating the cache does not exist
    And no caches should be invalidated

    @TC04
    Scenario: Attempt to invalidate a cache that exists but is not alive
    Given a cache named "expiredCache" exists but is not alive
    When I send a DELETE request to /1.0/kb/admin/cache?cacheName=expiredCache
    Then the response status code should be 400
    And the response should contain an error message indicating the cache is not alive
    And no caches should be invalidated

    @TC05
    Scenario: Attempt to invalidate with an empty cacheName parameter
    Given there are multiple caches in the system
    When I send a DELETE request to /1.0/kb/admin/cache?cacheName=
    Then the response status code should be 400
    And the response should contain an error message indicating invalid cacheName
    And no caches should be invalidated

    @TC06
    Scenario: Unauthorized access to invalidate caches
    Given I am not authenticated or provide an invalid authentication token
    When I send a DELETE request to /1.0/kb/admin/cache
    Then the response status code should be 401 or 403
    And the response should contain an error message indicating authentication failure
    And no caches should be invalidated

    @TC07
    Scenario: System error during cache invalidation
    Given the cache subsystem is unavailable or encounters an internal error
    When I send a DELETE request to /1.0/kb/admin/cache
    Then the response status code should be 500
    And the response should contain an error message indicating a server error
    And no caches should be invalidated

    @TC08
    Scenario: Invalidate caches when no caches exist
    Given the system has no caches configured or all caches are empty
    When I send a DELETE request to /1.0/kb/admin/cache
    Then the response status code should be 204
    And the response body should be empty

    @TC09
    Scenario: Invalidate caches with extra unsupported query parameters
    Given there are multiple caches in the system
    When I send a DELETE request to /1.0/kb/admin/cache?foo=bar
    Then the response status code should be 204
    And all caches should be invalidated
    And the response body should be empty

    @TC10
    Scenario: Invalidate caches with a very large cacheName value
    Given there are multiple caches in the system
    When I send a DELETE request to /1.0/kb/admin/cache?cacheName=<string of 1024 characters>
    Then the response status code should be 400
    And the response should contain an error message indicating invalid cacheName
    And no caches should be invalidated

    @TC11
    Scenario: Invalidate caches with special characters in cacheName
    Given there are multiple caches in the system
    When I send a DELETE request to /1.0/kb/admin/cache?cacheName=accounts%20drop%20table
    Then the response status code should be 400
    And the response should contain an error message indicating invalid cacheName
    And no caches should be invalidated

    @TC12
    Scenario: Invalidate caches with mixed-case cacheName
    Given a cache named "Accounts" exists in the system (case-sensitive)
    When I send a DELETE request to /1.0/kb/admin/cache?cacheName=accounts
    Then the response status code should be 400
    And the response should contain an error message indicating the cache does not exist (if case-sensitive)
    And no caches should be invalidated

    @TC13
    Scenario: Performance - Invalidate all caches with a large number of caches
    Given the system contains 1000 caches
    When I send a DELETE request to /1.0/kb/admin/cache
    Then the response status code should be 204
    And all caches should be invalidated within acceptable response time (e.g., < 2 seconds)
    And the response body should be empty

    @TC14
    Scenario: Concurrent requests to invalidate all caches
    Given the system contains multiple caches
    When I send 10 concurrent DELETE requests to /1.0/kb/admin/cache
    Then each response status code should be 204
    And all caches should be invalidated
    And the system should remain stable with no errors

    @TC15
    Scenario: Regression - Previously fixed issue with invalid cacheName format
    Given a previously problematic cacheName format (e.g., "acc#ounts")
    When I send a DELETE request to /1.0/kb/admin/cache?cacheName=acc#ounts
    Then the response status code should be 400
    And the response should contain an error message indicating invalid cacheName
    And no caches should be invalidated