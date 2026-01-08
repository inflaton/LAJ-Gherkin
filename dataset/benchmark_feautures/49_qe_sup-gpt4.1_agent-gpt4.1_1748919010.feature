Feature: Kill Bill Admin API - Take Host Out of Rotation
As a Kill Bill administrator,
I want to put a host out of rotation via the DELETE /1.0/kb/admin/healthcheck API,
so that I can perform maintenance or load balancing operations safely.

  Background:
  Given the Kill Bill system is running and accessible
  And the API endpoint DELETE /1.0/kb/admin/healthcheck is available
  And valid admin authentication credentials are obtained
  And the host is currently in rotation

    @TC01
    Scenario: Successfully take host out of rotation
    Given the host is currently in rotation
    And a valid admin authentication token is provided
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 204
    And the response body should be empty
    And the host should be marked as out of rotation in the system

    @TC02
    Scenario: Unauthorized request (no authentication)
    Given the host is currently in rotation
    And no authentication token is provided
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 401
    And the response body should contain an error message indicating authentication is required

    @TC03
    Scenario: Unauthorized request (invalid authentication)
    Given the host is currently in rotation
    And an invalid authentication token is provided
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 401
    And the response body should contain an error message indicating invalid authentication

    @TC04
    Scenario: Host already out of rotation
    Given the host is already out of rotation
    And a valid admin authentication token is provided
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 409
    And the response body should contain an error message indicating the host is already out of rotation

    @TC05
    Scenario: Endpoint unavailable (service down)
    Given the Kill Bill service is down or unreachable
    And a valid admin authentication token is provided
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 503
    And the response body should contain an error message indicating service unavailability

    @TC06
    Scenario: System error occurs during operation
    Given the host is currently in rotation
    And a valid admin authentication token is provided
    And a system error occurs during the operation
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 500
    And the response body should contain an error message indicating an internal server error

    @TC07
    Scenario: Invalid HTTP method used
    Given the host is currently in rotation
    And a valid admin authentication token is provided
    When the administrator sends a GET request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 405
    And the response body should contain an error message indicating method not allowed

    @TC08
    Scenario: Extra parameters provided in request
    Given the host is currently in rotation
    And a valid admin authentication token is provided
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck with extra query parameters
    Then the API should respond with HTTP status code 204
    And the response body should be empty
    And the host should be marked as out of rotation in the system

    @TC09
    Scenario: Malicious payload sent in request body
    Given the host is currently in rotation
    And a valid admin authentication token is provided
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck with a non-empty or malicious request body
    Then the API should respond with HTTP status code 400
    And the response body should contain an error message indicating invalid request body

    @TC10
    Scenario: Performance - Response time under normal load
    Given the host is currently in rotation
    And a valid admin authentication token is provided
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck under normal load conditions
    Then the API should respond with HTTP status code 204 within 1 second
    And the response body should be empty

    @TC11
    Scenario: Performance - Response time under concurrent requests
    Given the host is currently in rotation
    And multiple administrators with valid tokens send concurrent DELETE requests to /1.0/kb/admin/healthcheck
    When the requests are processed
    Then the API should respond with HTTP status code 204 to the first request
    And subsequent requests should receive HTTP status code 409 or 204 as appropriate
    And all responses should be returned within 2 seconds

    @TC12
    Scenario: Regression - Previously fixed issue: host not marked out of rotation
    Given the host is currently in rotation
    And a valid admin authentication token is provided
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 204
    And the host should be marked as out of rotation in the system
    And querying the host status should confirm it is out of rotation

    @TC13
    Scenario: Security - Injection attempt in headers
    Given the host is currently in rotation
    And a valid admin authentication token is provided with malicious header values
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 400 or 401
    And the response body should contain an error message indicating invalid headers or authentication

    @TC14
    Scenario: Edge Case - System with no hosts in rotation
    Given there are no hosts currently in rotation in the system
    And a valid admin authentication token is provided
    When the administrator sends a DELETE request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 409
    And the response body should contain an error message indicating no hosts available for operation