Feature: Retrieve a subscription bundle by ID via GET /1.0/kb/bundles/{bundleId}
As a KillBill API user,
I want to retrieve a subscription bundle by its ID,
so that I can view bundle details and associated audit information as needed.

  Background:
    Given the KillBill API is running and accessible at the configured baseUrl
    And the API endpoint /1.0/kb/bundles/{bundleId} is available
    And a valid authentication token is provided in the request headers
    And the database is seeded with:
      | bundleId (uuid)         | bundle data present | notes                  |
      | 11111111-1111-1111-1111-111111111111 | true                | Standard bundle      |
      | 22222222-2222-2222-2222-222222222222 | false               | Non-existent bundle |
    And the system supports audit levels: FULL, MINIMAL, NONE

  @TC01
  Scenario: Successful retrieval of a bundle by valid bundleId with default audit level (NONE)
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    And no audit query parameter is specified
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111
    Then the response status code should be 200
    And the response Content-Type should be "application/json"
    And the response body should contain a valid Bundle object matching the requested bundleId
    And the response should not include audit information

  @TC02
  Scenario: Successful retrieval of a bundle by valid bundleId with audit=FULL
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    And the query parameter "audit" is set to "FULL"
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111?audit=FULL
    Then the response status code should be 200
    And the response Content-Type should be "application/json"
    And the response body should contain a valid Bundle object with full audit information

  @TC03
  Scenario: Successful retrieval of a bundle by valid bundleId with audit=MINIMAL
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    And the query parameter "audit" is set to "MINIMAL"
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111?audit=MINIMAL
    Then the response status code should be 200
    And the response Content-Type should be "application/json"
    And the response body should contain a valid Bundle object with minimal audit information

  @TC04
  Scenario: Successful retrieval of a bundle by valid bundleId with audit=NONE
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    And the query parameter "audit" is set to "NONE"
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111?audit=NONE
    Then the response status code should be 200
    And the response Content-Type should be "application/json"
    And the response body should contain a valid Bundle object without audit information

  @TC05
  Scenario: Retrieval with extra/unknown query parameters
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    And the query parameter "foo" is set to "bar"
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111?foo=bar
    Then the response status code should be 200
    And the response Content-Type should be "application/json"
    And the response body should contain a valid Bundle object matching the requested bundleId

  @TC06
  Scenario: Retrieval of a non-existent bundleId
    Given a bundleId "22222222-2222-2222-2222-222222222222" does not exist in the system
    When the user sends a GET request to /1.0/kb/bundles/22222222-2222-2222-2222-222222222222
    Then the response status code should be 404
    And the response body should contain an error message indicating "Bundle not found"

  @TC07
  Scenario: Retrieval with invalid bundleId format (malformed UUID)
    Given an invalid bundleId "invalid-uuid"
    When the user sends a GET request to /1.0/kb/bundles/invalid-uuid
    Then the response status code should be 400
    And the response body should contain an error message indicating "Invalid bundleId format"

  @TC08
  Scenario: Retrieval with missing authentication token
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    And no authentication token is provided in the request headers
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111
    Then the response status code should be 401
    And the response body should contain an error message indicating "Unauthorized"

  @TC09
  Scenario: Retrieval with invalid authentication token
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    And an invalid authentication token is provided in the request headers
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111
    Then the response status code should be 401
    And the response body should contain an error message indicating "Unauthorized"

  @TC10
  Scenario: Retrieval with unsupported audit parameter value
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    And the query parameter "audit" is set to "VERBOSE"
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111?audit=VERBOSE
    Then the response status code should be 400
    And the response body should contain an error message indicating "Invalid audit parameter"

  @TC11
  Scenario: Retrieval when database is empty
    Given the database contains no bundles
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111
    Then the response status code should be 404
    And the response body should contain an error message indicating "Bundle not found"

  @TC12
  Scenario: Retrieval when service is unavailable
    Given the KillBill API service is down or unreachable
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111
    Then the response status code should be 503
    And the response body should contain an error message indicating "Service Unavailable"

  @TC13
  Scenario: Retrieval with network timeout
    Given the KillBill API experiences a network delay exceeding the client timeout threshold
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111
    Then the client should receive a timeout error
    And the system should log the timeout event

  @TC14
  Scenario: Retrieval with large bundle data
    Given a valid bundleId "33333333-3333-3333-3333-333333333333" exists in the system
    And the associated bundle contains a large amount of data (e.g., many subscriptions)
    When the user sends a GET request to /1.0/kb/bundles/33333333-3333-3333-3333-333333333333
    Then the response status code should be 200
    And the response Content-Type should be "application/json"
    And the response body should contain the complete Bundle object with all data
    And the response time should be within acceptable thresholds (e.g., < 2 seconds)

  @TC15
  Scenario: Retrieval with XSS/injection attempt in bundleId
    Given an invalid bundleId "<script>alert(1)</script>"
    When the user sends a GET request to /1.0/kb/bundles/%3Cscript%3Ealert(1)%3C%2Fscript%3E
    Then the response status code should be 400
    And the response body should contain an error message indicating "Invalid bundleId format"
    And the system should not execute or reflect the script

  @TC16
  Scenario: Regression - previously fixed bug for bundleId case sensitivity
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    And the bundleId is supplied in uppercase "11111111-1111-1111-1111-111111111111".toUpperCase()
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111
    Then the response status code should be 200
    And the response body should contain the correct Bundle object

  @TC17
  Scenario: Backward compatibility - client omits audit parameter
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    And no audit query parameter is specified
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111
    Then the response status code should be 200
    And the response body should match previous version's structure for Bundle object

  @TC18
  Scenario: Concurrent retrieval requests for the same bundleId
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    When multiple users send concurrent GET requests to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111
    Then each response status code should be 200
    And each response body should contain the correct Bundle object

  @TC19
  Scenario: Accessibility - response body is readable by assistive technologies
    Given a valid bundleId "11111111-1111-1111-1111-111111111111" exists in the system
    When the user sends a GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111
    Then the JSON response should be well-structured and compatible with screen readers

  @TC20
  Scenario: Recovery from transient errors (retry mechanism)
    Given the KillBill API temporarily returns a 500 error for the first request
    When the client retries the GET request to /1.0/kb/bundles/11111111-1111-1111-1111-111111111111
    Then the subsequent response status code should be 200
    And the response body should contain the correct Bundle object