Feature: Add tags to a bundle via POST /1.0/kb/bundles/{bundleId}/tags
As a KillBill API user,
I want to add tags to a bundle using the API,
so that I can categorize or annotate bundles as needed.

  Background:
  Given the KillBill API server is running and reachable
  And the database contains bundles with valid and invalid bundleIds
  And at least one valid tag definition exists in the system
  And I have a valid authentication token (if required)
  And I have the necessary permissions to add tags to bundles

    @TC01
    Scenario: Successful addition of tags to a bundle with all required headers and valid body
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array of valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 201
    And the response body should be a JSON array of Tag objects corresponding to the added tags
    And each Tag object should contain the correct bundleId and tagDefinitionId
    And the tags should be persisted in the database for the bundle

    @TC02
    Scenario: Addition of tags with optional headers X-Killbill-Reason and X-Killbill-Comment
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And X-Killbill-Reason header is set to "testing reason"
    And X-Killbill-Comment header is set to "testing comment"
    And the request body is a JSON array of valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 201
    And the response body should be a JSON array of Tag objects
    And each Tag object should contain the correct bundleId and tagDefinitionId
    And the tags should be persisted in the database for the bundle

    @TC03
    Scenario: Addition of a single tag to a bundle
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array with one valid tag definition UUID
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 201
    And the response body should be a JSON array with one Tag object
    And the Tag object should contain the correct bundleId and tagDefinitionId

    @TC04
    Scenario: Addition of multiple tags to a bundle
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array with multiple valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 201
    And the response body should be a JSON array with Tag objects for each tag definition UUID

    @TC05
    Scenario: Addition of tags to a bundle when no tags exist on the bundle
    Given a valid bundleId exists with no tags assigned
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array of valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 201
    And the response body should be a JSON array of Tag objects
    And the tags should be present on the bundle after the request

    @TC06
    Scenario: Addition of tags to a bundle when the bundle already has some of the tags
    Given a valid bundleId exists with some tags already assigned
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array including both new and already-assigned tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 201
    And the response body should be a JSON array of Tag objects
    And the response should reflect the current state of tags on the bundle

    @TC07
    Scenario: Addition of tags with an empty tag list
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is an empty JSON array
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 201
    And the response body should be an empty JSON array
    And no tags should be added to the bundle

    @TC08
    Scenario: Addition of tags with an invalid bundleId format
    Given an invalid bundleId is provided (e.g., not matching UUID pattern)
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array of valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid bundleId

    @TC09
    Scenario: Addition of tags with non-existent bundleId
    Given a bundleId that does not exist in the system
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array of valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating bundle not found

    @TC10
    Scenario: Addition of tags with malformed JSON body
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is malformed JSON (e.g., missing brackets or invalid syntax)
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating malformed request body

    @TC11
    Scenario: Addition of tags with a non-array JSON body
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON object instead of an array
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid request body format

    @TC12
    Scenario: Addition of tags with invalid tag definition UUIDs in request body
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array containing invalid UUIDs (malformed or non-existent)
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid tag definition

    @TC13
    Scenario: Addition of tags with missing X-Killbill-CreatedBy header
    Given a valid bundleId exists
    And the X-Killbill-CreatedBy header is missing
    And the request body is a JSON array of valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating missing required header

    @TC14
    Scenario: Addition of tags with missing request body
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is missing
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating missing request body

    @TC15
    Scenario: Addition of tags with extra, unsupported parameters in request body
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array of valid tag definition UUIDs with extra fields
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid request body

    @TC16
    Scenario: Unauthorized attempt to add tags (missing or invalid authentication token)
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the authentication token is missing or invalid
    And the request body is a JSON array of valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC17
    Scenario: Service unavailable or dependency failure during tag addition
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array of valid tag definition UUIDs
    And the backend service or database is unavailable
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC18
    Scenario: Attempt to inject malicious payload in request body
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body contains a string with script tags or SQL injection patterns
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid input

    @TC19
    Scenario: Recovery from transient network failure
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array of valid tag definition UUIDs
    And a transient network failure occurs during the request
    When I retry the POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 201
    And the response body should be a JSON array of Tag objects

    @TC20
    Scenario: Addition of tags with maximum allowed payload size
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array with the maximum allowed number of tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 201
    And the response body should be a JSON array of Tag objects for each tag definition UUID

    @TC21
    Scenario: Addition of tags with request body exceeding maximum allowed payload size
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array with more than the maximum allowed number of tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating payload too large

    @TC22
    Scenario: Addition of tags with slow backend causing timeout
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array of valid tag definition UUIDs
    And the backend service is responding slowly
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 504
    And the response body should contain an error message indicating timeout

    @TC23
    Scenario: Addition of tags with extra, unsupported HTTP headers
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And an extra unsupported HTTP header is included in the request
    And the request body is a JSON array of valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 201
    And the response body should be a JSON array of Tag objects

    @TC24
    Scenario: Performance - Add tags to a bundle under normal load
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array of valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response time should be less than 500ms
    And the response status code should be 201

    @TC25
    Scenario: Performance - Add tags to a bundle under peak load with concurrent requests
    Given multiple valid bundleIds exist
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request bodies are JSON arrays of valid tag definition UUIDs
    When I send concurrent POST requests to /1.0/kb/bundles/{bundleId}/tags
    Then all responses should have status code 201
    And response times should be within acceptable thresholds

    @TC26
    Scenario: Regression - Previously fixed issue with duplicate tags
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body includes a tag definition UUID already assigned to the bundle
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    Then the response status code should be 201
    And the response body should not contain duplicate Tag objects

    @TC27
    Scenario: Integration - Add tags and verify with GET /1.0/kb/bundles/{bundleId}/tags
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array of valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    And I send a GET request to /1.0/kb/bundles/{bundleId}/tags
    Then the GET response should include all tags added in the POST request

    @TC28
    Scenario: Integration - Add tags and verify tag data consistency across services
    Given a valid bundleId exists
    And X-Killbill-CreatedBy header is set to "test-user"
    And the request body is a JSON array of valid tag definition UUIDs
    When I send a POST request to /1.0/kb/bundles/{bundleId}/tags
    And I query the tag data from an integrated reporting service
    Then the tag data should be consistent between KillBill and the reporting service

    @TC29
    Scenario: Accessibility - Ensure API documentation is accessible
    Given I am a user with assistive technology
    When I access the API documentation for POST /1.0/kb/bundles/{bundleId}/tags
    Then the documentation should comply with accessibility standards (e.g., screen reader compatible, proper labeling)