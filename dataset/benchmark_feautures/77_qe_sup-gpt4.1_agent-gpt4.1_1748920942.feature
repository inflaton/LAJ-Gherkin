Feature: Retrieve priceList for a given subscription and date
As a KillBill API user,
I want to retrieve the price list for a subscription at a specific date,
so that I can determine the effective price list for that subscription.

  Background:
  Given the KillBill API is running and accessible
  And the /1.0/kb/catalog/priceList endpoint is available
  And the database is seeded with subscriptions, plans, and price lists
  And valid and invalid subscription IDs are known
  And authentication tokens are set as required

    @TC01
    Scenario: Successful retrieval with valid subscriptionId and requestedDate
    Given a valid subscriptionId exists in the system
    And a valid requestedDate is provided in YYYY-MM-DD format
    When the user sends a GET request to /1.0/kb/catalog/priceList with both subscriptionId and requestedDate as query parameters
    Then the API should respond with HTTP 200
    And the response body should be a valid PriceList JSON object associated with the subscription's plan on that date
    And the response content type should be application/json

    @TC02
    Scenario: Successful retrieval with only subscriptionId
    Given a valid subscriptionId exists in the system
    And requestedDate is omitted
    When the user sends a GET request to /1.0/kb/catalog/priceList with only subscriptionId as a query parameter
    Then the API should respond with HTTP 200
    And the response body should be a valid PriceList JSON object associated with the current plan of the subscription
    And the response content type should be application/json

    @TC03
    Scenario: Successful retrieval with only requestedDate
    Given requestedDate is provided in YYYY-MM-DD format
    And subscriptionId is omitted
    When the user sends a GET request to /1.0/kb/catalog/priceList with only requestedDate as a query parameter
    Then the API should respond with HTTP 200 or a default PriceList JSON object if applicable
    And the response content type should be application/json

    @TC04
    Scenario: Successful retrieval with no parameters
    Given no query parameters are provided
    When the user sends a GET request to /1.0/kb/catalog/priceList
    Then the API should respond with HTTP 200 or a default PriceList JSON object if applicable
    And the response content type should be application/json

    @TC05
    Scenario: Invalid subscriptionId format
    Given an invalid subscriptionId (not a UUID) is provided
    When the user sends a GET request to /1.0/kb/catalog/priceList with the invalid subscriptionId
    Then the API should respond with HTTP 400
    And the response body should contain an error message indicating invalid subscriptionId format

    @TC06
    Scenario: Non-existent subscriptionId
    Given a well-formed but non-existent subscriptionId is provided
    When the user sends a GET request to /1.0/kb/catalog/priceList with the non-existent subscriptionId
    Then the API should respond with HTTP 404
    And the response body should contain an error message indicating subscription not found

    @TC07
    Scenario: Invalid requestedDate format
    Given a requestedDate is provided in an invalid format (e.g., not YYYY-MM-DD)
    When the user sends a GET request to /1.0/kb/catalog/priceList with the invalid requestedDate
    Then the API should respond with HTTP 400
    And the response body should contain an error message indicating invalid date format

    @TC08
    Scenario: Unauthorized access
    Given the authentication token is missing or invalid
    When the user sends a GET request to /1.0/kb/catalog/priceList
    Then the API should respond with HTTP 401
    And the response body should contain an error message indicating unauthorized access

    @TC09
    Scenario: Service unavailable
    Given the KillBill service is down or unreachable
    When the user sends a GET request to /1.0/kb/catalog/priceList
    Then the API should respond with HTTP 503
    And the response body should contain an error message indicating service unavailability

    @TC10
    Scenario: Injection attack attempt in subscriptionId
    Given a subscriptionId containing SQL injection payload is provided
    When the user sends a GET request to /1.0/kb/catalog/priceList with the malicious subscriptionId
    Then the API should respond with HTTP 400 or 422
    And the response body should not expose internal server details

    @TC11
    Scenario: Large payload in query parameters
    Given a subscriptionId or requestedDate exceeding maximum allowed length is provided
    When the user sends a GET request to /1.0/kb/catalog/priceList
    Then the API should respond with HTTP 400
    And the response body should contain an error message indicating parameter size limit exceeded

    @TC12
    Scenario: Extra unexpected query parameters
    Given additional unexpected query parameters are provided
    When the user sends a GET request to /1.0/kb/catalog/priceList with extra parameters
    Then the API should respond with HTTP 200
    And the extra parameters should be ignored
    And the response body should be a valid PriceList JSON object if other parameters are valid

    @TC13
    Scenario: Empty database (no subscriptions or price lists)
    Given the database contains no subscriptions or price lists
    When the user sends a GET request to /1.0/kb/catalog/priceList with any parameters
    Then the API should respond with HTTP 404 or an empty/default response
    And the response body should indicate no data found

    @TC14
    Scenario: Response time under normal load
    Given the system is under normal operational load
    When the user sends a GET request to /1.0/kb/catalog/priceList
    Then the API should respond within 500ms

    @TC15
    Scenario: Response time under peak load
    Given the system is under simulated peak load with concurrent requests
    When the user sends multiple concurrent GET requests to /1.0/kb/catalog/priceList
    Then the API should respond to each request within 2 seconds

    @TC16
    Scenario: Backward compatibility with previous clients
    Given a client previously integrated with the API
    When the client sends a GET request to /1.0/kb/catalog/priceList as per old usage pattern
    Then the API should respond with HTTP 200 and a valid PriceList JSON object

    @TC17
    Scenario: Retry after transient network failure
    Given a network failure occurs during the request
    When the user retries the GET request to /1.0/kb/catalog/priceList
    Then the API should respond with HTTP 200 and a valid PriceList JSON object if the system has recovered

    @TC18
    Scenario: Large data volume for a subscription
    Given a subscriptionId is associated with a large number of price list changes
    When the user sends a GET request to /1.0/kb/catalog/priceList with that subscriptionId
    Then the API should respond with HTTP 200
    And the response body should include the correct PriceList JSON object
    And the response time should remain within acceptable limits

    @TC19
    Scenario: Malformed or partial query parameter values
    Given a subscriptionId or requestedDate is partially provided or malformed
    When the user sends a GET request to /1.0/kb/catalog/priceList
    Then the API should respond with HTTP 400
    And the response body should indicate invalid parameter value

    @TC20
    Scenario: Integration with dependent catalog service unavailable
    Given the dependent catalog service is unavailable
    When the user sends a GET request to /1.0/kb/catalog/priceList
    Then the API should respond with HTTP 502
    And the response body should indicate dependency failure

    @TC21
    Scenario: Regression - previously fixed issue with date boundary
    Given a subscriptionId and a requestedDate at the edge of a price list change
    When the user sends a GET request to /1.0/kb/catalog/priceList
    Then the API should respond with HTTP 200
    And the response body should reflect the correct PriceList for that date boundary

    @TC22
    Scenario: Security - XSS attempt in query parameter
    Given a subscriptionId or requestedDate containing XSS payload is provided
    When the user sends a GET request to /1.0/kb/catalog/priceList
    Then the API should respond with HTTP 400 or 422
    And the response body should not execute or reflect the malicious script

    @TC23
    Scenario: Accessibility - screen reader compatibility (if UI involved)
    Given the API response is rendered in a UI
    When a user accesses the price list information using a screen reader
    Then all information should be accessible and correctly labeled for assistive technologies