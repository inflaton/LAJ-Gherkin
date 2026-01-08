Feature: Retrieve available base plans via GET /1.0/kb/catalog/availableBasePlans
As a KillBill API user,
I want to retrieve all available base plans from the catalog,
so that I can view and select from the available base plans for my account or tenant.

  Background:
  Given the KillBill API service is running and accessible
  And the /1.0/kb/catalog/availableBasePlans endpoint is available
  And the database is seeded with a diverse set of base plans (including at least one base plan, and at least one account with a valid UUID)
  And valid authentication tokens are provided in the request headers
  And the system is configured to handle tenant-specific catalogs if applicable

    @TC01
    Scenario: Successful retrieval of all available base plans without accountId
    Given there are multiple base plans available in the catalog
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans without any query parameters
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array of PlanDetail objects representing all available base plans
    And each PlanDetail object should contain all required fields as per the API specification

    @TC02
    Scenario: Successful retrieval of available base plans with a valid accountId
    Given there are multiple base plans available in the catalog
    And a valid accountId is provided as a query parameter
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans?accountId=<valid-uuid>
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array of PlanDetail objects filtered or customized for the specified account if applicable
    And each PlanDetail object should contain all required fields as per the API specification

    @TC03
    Scenario: Retrieval when no base plans exist in the catalog
    Given the catalog contains no base plans
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be an empty JSON array

    @TC04
    Scenario: Retrieval with an accountId that does not exist
    Given a non-existent accountId is provided as a query parameter
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans?accountId=<nonexistent-uuid>
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a JSON array of PlanDetail objects (default catalog or empty if tenant-specific logic applies)

    @TC05
    Scenario: Retrieval with an invalid accountId format
    Given an invalid accountId (not a UUID) is provided as a query parameter
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans?accountId=invalid-format
    Then the response status code should be 400 or 422 depending on API validation
    And the response body should contain an error message indicating invalid accountId format

    @TC06
    Scenario: Unauthorized access attempt
    Given the request is sent without authentication tokens or with invalid tokens
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication failure

    @TC07
    Scenario: System error occurs (e.g., catalog service unavailable)
    Given the catalog service is down or unreachable
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailability

    @TC08
    Scenario: Request with unsupported or extra query parameters
    Given the user provides unsupported or extra query parameters
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans?foo=bar
    Then the response status code should be 200
    And the response body should be a JSON array of PlanDetail objects (ignoring unsupported parameters)

    @TC09
    Scenario: Performance under normal load
    Given there are 100 base plans in the catalog
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans
    Then the response status code should be 200
    And the response time should be less than 1 second

    @TC10
    Scenario: Performance under peak load (concurrent requests)
    Given there are 1000 base plans in the catalog
    When 100 concurrent GET requests are sent to /1.0/kb/catalog/availableBasePlans
    Then all responses should have status code 200
    And the average response time should be within acceptable SLA thresholds

    @TC11
    Scenario: Large payload handling (maximum allowed base plans)
    Given the catalog contains the maximum allowed number of base plans (e.g., 10,000)
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans
    Then the response status code should be 200
    And the response body should be a JSON array containing all base plans without truncation

    @TC12
    Scenario: Security - SQL injection attempt in accountId
    Given the user attempts to inject SQL via the accountId parameter
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans?accountId=' OR '1'='1
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid input
    And no sensitive information should be leaked

    @TC13
    Scenario: Security - XSS attempt in accountId
    Given the user attempts to inject JavaScript via the accountId parameter
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans?accountId=<script>alert('xss')</script>
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid input
    And no script content should be reflected in the response

    @TC14
    Scenario: Regression - previously fixed bug for empty array response
    Given the catalog is empty
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans
    Then the response status code should be 200
    And the response body should be an empty JSON array
    And no server error is returned

    @TC15
    Scenario: Backward compatibility - client using previous API version
    Given a client sends a GET request to /1.0/kb/catalog/availableBasePlans using headers or patterns from the previous version
    When the request is processed
    Then the response status code should be 200
    And the response body should be compatible with the previous version's expectations

    @TC16
    Scenario: Integration - dependent service (e.g., pricing engine) is degraded
    Given the pricing engine is slow or returns partial data
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans
    Then the response status code should be 200 or 206 (if partial content is supported)
    And the response body should reflect the available data
    And an appropriate warning or error message should be included if data is incomplete

    @TC17
    Scenario: Timeout condition
    Given the catalog service takes longer than the configured timeout to respond
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans
    Then the response status code should be 504
    And the response body should contain a timeout error message

    @TC18
    Scenario: Accessibility - response structure is machine-readable
    Given the user is using an accessibility tool
    When the user sends a GET request to /1.0/kb/catalog/availableBasePlans
    Then the response should be valid JSON
    And the response should be easily parsed by screen readers or assistive technologies