Feature: Retrieve account timeline via GET /1.0/kb/accounts/{accountId}/timeline
As a KillBill API user,
I want to retrieve the timeline for a specific account,
so that I can view account details, bundles, invoices, and payments.

  Background:
  Given the KillBill API is running and reachable
  And the database is seeded with accounts having diverse timelines (including accounts with no bundles, invoices, or payments)
  And valid and invalid authentication tokens are available
  And the API endpoint /1.0/kb/accounts/{accountId}/timeline is accessible

    @TC01
    Scenario: Successful retrieval of account timeline with required parameter only
    Given a valid accountId that exists in the system
    And no query parameters are provided
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 200
    And the response body should be a valid AccountTimeline JSON object containing account details, bundles, invoices, and payments
    And the audit level in the response should be NONE

    @TC02
    Scenario: Successful retrieval with parallel=true
    Given a valid accountId that exists in the system
    And the parallel query parameter is set to true
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline?parallel=true
    Then the response status code should be 200
    And the response body should be a valid AccountTimeline JSON object
    And the timeline parts are fetched in parallel (verify via logs or performance if possible)

    @TC03
    Scenario: Successful retrieval with audit=FULL
    Given a valid accountId that exists in the system
    And the audit query parameter is set to FULL
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline?audit=FULL
    Then the response status code should be 200
    And the response body should include full audit information as per AccountTimeline definition

    @TC04
    Scenario: Successful retrieval with audit=MINIMAL
    Given a valid accountId that exists in the system
    And the audit query parameter is set to MINIMAL
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline?audit=MINIMAL
    Then the response status code should be 200
    And the response body should include minimal audit information as per AccountTimeline definition

    @TC05
    Scenario: Successful retrieval with both parallel=true and audit=FULL
    Given a valid accountId that exists in the system
    And the parallel query parameter is set to true
    And the audit query parameter is set to FULL
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline?parallel=true&audit=FULL
    Then the response status code should be 200
    And the response body should include full audit information
    And the timeline parts are fetched in parallel

    @TC06
    Scenario: Retrieval when account exists but has no bundles, invoices, or payments
    Given a valid accountId that exists in the system
    And the account has no bundles, invoices, or payments
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 200
    And the response body should be a valid AccountTimeline JSON object with empty bundles, invoices, and payments arrays

    @TC07
    Scenario: Retrieval when account has large number of bundles, invoices, and payments
    Given a valid accountId that exists in the system
    And the account has a large number of bundles, invoices, and payments (e.g., 1000+ each)
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 200
    And the response body should contain all bundles, invoices, and payments
    And the response time should be within acceptable performance thresholds (e.g., <2s)

    @TC08
    Scenario: Error when accountId is invalid (malformed UUID)
    Given an accountId that does not match the UUID pattern
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 400
    And the response body should contain a descriptive error message indicating invalid account ID

    @TC09
    Scenario: Error when accountId does not exist
    Given a validly formatted accountId that does not exist in the system
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 404
    And the response body should indicate that the account was not found

    @TC10
    Scenario: Error when required authentication token is missing
    Given a valid accountId that exists in the system
    And no authentication token is provided
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC11
    Scenario: Error when authentication token is invalid
    Given a valid accountId that exists in the system
    And an invalid authentication token is provided
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC12
    Scenario: Error when system is unavailable
    Given the KillBill API service is down
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 503
    And the response body should indicate service unavailability

    @TC13
    Scenario: Error when dependent service (e.g., database) is unavailable
    Given the database is down
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 500
    And the response body should indicate an internal server error

    @TC14
    Scenario: Security test - SQL injection attempt in accountId
    Given an accountId containing SQL injection payload (e.g., '1 OR 1=1')
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 400
    And the response body should not reveal sensitive information

    @TC15
    Scenario: Security test - XSS attempt in accountId
    Given an accountId containing XSS payload (e.g., '<script>alert(1)</script>')
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 400
    And the response body should not execute or reflect the script

    @TC16
    Scenario: Error when extra unsupported query parameters are provided
    Given a valid accountId that exists in the system
    And an extra unsupported query parameter is provided (e.g., foo=bar)
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline?foo=bar
    Then the response status code should be 200
    And the response body should ignore the unsupported parameter

    @TC17
    Scenario: Edge case - Empty response for account with no timeline data
    Given a valid accountId that exists in the system
    And the account has no timeline data at all (no bundles, no invoices, no payments)
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 200
    And the response body should be a valid AccountTimeline JSON object with empty arrays for all timeline elements

    @TC18
    Scenario: Edge case - Maximum allowed accountId length
    Given an accountId at the maximum allowed UUID length
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 200 or 404 depending on existence

    @TC19
    Scenario: Edge case - Minimum allowed accountId length (valid UUID)
    Given an accountId at the minimum allowed UUID length
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 200 or 404 depending on existence

    @TC20
    Scenario: Performance under concurrent requests
    Given multiple valid accountIds exist in the system
    When multiple users send concurrent GET requests to /1.0/kb/accounts/{accountId}/timeline
    Then all responses should have status code 200
    And response times should remain within acceptable thresholds

    @TC21
    Scenario: Regression - previously fixed bug: timeline omits invoices when audit=FULL
    Given a valid accountId that exists in the system with invoices
    And audit is set to FULL
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline?audit=FULL
    Then the response body should include all invoices as per AccountTimeline definition

    @TC22
    Scenario: Regression - previously fixed bug: parallel=true caused partial data
    Given a valid accountId that exists in the system with multiple timeline elements
    And parallel is set to true
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline?parallel=true
    Then the response body should include all timeline elements (bundles, invoices, payments) without missing data

    @TC23
    Scenario: Backward compatibility - client using old query parameter casing (e.g., Audit=FULL)
    Given a valid accountId that exists in the system
    And the audit query parameter is provided as 'Audit=FULL'
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline?Audit=FULL
    Then the response status code should be 200 or 400 as per API specification (document observed behavior)

    @TC24
    Scenario: Accessibility - API response structure is compatible with screen readers
    Given a valid accountId that exists in the system
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response body should be a well-formed JSON with clear key names and values for screen reader parsing

    @TC25
    Scenario: Timeout/long-running operation
    Given a valid accountId that exists in the system with a very large timeline
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the API should respond within the documented timeout period (e.g., 30s)
    And if exceeded, the response status code should be 504

    @TC26
    Scenario: Recovery from transient network error
    Given a valid accountId that exists in the system
    And a transient network error occurs during the request
    When the user retries the GET request to /1.0/kb/accounts/{accountId}/timeline
    Then the response status code should be 200
    And the response body should be a valid AccountTimeline JSON object

    @TC27
    Scenario: Error when audit parameter value is invalid
    Given a valid accountId that exists in the system
    And the audit query parameter is set to an unsupported value (e.g., audit=VERBOSE)
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline?audit=VERBOSE
    Then the response status code should be 400
    And the response body should indicate invalid audit parameter value

    @TC28
    Scenario: Error when parallel parameter value is invalid
    Given a valid accountId that exists in the system
    And the parallel query parameter is set to an unsupported value (e.g., parallel=maybe)
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/timeline?parallel=maybe
    Then the response status code should be 400
    And the response body should indicate invalid parallel parameter value