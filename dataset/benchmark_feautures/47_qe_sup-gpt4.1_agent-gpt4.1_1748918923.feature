Feature: Invalidate Tenant-Level Caches via DELETE /1.0/kb/admin/cache/tenants
As an administrator,
I want to invalidate tenant-level caches,
so that I can ensure cache consistency for the current tenant context.

  Background:
  Given the KillBill system is running and accessible
  And the API endpoint DELETE /1.0/kb/admin/cache/tenants is available
  And the request is authenticated with valid admin credentials for a specific tenant
  And the tenant context is properly set (e.g., via header or token)

    @TC01
    Scenario: Successful cache invalidation for tenant
    Given the tenant cache contains valid data
    When the administrator sends a DELETE request to /1.0/kb/admin/cache/tenants
    Then the API responds with HTTP status 204
    And the response body is empty
    And the tenant cache is invalidated
    And subsequent requests reflect the cache invalidation

    @TC02
    Scenario: Attempt to invalidate cache without authentication
    Given the tenant cache contains valid data
    And the request is missing authentication headers
    When a DELETE request is sent to /1.0/kb/admin/cache/tenants
    Then the API responds with HTTP status 401
    And the response body contains an error message indicating unauthorized access

    @TC03
    Scenario: Attempt to invalidate cache with invalid authentication
    Given the tenant cache contains valid data
    And the request contains invalid authentication credentials
    When a DELETE request is sent to /1.0/kb/admin/cache/tenants
    Then the API responds with HTTP status 401
    And the response body contains an error message indicating unauthorized access

    @TC04
    Scenario: Attempt to invalidate cache for a non-existent tenant context
    Given the request is authenticated with valid admin credentials
    And the tenant context is set to a non-existent tenant
    When a DELETE request is sent to /1.0/kb/admin/cache/tenants
    Then the API responds with HTTP status 404
    And the response body contains an error message indicating tenant not found

    @TC05
    Scenario: System error during cache invalidation
    Given the request is authenticated with valid admin credentials
    And the system encounters an internal error during cache invalidation
    When a DELETE request is sent to /1.0/kb/admin/cache/tenants
    Then the API responds with HTTP status 500
    And the response body contains an error message indicating internal server error

    @TC06
    Scenario: Service unavailable during cache invalidation
    Given the request is authenticated with valid admin credentials
    And the cache service is temporarily unavailable
    When a DELETE request is sent to /1.0/kb/admin/cache/tenants
    Then the API responds with HTTP status 503
    And the response body contains an error message indicating service unavailable

    @TC07
    Scenario: Malformed request with extra parameters
    Given the request is authenticated with valid admin credentials
    And the request includes unsupported query parameters or payload
    When a DELETE request is sent to /1.0/kb/admin/cache/tenants with extra parameters
    Then the API responds with HTTP status 400
    And the response body contains an error message indicating bad request

    @TC08
    Scenario: Security test - injection attempt in headers
    Given the request is authenticated with admin credentials
    And the request headers contain a malicious payload (e.g., SQL injection attempt)
    When a DELETE request is sent to /1.0/kb/admin/cache/tenants
    Then the API responds with HTTP status 400 or 403
    And the response body contains an error message indicating invalid input or forbidden

    @TC09
    Scenario: Edge case - cache already empty
    Given the tenant cache is already empty
    When the administrator sends a DELETE request to /1.0/kb/admin/cache/tenants
    Then the API responds with HTTP status 204
    And the response body is empty
    And the operation is idempotent

    @TC10
    Scenario: Performance - invalidate cache under load
    Given the system is under normal operational load
    When multiple concurrent DELETE requests are sent to /1.0/kb/admin/cache/tenants for the same tenant
    Then each API response is HTTP 204
    And the response time is within acceptable thresholds (e.g., < 2 seconds)
    And no data corruption or race conditions occur

    @TC11
    Scenario: Regression - previously fixed error does not recur
    Given the system previously had a bug where cache was not invalidated on DELETE
    When the administrator sends a DELETE request to /1.0/kb/admin/cache/tenants
    Then the API responds with HTTP status 204
    And the tenant cache is actually invalidated

    @TC12
    Scenario: Integration - cache invalidation reflected in dependent services
    Given the request is authenticated with valid admin credentials
    And dependent services consume tenant cache data
    When the administrator sends a DELETE request to /1.0/kb/admin/cache/tenants
    Then dependent services observe the cache invalidation
    And no stale data is returned from dependent services

    @TC13
    Scenario: State variation - partially populated tenant cache
    Given the tenant cache contains a mix of valid and expired entries
    When the administrator sends a DELETE request to /1.0/kb/admin/cache/tenants
    Then the API responds with HTTP status 204
    And all cache entries for the tenant are invalidated

    @TC14
    Scenario: Timeout during cache invalidation
    Given the request is authenticated with valid admin credentials
    And the cache invalidation process takes longer than the configured timeout
    When a DELETE request is sent to /1.0/kb/admin/cache/tenants
    Then the API responds with HTTP status 504
    And the response body contains an error message indicating gateway timeout