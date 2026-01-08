Feature: Delete all versions of catalog for a tenant via DELETE /1.0/kb/catalog
As an authenticated KillBill API user,
I want to delete all versions of the catalog for my tenant,
so that I can remove catalog data as needed.

  Background:
  Given the KillBill API endpoint {{baseUrl}}/1.0/kb/catalog is available
  And the tenant exists in the system
  And I have a valid authentication token
  And the database is seeded with multiple catalog versions for the tenant

    @TC01
    Scenario: Successful deletion of all catalog versions with required header
    Given the tenant has multiple catalog versions
    And I set the X-Killbill-CreatedBy header to a valid username
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 204
    And all catalog versions for the tenant should be deleted from the system
    And subsequent GET requests to /1.0/kb/catalog should return an empty result or 404

    @TC02
    Scenario: Successful deletion with all optional headers provided
    Given the tenant has multiple catalog versions
    And I set the X-Killbill-CreatedBy header to a valid username
    And I set the X-Killbill-Reason header to a valid reason string
    And I set the X-Killbill-Comment header to a valid comment string
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 204
    And all catalog versions for the tenant should be deleted from the system

    @TC03
    Scenario: Attempt deletion with missing required header X-Killbill-CreatedBy
    Given the tenant has multiple catalog versions
    And I do not set the X-Killbill-CreatedBy header
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 400 or 401
    And the response body should indicate the missing required header
    And no catalog versions should be deleted

    @TC04
    Scenario: Attempt deletion with invalid authentication token
    Given the tenant has multiple catalog versions
    And I set the X-Killbill-CreatedBy header to a valid username
    And I use an invalid or expired authentication token
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 401
    And the response body should indicate unauthorized access
    And no catalog versions should be deleted

    @TC05
    Scenario: Attempt deletion for a tenant with no catalog versions
    Given the tenant exists but has no catalog versions
    And I set the X-Killbill-CreatedBy header to a valid username
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 204
    And the system should remain unchanged

    @TC06
    Scenario: Attempt deletion for a non-existent tenant
    Given the tenant does not exist in the system
    And I set the X-Killbill-CreatedBy header to a valid username
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 404
    And the response body should indicate tenant not found
    And no catalog versions should be deleted

    @TC07
    Scenario: Attempt deletion with malformed or unsupported header values
    Given the tenant has multiple catalog versions
    And I set the X-Killbill-CreatedBy header to an empty string
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 400
    And the response body should indicate invalid header value
    And no catalog versions should be deleted

    @TC08
    Scenario: Attempt deletion with extra, unexpected headers
    Given the tenant has multiple catalog versions
    And I set the X-Killbill-CreatedBy header to a valid username
    And I set additional unsupported headers
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 204
    And all catalog versions for the tenant should be deleted from the system

    @TC09
    Scenario: System error occurs during deletion (e.g., database unavailable)
    Given the database is unavailable or the service is down
    And I set the X-Killbill-CreatedBy header to a valid username
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 500
    And the response body should indicate an internal server error
    And no catalog versions should be deleted

    @TC10
    Scenario: Attempt deletion with large number of catalog versions (performance)
    Given the tenant has a large number of catalog versions (e.g., thousands)
    And I set the X-Killbill-CreatedBy header to a valid username
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 204
    And all catalog versions for the tenant should be deleted within acceptable response time (e.g., < 2 seconds)

    @TC11
    Scenario: Attempt deletion with injection or malicious payload in headers
    Given the tenant has multiple catalog versions
    And I set the X-Killbill-CreatedBy header to a string containing SQL injection or script tags
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 400 or 422
    And the response body should indicate invalid header value or security violation
    And no catalog versions should be deleted

    @TC12
    Scenario: Regression - previously fixed bug: deletion leaves orphaned references
    Given the tenant has catalog versions and related data
    And I set the X-Killbill-CreatedBy header to a valid username
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 204
    And all catalog versions and their references should be deleted
    And no orphaned references should remain in the system

    @TC13
    Scenario: Concurrent deletion requests
    Given the tenant has multiple catalog versions
    And I set the X-Killbill-CreatedBy header to a valid username
    When I send multiple concurrent DELETE requests to /1.0/kb/catalog
    Then only one request should succeed with 204 and others should receive 204 or appropriate error (e.g., 404 if already deleted)
    And the system should remain in a consistent state

    @TC14
    Scenario: Attempt deletion with partial header set (only optional headers, missing required)
    Given the tenant has multiple catalog versions
    And I set the X-Killbill-Reason header to a valid reason string
    And I do not set the X-Killbill-CreatedBy header
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 400 or 401
    And the response body should indicate the missing required header
    And no catalog versions should be deleted

    @TC15
    Scenario: DELETE request with request body present (should be ignored)
    Given the tenant has multiple catalog versions
    And I set the X-Killbill-CreatedBy header to a valid username
    And I include a random JSON body in the request
    When I send a DELETE request to /1.0/kb/catalog
    Then the response status code should be 204
    And all catalog versions for the tenant should be deleted
    And the request body should be ignored by the server