Feature: Transfer a bundle to another account via POST /1.0/kb/bundles/{bundleId}
As a KillBill API user,
I want to transfer a subscription bundle to another account,
so that I can manage subscriptions across accounts efficiently.

  Background:
  Given the KillBill API is available at the correct baseUrl
  And the database contains at least two valid accounts (source and target)
  And at least one bundle exists and is associated with the source account
  And the user has a valid authentication token
  And the request will include the required X-Killbill-CreatedBy header
  And the system clock is set to a known value

    @TC01
    Scenario: Successful transfer with minimum required fields
    Given a valid bundleId belonging to the source account
    And a valid target accountId in the request body
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId} with the above data
    Then the response status should be 201
    And the response body should be a valid Bundle object associated with the target account
    And the Location header should contain the URL of the transferred bundle

    @TC02
    Scenario: Successful transfer with all optional query and header parameters
    Given a valid bundleId and valid target accountId
    And requestedDate, billingPolicy, and pluginProperty query parameters are provided with valid values
    And X-Killbill-CreatedBy, X-Killbill-Reason, and X-Killbill-Comment headers are provided
    When the user calls POST /1.0/kb/bundles/{bundleId} with all parameters
    Then the response status should be 201
    And the response body should reflect the new target account and the specified parameters
    And the Location header should be present and correct

    @TC03
    Scenario: Successful transfer with each billingPolicy value
    Given a valid bundleId and valid target accountId
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId} with billingPolicy set to START_OF_TERM
    Then the response status should be 201
    And the Bundle is transferred according to START_OF_TERM policy
    When the user calls POST /1.0/kb/bundles/{bundleId} with billingPolicy set to END_OF_TERM
    Then the response status should be 201
    And the Bundle is transferred according to END_OF_TERM policy
    When the user calls POST /1.0/kb/bundles/{bundleId} with billingPolicy set to IMMEDIATE
    Then the response status should be 201
    And the Bundle is transferred according to IMMEDIATE policy

    @TC04
    Scenario: Transfer with requestedDate set to today
    Given a valid bundleId and valid target accountId
    And requestedDate query parameter is set to today's date
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 201
    And the Bundle's transfer effective date matches today's date

    @TC05
    Scenario: Transfer with pluginProperty array
    Given a valid bundleId and valid target accountId
    And pluginProperty query parameter is provided with multiple values
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 201
    And the response body should reflect the plugin properties

    @TC06
    Scenario: Transfer when no data exists (bundle does not exist)
    Given a non-existent bundleId
    And a valid target accountId
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 404
    And the response body should contain an error message indicating bundle not found

    @TC07
    Scenario: Transfer to a non-existent target account
    Given a valid bundleId
    And a non-existent target accountId in the request body
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 404
    And the response body should contain an error message indicating account not found

    @TC08
    Scenario: Invalid bundleId format
    Given a bundleId that does not match the UUID pattern
    And a valid target accountId
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 400
    And the response body should contain an error message indicating invalid bundleId

    @TC09
    Scenario: Invalid requestedDate format
    Given a valid bundleId and valid target accountId
    And requestedDate is set to an invalid date string
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 400
    And the response body should contain an error message indicating invalid requestedDate

    @TC10
    Scenario: Invalid billingPolicy value
    Given a valid bundleId and valid target accountId
    And billingPolicy is set to ILLEGAL
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 400
    And the response body should contain an error message indicating invalid billingPolicy

    @TC11
    Scenario: Missing required X-Killbill-CreatedBy header
    Given a valid bundleId and valid target accountId
    When the user calls POST /1.0/kb/bundles/{bundleId} without the X-Killbill-CreatedBy header
    Then the response status should be 400
    And the response body should indicate missing required header

    @TC12
    Scenario: Missing required request body (accountId)
    Given a valid bundleId
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId} without a request body
    Then the response status should be 400
    And the response body should indicate missing required body

    @TC13
    Scenario: Unauthorized access attempt
    Given a valid bundleId and valid target accountId
    And an invalid or missing authentication token
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 401
    And the response body should indicate unauthorized access

    @TC14
    Scenario: System error (dependency/service unavailable)
    Given a valid bundleId and valid target accountId
    And X-Killbill-CreatedBy header is provided
    And the dependent service is unavailable
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 503
    And the response body should indicate service unavailable

    @TC15
    Scenario: Security - SQL injection attempt in accountId
    Given a valid bundleId
    And X-Killbill-CreatedBy header is provided
    And accountId in the request body contains a SQL injection string
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 400
    And the response body should indicate invalid input

    @TC16
    Scenario: Security - XSS attempt in pluginProperty
    Given a valid bundleId and valid target accountId
    And pluginProperty contains a script tag
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 400
    And the response body should indicate invalid input

    @TC17
    Scenario: Recovery from transient network failure
    Given a valid bundleId and valid target accountId
    And X-Killbill-CreatedBy header is provided
    And a transient network failure occurs on the first attempt
    When the user retries the POST request
    Then the response status should be 201
    And the transfer should succeed

    @TC18
    Scenario: Edge case - Empty pluginProperty array
    Given a valid bundleId and valid target accountId
    And pluginProperty is provided as an empty array
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 201
    And the response body should not include plugin properties

    @TC19
    Scenario: Edge case - Extra unexpected parameters
    Given a valid bundleId and valid target accountId
    And X-Killbill-CreatedBy header is provided
    And the request includes extra, unsupported parameters
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 201
    And the extra parameters are ignored

    @TC20
    Scenario: Edge case - Large payload in pluginProperty
    Given a valid bundleId and valid target accountId
    And pluginProperty contains a large number of entries (approaching system limit)
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 201 or 413 if payload too large
    And the system handles the payload appropriately

    @TC21
    Scenario: Edge case - Maximum allowed length for comment and reason headers
    Given a valid bundleId and valid target accountId
    And X-Killbill-CreatedBy header is provided
    And X-Killbill-Reason and X-Killbill-Comment headers are set to maximum allowed length
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 201
    And the transfer completes successfully

    @TC22
    Scenario: State variation - Empty database (no bundles, no accounts)
    Given the database is empty
    When the user calls POST /1.0/kb/bundles/{bundleId} with any bundleId and accountId
    Then the response status should be 404
    And the response body should indicate not found

    @TC23
    Scenario: State variation - Partially populated database
    Given the database has some accounts but not the target account
    And a valid bundleId exists
    When the user calls POST /1.0/kb/bundles/{bundleId} with a non-existent target accountId
    Then the response status should be 404
    And the response body should indicate account not found

    @TC24
    Scenario: Integration - Dependency returns inconsistent data
    Given a valid bundleId and valid target accountId
    And X-Killbill-CreatedBy header is provided
    And a dependent service returns inconsistent data
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 500
    And the response body should indicate internal server error

    @TC25
    Scenario: Regression - Previously fixed issue with transfer to same account
    Given a valid bundleId and the target accountId is the same as the source account
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 400
    And the response body should indicate transfer to same account is not allowed

    @TC26
    Scenario: Regression - Backward compatibility with old clients (missing optional fields)
    Given a valid bundleId and valid target accountId
    And X-Killbill-CreatedBy header is provided
    And no optional query or header parameters are provided
    When the user calls POST /1.0/kb/bundles/{bundleId}
    Then the response status should be 201
    And the transfer completes successfully

    @TC27
    Scenario: Performance - Response time under normal load
    Given a valid bundleId and valid target accountId
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId} under normal system load
    Then the response time should be less than 2 seconds
    And the response status should be 201

    @TC28
    Scenario: Performance - Response time under peak load
    Given a valid bundleId and valid target accountId
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId} under peak system load
    Then the response time should be within acceptable SLA
    And the response status should be 201

    @TC29
    Scenario: Performance - Concurrent requests
    Given multiple valid bundleIds and target accountIds
    And X-Killbill-CreatedBy header is provided
    When multiple users call POST /1.0/kb/bundles/{bundleId} concurrently
    Then all responses should be 201
    And all transfers should succeed without data corruption

    @TC30
    Scenario: Performance - Resource utilization
    Given a valid bundleId and valid target accountId
    And X-Killbill-CreatedBy header is provided
    When the user calls POST /1.0/kb/bundles/{bundleId} repeatedly
    Then the system should not exceed acceptable memory and CPU thresholds

    @TC31
    Scenario: Accessibility - API documentation and error messages
    Given the user is visually impaired
    When the user reads API documentation and error messages
    Then all documentation and messages should be clear, concise, and accessible
    And error responses should include machine-readable error codes and human-readable descriptions