Feature: Resume Subscription Bundle via PUT /1.0/kb/bundles/{bundleId}/resume
As a KillBill API user,
I want to resume a paused subscription bundle using the API,
so that all subscriptions in the bundle are resumed as expected.

  Background:
  Given the KillBill API server is running and available
  And the database contains bundles in various states (paused, active, cancelled, non-existent)
  And valid and invalid bundle UUIDs are seeded into the system
  And valid authentication tokens are available
  And the API endpoint /1.0/kb/bundles/{bundleId}/resume is accessible

    @TC01
    Scenario: Successful resume of a paused bundle with required headers only
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 204
    And the bundle state is updated to active
    And all subscriptions in the bundle are resumed

    @TC02
    Scenario: Successful resume with requestedDate query parameter
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with requestedDate set to a valid future date
    Then the API responds with status code 204
    And the bundle is scheduled to resume on the requestedDate

    @TC03
    Scenario: Successful resume with pluginProperty query parameter
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with pluginProperty set to ["prop1=value1", "prop2=value2"]
    Then the API responds with status code 204
    And the plugin properties are processed as expected

    @TC04
    Scenario: Successful resume with all optional headers and parameters
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    And X-Killbill-Reason header is set to "Customer request"
    And X-Killbill-Comment header is set to "Resuming after payment"
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with requestedDate and pluginProperty parameters
    Then the API responds with status code 204
    And the bundle is scheduled to resume on the requestedDate
    And the plugin properties are processed as expected
    And the reason and comment are recorded in the audit log

    @TC05
    Scenario: Resume bundle when no data exists (empty database)
    Given the database contains no bundles
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with a random UUID
    Then the API responds with status code 404
    And the response body contains an error message indicating bundle not found

    @TC06
    Scenario: Resume bundle with invalid bundleId format
    Given X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with bundleId set to "invalid-uuid"
    Then the API responds with status code 400
    And the response body contains an error message indicating invalid bundle ID

    @TC07
    Scenario: Resume bundle with missing X-Killbill-CreatedBy header
    Given a bundle with bundleId in paused state exists
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume without the X-Killbill-CreatedBy header
    Then the API responds with status code 400
    And the response body contains an error message indicating missing required header

    @TC08
    Scenario: Resume bundle that is not paused (already active)
    Given a bundle with bundleId in active state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 400
    And the response body contains an error message indicating bundle cannot be resumed from current state

    @TC09
    Scenario: Resume bundle that is cancelled
    Given a bundle with bundleId in cancelled state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 400
    And the response body contains an error message indicating bundle cannot be resumed from cancelled state

    @TC10
    Scenario: Resume bundle with unauthorized access (invalid token)
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to an invalid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 401 or 403
    And the response body contains an error message indicating unauthorized access

    @TC11
    Scenario: Resume bundle with extra/unexpected parameters
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with an extra query parameter foo=bar
    Then the API responds with status code 204 or ignores the extra parameter
    And the bundle is resumed as expected

    @TC12
    Scenario: Resume bundle with maximum allowed length for headers and parameters
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a string of maximum allowed length
    And X-Killbill-Reason and X-Killbill-Comment headers are set to strings of maximum allowed length
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 204
    And the bundle is resumed as expected

    @TC13
    Scenario: Resume bundle with very large number of pluginProperty values
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with 1000 pluginProperty values
    Then the API responds with status code 204 or 400 if limit exceeded
    And the response indicates whether all plugin properties were processed or if a limit was enforced

    @TC14
    Scenario: System error when dependency service is unavailable
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    And the dependent subscription service is unavailable
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 500
    And the response body contains an error message indicating internal server error

    @TC15
    Scenario: Resume bundle after transient network failure (retry mechanism)
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    And a transient network failure occurs during the request
    When the user retries the PUT request to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 204 after successful retry
    And the bundle is resumed as expected

    @TC16
    Scenario: Security - SQL injection attempt in pluginProperty
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with pluginProperty set to ["prop1=1;DROP TABLE bundles;"]
    Then the API responds with status code 400 or 204 with no harmful side effects
    And the system is not compromised

    @TC17
    Scenario: Security - XSS attempt in X-Killbill-Comment header
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    And X-Killbill-Comment header is set to "<script>alert(1)</script>"
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 204 or 400 with no XSS vulnerability
    And the comment is safely handled

    @TC18
    Scenario: Resume bundle with partial input (only required fields)
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with only required fields
    Then the API responds with status code 204
    And the bundle is resumed as expected

    @TC19
    Scenario: Resume bundle with unexpected input format for pluginProperty
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with pluginProperty set to a non-array value
    Then the API responds with status code 400
    And the response body contains an error message indicating invalid parameter format

    @TC20
    Scenario: Resume bundle with requestedDate in the past
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with requestedDate set to a date in the past
    Then the API responds with status code 400
    And the response body contains an error message indicating invalid requestedDate

    @TC21
    Scenario: Resume bundle with concurrent requests
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    When multiple users send concurrent PUT requests to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 204 for the first request
    And subsequent requests receive 400 or 409 indicating bundle is already resumed or in invalid state

    @TC22
    Scenario: Performance - Resume bundle under normal and peak load
    Given multiple bundles in paused state exist
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends multiple PUT requests to resume different bundles under normal and peak load
    Then the API responds within the acceptable response time threshold (e.g., < 2 seconds)
    And all bundles are resumed as expected

    @TC23
    Scenario: Regression - Resume bundle with previously fixed edge cases
    Given a bundle with bundleId in paused state exists that previously caused an error
    And X-Killbill-CreatedBy header is set to a valid user
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 204
    And the bundle is resumed as expected

    @TC24
    Scenario: Backward compatibility - Resume bundle using legacy client headers
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid legacy user format
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 204
    And the bundle is resumed as expected

    @TC25
    Scenario: Integration - Resume bundle when plugin service is degraded
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to a valid user
    And the plugin service is experiencing high latency
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume with pluginProperty
    Then the API responds with status code 204 or 504 if timeout occurs
    And the bundle is resumed or an appropriate error is returned

    @TC26
    Scenario: Resume bundle with whitespace and case variations in headers
    Given a bundle with bundleId in paused state exists
    And X-Killbill-CreatedBy header is set to "  USER  " (with leading/trailing spaces and mixed case)
    When the user sends a PUT request to /1.0/kb/bundles/{bundleId}/resume
    Then the API responds with status code 204
    And the bundle is resumed as expected