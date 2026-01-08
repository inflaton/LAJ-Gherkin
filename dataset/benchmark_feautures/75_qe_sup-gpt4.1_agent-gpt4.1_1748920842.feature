Feature: Retrieve catalog phase for a given subscription and date
As a KillBill API user,
I want to retrieve the phase for a subscription at a specific date using GET /1.0/kb/catalog/phase,
so that I can determine the subscription's phase details for business logic or reporting.

  Background:
  Given the KillBill API server is running and reachable
  And the API endpoint GET /1.0/kb/catalog/phase is available
  And the database contains subscriptions with diverse phases and dates
  And I have a valid authentication token

    @TC01
    Scenario: Successful retrieval with both subscriptionId and requestedDate provided
    Given a valid subscriptionId exists in the system
    And a valid requestedDate within the subscription's active period
    When I send a GET request to /1.0/kb/catalog/phase with subscriptionId and requestedDate as query parameters
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should contain a valid Phase object for that subscription and date

    @TC02
    Scenario: Retrieval with only subscriptionId provided
    Given a valid subscriptionId exists in the system
    And no requestedDate is provided
    When I send a GET request to /1.0/kb/catalog/phase with only subscriptionId as a query parameter
    Then the response status code should be 200 or a default phase is returned if defined
    And the response body should contain a Phase object or a meaningful default

    @TC03
    Scenario: Retrieval with only requestedDate provided
    Given no subscriptionId is provided
    And a valid requestedDate is provided
    When I send a GET request to /1.0/kb/catalog/phase with only requestedDate as a query parameter
    Then the response status code should be 400
    And the response body should contain an error message indicating missing subscriptionId

    @TC04
    Scenario: Retrieval with neither parameter provided
    Given neither subscriptionId nor requestedDate is provided
    When I send a GET request to /1.0/kb/catalog/phase with no query parameters
    Then the response status code should be 400
    And the response body should contain an error message indicating missing parameters

    @TC05
    Scenario: Retrieval for non-existent subscriptionId
    Given a subscriptionId that does not exist in the system
    And a valid requestedDate
    When I send a GET request to /1.0/kb/catalog/phase with the non-existent subscriptionId and requestedDate
    Then the response status code should be 404
    And the response body should contain an error message indicating subscription not found

    @TC06
    Scenario: Retrieval with invalid subscriptionId format
    Given an invalid subscriptionId (not a UUID format)
    And a valid requestedDate
    When I send a GET request to /1.0/kb/catalog/phase with the invalid subscriptionId and requestedDate
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid subscriptionId format

    @TC07
    Scenario: Retrieval with invalid requestedDate format
    Given a valid subscriptionId
    And an invalid requestedDate (not in date format)
    When I send a GET request to /1.0/kb/catalog/phase with subscriptionId and invalid requestedDate
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid date format

    @TC08
    Scenario: Retrieval with requestedDate outside subscription's active period
    Given a valid subscriptionId
    And a requestedDate before the subscription's start date or after its end date
    When I send a GET request to /1.0/kb/catalog/phase with subscriptionId and out-of-range requestedDate
    Then the response status code should be 404
    And the response body should contain an error message indicating no phase found for the specified date

    @TC09
    Scenario: Unauthorized access attempt
    Given a valid subscriptionId and requestedDate
    And the authentication token is missing or invalid
    When I send a GET request to /1.0/kb/catalog/phase
    Then the response status code should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC10
    Scenario: System error or dependency failure
    Given the KillBill service or a dependency is unavailable
    When I send a GET request to /1.0/kb/catalog/phase
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC11
    Scenario: Security - SQL injection attempt in subscriptionId
    Given a malicious subscriptionId input attempting SQL injection
    And a valid requestedDate
    When I send a GET request to /1.0/kb/catalog/phase
    Then the response status code should be 400 or 422
    And the response body should not expose internal errors

    @TC12
    Scenario: Edge case - Empty database
    Given the database contains no subscriptions
    When I send a GET request to /1.0/kb/catalog/phase with any parameters
    Then the response status code should be 404
    And the response body should indicate no subscription found

    @TC13
    Scenario: Edge case - Large payload handling
    Given the database contains a large number of subscriptions and phases
    When I send a GET request to /1.0/kb/catalog/phase with valid parameters
    Then the response status code should be 200
    And the response time should be within acceptable thresholds (e.g., < 2 seconds)
    And the response body should contain the correct Phase object

    @TC14
    Scenario: Extra parameters provided
    Given a valid subscriptionId and requestedDate
    And extra, unsupported query parameters are included
    When I send a GET request to /1.0/kb/catalog/phase
    Then the response status code should be 200
    And the extra parameters are ignored
    And the response body should contain the correct Phase object

    @TC15
    Scenario: Regression - previously fixed bug for phase retrieval on boundary date
    Given a valid subscriptionId
    And a requestedDate exactly on the boundary of a phase change
    When I send a GET request to /1.0/kb/catalog/phase
    Then the response status code should be 200
    And the response body should contain the correct Phase object for the boundary date

    @TC16
    Scenario: Performance - concurrent requests
    Given multiple valid subscriptionIds and requestedDates
    When I send concurrent GET requests to /1.0/kb/catalog/phase
    Then all responses should have status code 200
    And each response should contain the correct Phase object
    And response times should remain within acceptable limits