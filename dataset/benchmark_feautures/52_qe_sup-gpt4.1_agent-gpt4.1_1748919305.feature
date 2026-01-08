Feature: Retrieve Tags for a Bundle via GET /1.0/kb/bundles/{bundleId}/tags
As a KillBill API user,
I want to retrieve tags for a specific bundle,
so that I can view metadata and manage bundle categorization.

  Background:
  Given the KillBill API is available at the base URL
  And I have valid authentication credentials
  And the system contains bundles with various tag configurations (no tags, some tags, deleted tags)
  And the database is seeded with bundles having valid and invalid UUIDs
  And the API endpoint GET /1.0/kb/bundles/{bundleId}/tags is reachable

    @TC01
    Scenario: Successful retrieval of tags for a bundle with no query parameters (happy path)
    Given a valid bundleId corresponding to an existing bundle with tags
    When I perform GET /1.0/kb/bundles/{bundleId}/tags without query parameters
    Then the response code should be 200
    And the response body should be a JSON array of Tag objects (excluding deleted tags)
    And the response Content-Type should be application/json

    @TC02
    Scenario: Successful retrieval of tags for a bundle with includedDeleted=true
    Given a valid bundleId corresponding to an existing bundle with both active and deleted tags
    When I perform GET /1.0/kb/bundles/{bundleId}/tags?includedDeleted=true
    Then the response code should be 200
    And the response body should include both active and deleted Tag objects

    @TC03
    Scenario: Successful retrieval of tags for a bundle with audit=FULL
    Given a valid bundleId corresponding to an existing bundle with tags
    When I perform GET /1.0/kb/bundles/{bundleId}/tags?audit=FULL
    Then the response code should be 200
    And each Tag object in the response should include full audit information

    @TC04
    Scenario: Successful retrieval of tags for a bundle with audit=MINIMAL
    Given a valid bundleId corresponding to an existing bundle with tags
    When I perform GET /1.0/kb/bundles/{bundleId}/tags?audit=MINIMAL
    Then the response code should be 200
    And each Tag object in the response should include minimal audit information

    @TC05
    Scenario: Successful retrieval of tags for a bundle with all query parameters
    Given a valid bundleId corresponding to an existing bundle with both active and deleted tags
    When I perform GET /1.0/kb/bundles/{bundleId}/tags?includedDeleted=true&audit=FULL
    Then the response code should be 200
    And the response body should include both active and deleted Tag objects with full audit information

    @TC06
    Scenario: Retrieve tags for a bundle with no tags
    Given a valid bundleId corresponding to an existing bundle with no tags
    When I perform GET /1.0/kb/bundles/{bundleId}/tags
    Then the response code should be 200
    And the response body should be an empty JSON array

    @TC07
    Scenario: Retrieve tags for a non-existent bundle
    Given a valid bundleId that does not correspond to any bundle in the system
    When I perform GET /1.0/kb/bundles/{bundleId}/tags
    Then the response code should be 404
    And the response body should contain an error message indicating bundle not found

    @TC08
    Scenario: Retrieve tags with an invalid bundleId format
    Given an invalid bundleId that does not match the UUID pattern
    When I perform GET /1.0/kb/bundles/{bundleId}/tags
    Then the response code should be 400
    And the response body should contain an error message indicating invalid bundleId

    @TC09
    Scenario: Retrieve tags with unsupported audit parameter value
    Given a valid bundleId corresponding to an existing bundle
    When I perform GET /1.0/kb/bundles/{bundleId}/tags?audit=INVALID
    Then the response code should be 400
    And the response body should contain an error message indicating invalid audit parameter

    @TC10
    Scenario: Retrieve tags with extra/unexpected query parameters
    Given a valid bundleId corresponding to an existing bundle
    When I perform GET /1.0/kb/bundles/{bundleId}/tags?foo=bar
    Then the response code should be 200
    And the response body should be a JSON array of Tag objects (excluding deleted tags)

    @TC11
    Scenario: Retrieve tags when API is unavailable
    Given the KillBill API endpoint is down or unreachable
    When I perform GET /1.0/kb/bundles/{bundleId}/tags
    Then the response code should be 503 or 504
    And the response body should contain an appropriate error message

    @TC12
    Scenario: Retrieve tags with missing authentication token
    Given a valid bundleId corresponding to an existing bundle
    And I do not provide an authentication token
    When I perform GET /1.0/kb/bundles/{bundleId}/tags
    Then the response code should be 401
    And the response body should contain an error message indicating authentication failure

    @TC13
    Scenario: Retrieve tags with invalid authentication token
    Given a valid bundleId corresponding to an existing bundle
    And I provide an invalid authentication token
    When I perform GET /1.0/kb/bundles/{bundleId}/tags
    Then the response code should be 401
    And the response body should contain an error message indicating authentication failure

    @TC14
    Scenario: Retrieve tags with injection or malicious payload in parameters
    Given a valid bundleId corresponding to an existing bundle
    When I perform GET /1.0/kb/bundles/{bundleId}/tags?audit=' OR 1=1 --
    Then the response code should be 400 or 422
    And the response body should contain an error message indicating invalid input

    @TC15
    Scenario: Retrieve tags for a bundle with a very large number of tags
    Given a valid bundleId corresponding to an existing bundle with a large number of tags (e.g., 10,000)
    When I perform GET /1.0/kb/bundles/{bundleId}/tags
    Then the response code should be 200
    And the response time should be within acceptable limits (e.g., < 2 seconds)
    And the response body should be a JSON array of Tag objects

    @TC16
    Scenario: Retrieve tags with slow dependency (simulate degraded performance)
    Given a valid bundleId corresponding to an existing bundle
    And the tag storage service is responding slowly
    When I perform GET /1.0/kb/bundles/{bundleId}/tags
    Then the response code should be 200 or 504 depending on timeout configuration
    And the response time and error handling should be logged

    @TC17
    Scenario: Regression - previously fixed issue with deleted tags being returned when includedDeleted=false
    Given a valid bundleId corresponding to an existing bundle with deleted tags
    When I perform GET /1.0/kb/bundles/{bundleId}/tags?includedDeleted=false
    Then the response code should be 200
    And the response body should not include deleted Tag objects

    @TC18
    Scenario: Regression - backward compatibility with previous clients (no audit parameter)
    Given a valid bundleId corresponding to an existing bundle
    When I perform GET /1.0/kb/bundles/{bundleId}/tags without audit parameter
    Then the response code should be 200
    And the response body should be a JSON array of Tag objects

    @TC19
    Scenario: Performance - concurrent requests for tags on the same bundle
    Given a valid bundleId corresponding to an existing bundle
    When I perform 100 concurrent GET /1.0/kb/bundles/{bundleId}/tags requests
    Then all responses should have status code 200
    And the average response time should be within acceptable limits

    @TC20
    Scenario: Performance - high resource utilization
    Given a valid bundleId corresponding to an existing bundle with a large number of tags
    When I perform GET /1.0/kb/bundles/{bundleId}/tags
    Then the system should not exceed resource utilization thresholds (CPU, memory, network)

    # Accessibility scenarios are not applicable as this is an API endpoint with no UI