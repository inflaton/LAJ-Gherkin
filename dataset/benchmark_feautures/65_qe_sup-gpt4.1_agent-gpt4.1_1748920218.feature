Feature: Block a Bundle via POST /1.0/kb/bundles/{bundleId}/block
As a KillBill API user,
I want to apply a blocking state to a specific bundle,
so that I can control entitlement, billing, or changes for that bundle.

  Background:
  Given the KillBill API is available
  And a valid authentication token is set
  And the database contains bundles with a variety of states (including at least one valid bundle with a known UUID and at least one non-existent UUID)
  And the BlockingState schema is defined and available for request body validation

    @TC01
    Scenario: Successful block of a bundle with only required parameters
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block with only required headers and body
    Then the API responds with HTTP 201
    And the response body contains a JSON array of BlockingState objects representing the created blocking state(s)
    And the response contains all expected fields per BlockingState definition

    @TC02
    Scenario: Successful block with all optional parameters and headers
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    And the X-Killbill-Reason header is set
    And the X-Killbill-Comment header is set
    And the requestedDate query parameter is set to a valid date
    And the pluginProperty query parameter is set to multiple valid values
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block with all headers, query params, and valid body
    Then the API responds with HTTP 201
    And the response body contains a JSON array of BlockingState objects with the correct effective date and plugin properties

    @TC03
    Scenario: Block a bundle with only optional headers
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    And the X-Killbill-Reason and X-Killbill-Comment headers are set
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block with optional headers and required body
    Then the API responds with HTTP 201
    And the response body contains a JSON array of BlockingState objects

    @TC04
    Scenario: Block a bundle with only optional query parameters
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    And the requestedDate query parameter is set to a valid date
    And the pluginProperty query parameter is set to multiple valid values
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block with optional query params and required body
    Then the API responds with HTTP 201
    And the response body contains a JSON array of BlockingState objects

    @TC05
    Scenario: Block a bundle when no data exists in the system
    Given the database contains no bundles
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 404
    And the response body contains an error message indicating the bundle was not found

    @TC06
    Scenario: Block a bundle with an invalid bundleId format
    Given an invalid bundleId is used (not matching the uuid pattern)
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid bundleId

    @TC07
    Scenario: Block a bundle with a non-existent bundleId
    Given a bundleId that does not exist in the system
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 404
    And the response body contains an error message indicating the bundle was not found

    @TC08
    Scenario: Block a bundle with a malformed request body
    Given a valid bundleId exists
    And a malformed BlockingState object is prepared in the request body (e.g., missing required fields, invalid types)
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 400
    And the response body contains an error message indicating the request body is invalid

    @TC09
    Scenario: Block a bundle with missing required header X-Killbill-CreatedBy
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block without the X-Killbill-CreatedBy header
    Then the API responds with HTTP 400 or 401
    And the response body contains an error message indicating the missing required header

    @TC10
    Scenario: Block a bundle with missing request body
    Given a valid bundleId exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block without a request body
    Then the API responds with HTTP 400
    And the response body contains an error message indicating the request body is required

    @TC11
    Scenario: Block a bundle with invalid requestedDate format
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    And the requestedDate query parameter is set to an invalid date format
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid date format

    @TC12
    Scenario: Block a bundle with extra unexpected parameters
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    And additional unexpected query or header parameters are included
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 201 or ignores extra parameters
    And the response body contains a JSON array of BlockingState objects

    @TC13
    Scenario: Block a bundle with maximum allowed values in BlockingState
    Given a valid bundleId exists
    And a BlockingState object with maximum allowed field lengths/values is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 201
    And the response body contains a JSON array of BlockingState objects

    @TC14
    Scenario: Block a bundle with minimum allowed values in BlockingState
    Given a valid bundleId exists
    And a BlockingState object with minimum allowed field lengths/values is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 201
    And the response body contains a JSON array of BlockingState objects

    @TC15
    Scenario: Block a bundle with partial input in BlockingState
    Given a valid bundleId exists
    And a BlockingState object with only required fields is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 201
    And the response body contains a JSON array of BlockingState objects

    @TC16
    Scenario: Block a bundle with large payload (stress test)
    Given a valid bundleId exists
    And a BlockingState object with very large string fields (up to allowed limits) is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 201 or 400 (if size limit exceeded)
    And the response body is handled appropriately

    @TC17
    Scenario: Block a bundle when the KillBill service is unavailable
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    And the KillBill service is down or unreachable
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 503 or appropriate error code
    And the response body contains an error message indicating service unavailability

    @TC18
    Scenario: Block a bundle with invalid authentication token
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    And the authentication token is missing or invalid
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 401
    And the response body contains an error message indicating authentication failure

    @TC19
    Scenario: Block a bundle with injection attempt in input fields
    Given a valid bundleId exists
    And a BlockingState object with injection payloads in string fields is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 400 or sanitizes input
    And the response body does not reflect the injection payload

    @TC20
    Scenario: Block a bundle with XSS attempt in input fields
    Given a valid bundleId exists
    And a BlockingState object with XSS payloads in string fields is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 400 or sanitizes input
    And the response body does not reflect the XSS payload

    @TC21
    Scenario: Block a bundle with network interruption and retry
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    And a transient network error occurs during the request
    When the user retries the POST request after the network recovers
    Then the API responds with HTTP 201
    And the response body contains a JSON array of BlockingState objects

    @TC22
    Scenario: Block a bundle with concurrent requests
    Given a valid bundleId exists
    And multiple valid BlockingState objects are prepared in request bodies
    And the X-Killbill-CreatedBy header is set to a valid user
    When multiple POST requests are sent concurrently to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 201 for each request
    And all blocking states are properly reflected in the system

    @TC23
    Scenario: Regression - previously fixed issue with special characters in BlockingState
    Given a valid bundleId exists
    And a BlockingState object containing special characters in string fields is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 201
    And the response body contains a JSON array of BlockingState objects with correct character encoding

    @TC24
    Scenario: Regression - backward compatibility with previous clients
    Given a valid bundleId exists
    And a BlockingState object using only fields supported by previous API versions is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 201
    And the response body is compatible with previous client expectations

    @TC25
    Scenario: Performance - response time under normal load
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block under normal load
    Then the API responds with HTTP 201 within the acceptable response time threshold (e.g., < 1s)

    @TC26
    Scenario: Performance - response time under peak load
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block under simulated peak load
    Then the API responds with HTTP 201 within the acceptable response time threshold (e.g., < 2s)

    @TC27
    Scenario: Performance - resource utilization during bulk blocking
    Given multiple valid bundleIds exist
    And valid BlockingState objects are prepared in request bodies
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends multiple POST requests to /1.0/kb/bundles/{bundleId}/block in parallel
    Then the API responds with HTTP 201 for each request
    And system resource utilization remains within acceptable limits

    @TC28
    Scenario: Integration - dependent service returns error
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    And a dependent service required for blocking state returns an error
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 502 or 503
    And the response body indicates the dependency failure

    @TC29
    Scenario: Integration - data consistency across systems
    Given a valid bundleId exists
    And a valid BlockingState object is prepared in the request body
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a POST request to /1.0/kb/bundles/{bundleId}/block
    Then the API responds with HTTP 201
    And the blocking state is reflected consistently in all integrated systems

    @TC30
    Scenario: Accessibility - API documentation is accessible
    Given the API documentation is available
    When a user with a screen reader accesses the documentation for POST /1.0/kb/bundles/{bundleId}/block
    Then the documentation is readable and navigable according to accessibility standards