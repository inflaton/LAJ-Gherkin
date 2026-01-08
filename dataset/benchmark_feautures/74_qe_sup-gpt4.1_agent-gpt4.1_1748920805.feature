Feature: Retrieve Plan for Subscription and Date via GET /1.0/kb/catalog/plan
As a KillBill API user,
I want to retrieve the plan for a given subscription and date,
so that I can determine which plan was active for a subscription at a specific date.

  Background:
  Given the KillBill API is running and accessible
  And the database contains subscriptions with diverse plans and effective dates
  And valid and invalid subscription IDs are known
  And valid and invalid requestedDate values are known
  And a valid authentication token is set (if required)

    @TC01
    Scenario: Successful retrieval with both subscriptionId and requestedDate provided
    Given a valid subscriptionId corresponding to an existing subscription
    And a valid requestedDate within the subscription's plan effective period
    When the user sends a GET request to /1.0/kb/catalog/plan with both subscriptionId and requestedDate as query parameters
    Then the response status code should be 200
    And the response body should be a valid JSON Plan object
    And the Plan object should reflect the plan active for that subscription on the requestedDate

    @TC02
    Scenario: Successful retrieval with only subscriptionId provided
    Given a valid subscriptionId corresponding to an existing subscription
    And no requestedDate is provided
    When the user sends a GET request to /1.0/kb/catalog/plan with only subscriptionId as a query parameter
    Then the response status code should be 200
    And the response body should be a valid JSON Plan object
    And the Plan object should reflect the current plan for the subscription

    @TC03
    Scenario: Successful retrieval with only requestedDate provided
    Given a valid requestedDate within the range of at least one subscription's plan
    And no subscriptionId is provided
    When the user sends a GET request to /1.0/kb/catalog/plan with only requestedDate as a query parameter
    Then the response status code should be 200 or an appropriate default plan is returned
    And the response body should be a valid JSON Plan object or an empty object if no plan matches

    @TC04
    Scenario: Successful retrieval with neither parameter provided
    Given no subscriptionId and no requestedDate are provided
    When the user sends a GET request to /1.0/kb/catalog/plan with no query parameters
    Then the response status code should be 200 or an appropriate default plan is returned
    And the response body should be a valid JSON Plan object or an empty object if no plan matches

    @TC05
    Scenario: Error when subscriptionId is invalid (malformed UUID)
    Given a malformed subscriptionId is provided (e.g., not a UUID)
    When the user sends a GET request to /1.0/kb/catalog/plan with the invalid subscriptionId
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid subscriptionId

    @TC06
    Scenario: Error when requestedDate is invalid (malformed date)
    Given a valid subscriptionId is provided
    And a malformed requestedDate is provided (e.g., not in YYYY-MM-DD format)
    When the user sends a GET request to /1.0/kb/catalog/plan with the malformed requestedDate
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid requestedDate

    @TC07
    Scenario: Error when subscriptionId does not exist
    Given a non-existent but well-formed subscriptionId is provided
    When the user sends a GET request to /1.0/kb/catalog/plan with the non-existent subscriptionId
    Then the response status code should be 404
    And the response body should contain an error message indicating subscription not found

    @TC08
    Scenario: Error when both parameters are invalid
    Given a malformed subscriptionId and a malformed requestedDate are provided
    When the user sends a GET request to /1.0/kb/catalog/plan with both invalid parameters
    Then the response status code should be 400
    And the response body should contain error messages for both parameters

    @TC09
    Scenario: Unauthorized access (missing or invalid authentication)
    Given the authentication token is missing or invalid
    When the user sends a GET request to /1.0/kb/catalog/plan
    Then the response status code should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC10
    Scenario: System error (dependency/service unavailable)
    Given the backend service or database is unavailable
    When the user sends a GET request to /1.0/kb/catalog/plan
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailability

    @TC11
    Scenario: Edge case - Empty database (no subscriptions or plans exist)
    Given the database contains no subscriptions or plans
    When the user sends a GET request to /1.0/kb/catalog/plan with any parameters
    Then the response status code should be 200 or 404 depending on implementation
    And the response body should be an empty object or an appropriate error message

    @TC12
    Scenario: Edge case - Multiple plans active on requestedDate (data integrity issue)
    Given a subscriptionId with overlapping plans on the same requestedDate
    When the user sends a GET request to /1.0/kb/catalog/plan with that subscriptionId and requestedDate
    Then the response status code should be 409 or 500 depending on implementation
    And the response body should contain an error message indicating data inconsistency

    @TC13
    Scenario: Edge case - requestedDate at the boundary of plan effective dates
    Given a subscriptionId with a plan that starts or ends on the requestedDate
    When the user sends a GET request to /1.0/kb/catalog/plan with that subscriptionId and requestedDate
    Then the response status code should be 200
    And the response body should be a valid JSON Plan object reflecting the correct boundary plan

    @TC14
    Scenario: Edge case - Extra/unexpected query parameters provided
    Given valid subscriptionId and requestedDate are provided
    And extra, unrelated query parameters are included
    When the user sends a GET request to /1.0/kb/catalog/plan with extra parameters
    Then the response status code should be 200
    And the response body should be a valid JSON Plan object
    And extra parameters should be ignored

    @TC15
    Scenario: Performance - Response time under normal load
    Given the system is under normal operational load
    When the user sends a GET request to /1.0/kb/catalog/plan
    Then the response should be received within 500ms

    @TC16
    Scenario: Performance - Response time under concurrent requests
    Given the system is under high concurrent load (e.g., 100 parallel requests)
    When multiple users send GET requests to /1.0/kb/catalog/plan
    Then all responses should be received within 2 seconds

    @TC17
    Scenario: Security - SQL injection attempt in subscriptionId
    Given a subscriptionId parameter containing SQL injection payload (e.g., '1 OR 1=1')
    When the user sends a GET request to /1.0/kb/catalog/plan
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid input

    @TC18
    Scenario: Security - XSS attempt in requestedDate
    Given a requestedDate parameter containing XSS payload (e.g., '<script>alert(1)</script>')
    When the user sends a GET request to /1.0/kb/catalog/plan
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid input

    @TC19
    Scenario: Regression - Previously fixed issue for missing plan on valid subscriptionId and requestedDate
    Given a valid subscriptionId and requestedDate for which a plan should exist (previously failed)
    When the user sends a GET request to /1.0/kb/catalog/plan
    Then the response status code should be 200
    And the response body should be a valid JSON Plan object

    @TC20
    Scenario: Regression - Backward compatibility with existing clients
    Given an existing client using legacy query patterns
    When the user sends a GET request to /1.0/kb/catalog/plan as per legacy usage
    Then the response status code should be 200
    And the response body should be a valid JSON Plan object