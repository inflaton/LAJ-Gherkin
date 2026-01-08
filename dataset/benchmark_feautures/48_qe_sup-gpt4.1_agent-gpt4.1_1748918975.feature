Feature: Put Kill Bill Host Back Into Rotation
As an administrator,
I want to put a Kill Bill host back into rotation via the Admin API,
so that the host can resume handling traffic for operational and load balancing purposes.

  Background:
  Given the Kill Bill service is running
  And the API endpoint PUT /1.0/kb/admin/healthcheck is available
  And the administrator is authenticated with valid credentials
  And the system has at least one host that can be put back into rotation

    @TC01
    Scenario: Successful PUT to put host back into rotation
    Given the Kill Bill host is currently out of rotation
    And the administrator is authenticated
    When the administrator sends a PUT request to /1.0/kb/admin/healthcheck with no request body
    Then the API should respond with HTTP status code 204
    And the response body should be empty
    And the host should be marked as in rotation in the system state

    @TC02
    Scenario: PUT request when host is already in rotation
    Given the Kill Bill host is already in rotation
    And the administrator is authenticated
    When the administrator sends a PUT request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 204
    And the response body should be empty
    And the host state should remain in rotation

    @TC03
    Scenario: Unauthorized access attempt
    Given the administrator is not authenticated or provides an invalid token
    When a PUT request is sent to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 401
    And the response body should contain an error message indicating unauthorized access

    @TC04
    Scenario: Forbidden access due to insufficient permissions
    Given the user is authenticated but lacks admin privileges
    When the user sends a PUT request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 403
    And the response body should contain an error message indicating insufficient permissions

    @TC05
    Scenario: Endpoint unavailable or service down
    Given the Kill Bill service is not running or the endpoint is unreachable
    When a PUT request is sent to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 503
    And the response body should contain an error message indicating service unavailability

    @TC06
    Scenario: PUT request with invalid HTTP method
    Given the administrator is authenticated
    When the administrator sends a GET request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 405
    And the response body should contain an error message indicating method not allowed

    @TC07
    Scenario: PUT request with unexpected payload
    Given the administrator is authenticated
    When the administrator sends a PUT request to /1.0/kb/admin/healthcheck with a non-empty request body
    Then the API should respond with HTTP status code 204
    And the response body should be empty
    And the host should be marked as in rotation in the system state

    @TC08
    Scenario: PUT request with additional unexpected headers
    Given the administrator is authenticated
    When the administrator sends a PUT request to /1.0/kb/admin/healthcheck with extra headers
    Then the API should respond with HTTP status code 204
    And the response body should be empty

    @TC09
    Scenario: PUT request with missing required headers
    Given the administrator omits required headers such as authentication
    When a PUT request is sent to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 401
    And the response body should contain an error message indicating unauthorized access

    @TC10
    Scenario: PUT request during degraded system performance
    Given the Kill Bill service is experiencing high load or slow response
    And the administrator is authenticated
    When the administrator sends a PUT request to /1.0/kb/admin/healthcheck
    Then the API should respond within the acceptable timeout threshold (e.g., <2 seconds)
    And the API should respond with HTTP status code 204 if successful
    Or with an appropriate error code if the operation fails due to system load

    @TC11
    Scenario: Regression - Previously fixed issue for host rotation
    Given a previously reported bug related to host rotation was fixed
    When the administrator sends a PUT request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 204
    And the host should be correctly marked as in rotation

    @TC12
    Scenario: Security - Injection attempt in headers
    Given the administrator is authenticated
    When the administrator sends a PUT request to /1.0/kb/admin/healthcheck with a header containing a malicious payload
    Then the API should respond with HTTP status code 204 or appropriate error code
    And the system should not be vulnerable to injection

    @TC13
    Scenario: PUT request with network interruption (transient failure)
    Given the administrator is authenticated
    And the network connection is temporarily interrupted during the request
    When the administrator retries the PUT request to /1.0/kb/admin/healthcheck
    Then the API should respond with HTTP status code 204 upon successful retry
    And the host should be marked as in rotation

    @TC14
    Scenario: PUT request with large number of concurrent requests
    Given multiple administrators are authenticated
    When multiple PUT requests are sent concurrently to /1.0/kb/admin/healthcheck
    Then all requests should complete successfully with HTTP status code 204
    And the host should be marked as in rotation without error or race condition