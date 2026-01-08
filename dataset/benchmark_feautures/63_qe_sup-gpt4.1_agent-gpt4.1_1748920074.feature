Feature: Pause a subscription bundle via PUT /1.0/kb/bundles/{bundleId}/pause
As a KillBill API user,
I want to pause a bundle and all its active subscriptions,
so that billing and subscription activity is temporarily halted as needed.

  Background:
  Given the KillBill API is available
  And the database contains multiple bundles in various states (active, paused, canceled)
  And I have a valid authentication token and necessary permissions
  And the API endpoint /1.0/kb/bundles/{bundleId}/pause is reachable

    @TC01
    Scenario: Successfully pause an active bundle with only required parameters
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 204
    And the bundle and all its active subscriptions should be in paused state

    @TC02
    Scenario: Successfully pause an active bundle with requestedDate parameter
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause with requestedDate set to a valid future date
    Then the response status code should be 204
    And the bundle should be scheduled to pause on the requestedDate

    @TC03
    Scenario: Successfully pause an active bundle with pluginProperty parameter
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause with pluginProperty set to ["prop1=value1", "prop2=value2"]
    Then the response status code should be 204
    And the plugin properties should be processed accordingly

    @TC04
    Scenario: Successfully pause an active bundle with all optional headers
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    And header X-Killbill-Reason is set to "Customer request"
    And header X-Killbill-Comment is set to "Pausing for vacation"
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 204
    And the reason and comment should be recorded in the audit logs

    @TC05
    Scenario: Successfully pause an active bundle with all parameters and headers
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    And header X-Killbill-Reason is set to "System maintenance"
    And header X-Killbill-Comment is set to "Bulk operation"
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause with requestedDate set to a valid date and pluginProperty set to ["prop1=value1"]
    Then the response status code should be 204
    And the bundle should be scheduled to pause on the requestedDate
    And the plugin properties should be processed accordingly

    @TC06
    Scenario: Attempt to pause a bundle with invalid bundleId format
    Given no bundle exists with bundleId in invalid uuid format
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid bundleId

    @TC07
    Scenario: Attempt to pause a non-existent bundle
    Given no bundle exists with bundleId in valid uuid format
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 404
    And the response body should contain an error message indicating bundle not found

    @TC08
    Scenario: Attempt to pause a bundle that is already paused
    Given a bundle exists with bundleId in paused state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 400
    And the response body should indicate the bundle cannot be paused in its current state

    @TC09
    Scenario: Attempt to pause a bundle in an invalid state (e.g., canceled)
    Given a bundle exists with bundleId in canceled state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 400
    And the response body should indicate the bundle cannot be paused in its current state

    @TC10
    Scenario: Attempt to pause a bundle with missing X-Killbill-CreatedBy header
    Given a bundle exists with bundleId in active state
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause without X-Killbill-CreatedBy header
    Then the response status code should be 400
    And the response body should indicate missing required header

    @TC11
    Scenario: Attempt to pause a bundle with an unauthorized user
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to an unauthorized user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC12
    Scenario: Attempt to pause a bundle when the service is unavailable
    Given a bundle exists with bundleId in active state
    And the KillBill API is temporarily unavailable
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 503
    And the response body should indicate service unavailable

    @TC13
    Scenario: Attempt to pause a bundle with SQL injection in bundleId
    Given a bundle exists with bundleId containing SQL injection payload
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 400
    And the response body should indicate invalid bundleId
    And no database error or unintended behavior should occur

    @TC14
    Scenario: Attempt to pause a bundle with XSS payload in headers
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a value containing XSS payload
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 400
    And the response body should indicate invalid header value
    And no script should be executed

    @TC15
    Scenario: Attempt to pause a bundle with extra unexpected parameters
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause with extra query parameters
    Then the response status code should be 204
    And the extra parameters should be ignored

    @TC16
    Scenario: Attempt to pause a bundle with very large pluginProperty array
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause with pluginProperty set to an array of 1000+ values
    Then the response status code should be 204 or 413
    And the system should handle large payload gracefully

    @TC17
    Scenario: Attempt to pause a bundle with requestedDate in the past
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause with requestedDate set to a past date
    Then the response status code should be 400
    And the response body should indicate invalid requestedDate

    @TC18
    Scenario: Attempt to pause a bundle with malformed requestedDate
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause with requestedDate set to "not-a-date"
    Then the response status code should be 400
    And the response body should indicate invalid date format

    @TC19
    Scenario: Attempt to pause a bundle with malformed pluginProperty
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause with pluginProperty set to invalid format (e.g., integer value)
    Then the response status code should be 400
    And the response body should indicate invalid pluginProperty format

    @TC20
    Scenario: Attempt to pause a bundle when database is empty
    Given the database contains no bundles
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause with a valid bundleId
    Then the response status code should be 404
    And the response body should indicate bundle not found

    @TC21
    Scenario: Pause a bundle with concurrent requests
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send multiple concurrent PUT requests to /1.0/kb/bundles/{bundleId}/pause
    Then only one request should succeed with 204
    And the others should return 400 indicating already paused or invalid state

    @TC22
    Scenario: Pause a bundle and verify system performance under load
    Given 1000 active bundles exist
    And header X-Killbill-CreatedBy is set to a valid user
    When I send PUT requests to /1.0/kb/bundles/{bundleId}/pause for all bundles in quick succession
    Then the average response time should be within acceptable threshold (e.g., <500ms)
    And no system errors should occur

    @TC23
    Scenario: Regression - Pausing a bundle does not affect unrelated bundles
    Given two bundles exist: bundleA in active state and bundleB in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/bundleA/pause
    Then the response status code should be 204
    And bundleA should be paused
    And bundleB should remain active

    @TC24
    Scenario: Regression - Previously fixed issue: pausing a bundle with special characters in pluginProperty
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause with pluginProperty set to ["spécial=✓"]
    Then the response status code should be 204
    And the plugin property should be processed correctly

    @TC25
    Scenario: Integration - Pause a bundle when dependent plugin service is down
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    And the plugin service is unavailable
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 502
    And the response body should indicate dependency failure

    @TC26
    Scenario: Integration - Pause a bundle and verify data consistency across systems
    Given a bundle exists with bundleId in active state
    And header X-Killbill-CreatedBy is set to a valid user
    When I send a PUT request to /1.0/kb/bundles/{bundleId}/pause
    Then the response status code should be 204
    And the pause event should be reflected in downstream systems

    @TC27
    Scenario: Accessibility - API documentation is accessible and conforms to standards
    Given I have access to the KillBill API documentation for PUT /1.0/kb/bundles/{bundleId}/pause
    When I inspect the documentation
    Then it should be navigable by screen readers
    And all fields and error messages should have accessible descriptions