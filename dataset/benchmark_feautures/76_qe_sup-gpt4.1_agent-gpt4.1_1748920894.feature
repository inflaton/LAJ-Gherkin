Feature: Retrieve product for a given subscription and date via GET /1.0/kb/catalog/product
As a KillBill API user,
I want to retrieve the product details for a subscription at a specific date,
so that I can determine the effective product for billing or display purposes.

  Background:
  Given the KillBill API is available and reachable
  And the database contains subscriptions with various plans and effective dates
  And I have a valid authentication token
  And the Product schema is defined and available for validation

    @TC01
    Scenario: Successful retrieval with valid subscriptionId and requestedDate
    Given a subscription exists with id "<valid_subscription_id>" and has a product effective on "<valid_requested_date>"
    When I send a GET request to /1.0/kb/catalog/product with query parameters subscriptionId=<valid_subscription_id> and requestedDate=<valid_requested_date>
    Then the response status code should be 200
    And the response body should be a valid Product object matching the subscription's product on <valid_requested_date>
    And the response Content-Type should be application/json

    @TC02
    Scenario: Successful retrieval with only subscriptionId (requestedDate omitted)
    Given a subscription exists with id "<valid_subscription_id>" and a current effective product
    When I send a GET request to /1.0/kb/catalog/product with query parameter subscriptionId=<valid_subscription_id>
    Then the response status code should be 200
    And the response body should be a valid Product object for the current effective date

    @TC03
    Scenario: Successful retrieval with only requestedDate (subscriptionId omitted)
    Given at least one subscription exists with a product effective on "<valid_requested_date>"
    When I send a GET request to /1.0/kb/catalog/product with query parameter requestedDate=<valid_requested_date>
    Then the response status code should be 200 or an appropriate error if ambiguous
    And the response body should reflect the product(s) effective on <valid_requested_date> or an error message if ambiguous

    @TC04
    Scenario: Successful retrieval with no parameters
    Given the system contains at least one subscription
    When I send a GET request to /1.0/kb/catalog/product with no query parameters
    Then the response status code should be 200 or an appropriate error if not supported
    And the response body should return a default product or an error message indicating missing parameters

    @TC05
    Scenario: Error when subscriptionId does not exist
    Given no subscription exists with id "<nonexistent_subscription_id>"
    When I send a GET request to /1.0/kb/catalog/product with query parameter subscriptionId=<nonexistent_subscription_id>
    Then the response status code should be 404
    And the response body should contain an error message indicating subscription not found

    @TC06
    Scenario: Error when requestedDate is in invalid format
    Given a subscription exists with id "<valid_subscription_id>"
    When I send a GET request to /1.0/kb/catalog/product with subscriptionId=<valid_subscription_id> and requestedDate="invalid-date"
    Then the response status code should be 400
    And the response body should contain an error message about invalid date format

    @TC07
    Scenario: Error when both parameters are missing and not supported
    Given the system requires at least one parameter
    When I send a GET request to /1.0/kb/catalog/product with no query parameters
    Then the response status code should be 400
    And the response body should indicate missing required parameters

    @TC08
    Scenario: Error when subscriptionId is not a valid UUID
    Given the subscriptionId parameter is set to "not-a-uuid"
    When I send a GET request to /1.0/kb/catalog/product with subscriptionId="not-a-uuid"
    Then the response status code should be 400
    And the response body should contain an error message about invalid UUID format

    @TC09
    Scenario: Unauthorized access attempt
    Given I do not provide a valid authentication token
    When I send a GET request to /1.0/kb/catalog/product with any parameters
    Then the response status code should be 401
    And the response body should indicate an authentication error

    @TC10
    Scenario: System error or service unavailable
    Given the KillBill API service is down or unreachable
    When I send a GET request to /1.0/kb/catalog/product
    Then the response status code should be 503
    And the response body should indicate service unavailability

    @TC11
    Scenario: Edge case - Empty database (no subscriptions)
    Given the database contains no subscriptions
    When I send a GET request to /1.0/kb/catalog/product with any parameters
    Then the response status code should be 404
    And the response body should indicate no subscription or product found

    @TC12
    Scenario: Edge case - requestedDate is a future date
    Given a subscription exists with id "<valid_subscription_id>"
    When I send a GET request to /1.0/kb/catalog/product with subscriptionId=<valid_subscription_id> and requestedDate=<future_date>
    Then the response status code should be 200 or 404 depending on business rules
    And the response body should reflect the product effective at <future_date> or indicate not found

    @TC13
    Scenario: Edge case - requestedDate is before subscription start
    Given a subscription exists with id "<valid_subscription_id>" starting after <past_date>
    When I send a GET request to /1.0/kb/catalog/product with subscriptionId=<valid_subscription_id> and requestedDate=<past_date>
    Then the response status code should be 404
    And the response body should indicate no product found for that date

    @TC14
    Scenario: Edge case - Extra/unexpected query parameters
    Given a valid subscription exists
    When I send a GET request to /1.0/kb/catalog/product with subscriptionId=<valid_subscription_id> and foo=bar
    Then the response status code should be 200 if extra params are ignored, or 400 if rejected
    And the response body should be a valid Product object or an error message

    @TC15
    Scenario: Edge case - Large volume of concurrent requests
    Given the system is under normal and peak load
    When multiple clients send concurrent GET requests to /1.0/kb/catalog/product with valid parameters
    Then all responses should return 200 within acceptable response times
    And the system should not degrade or fail

    @TC16
    Scenario: Security - SQL injection attempt in subscriptionId
    Given a malicious value is used for subscriptionId (e.g., "' OR 1=1 --")
    When I send a GET request to /1.0/kb/catalog/product with subscriptionId="' OR 1=1 --"
    Then the response status code should be 400 or 422
    And the response body should indicate invalid input and no sensitive error details

    @TC17
    Scenario: Security - XSS attempt in requestedDate
    Given a malicious value is used for requestedDate (e.g., "<script>alert(1)</script>")
    When I send a GET request to /1.0/kb/catalog/product with requestedDate="<script>alert(1)</script>"
    Then the response status code should be 400 or 422
    And the response body should indicate invalid input and no script is executed

    @TC18
    Scenario: Regression - Previously fixed bug for missing product on boundary date
    Given a subscription exists with a product change effective on <boundary_date>
    When I send a GET request to /1.0/kb/catalog/product with subscriptionId=<valid_subscription_id> and requestedDate=<boundary_date>
    Then the response status code should be 200
    And the response body should be the correct Product object as per the fix

    @TC19
    Scenario: Regression - Backward compatibility with clients omitting requestedDate
    Given a subscription exists with id "<valid_subscription_id>"
    When I send a GET request to /1.0/kb/catalog/product with only subscriptionId=<valid_subscription_id>
    Then the response status code should be 200
    And the response body should be the current Product object

    @TC20
    Scenario: Performance - Response time under normal and peak load
    Given the system is operating under normal and peak conditions
    When I send a GET request to /1.0/kb/catalog/product with valid parameters
    Then the response time should be less than <acceptable_threshold> ms

    @TC21
    Scenario: Integration - Dependency service is unavailable
    Given the product lookup relies on a downstream service that is unavailable
    When I send a GET request to /1.0/kb/catalog/product with valid parameters
    Then the response status code should be 502 or 503
    And the response body should indicate dependency failure

    @TC22
    Scenario: Integration - Data consistency across catalog and subscription
    Given a subscription and product exist and are linked
    When I send a GET request to /1.0/kb/catalog/product with valid parameters
    Then the response Product object should match the catalog definition for that product

    @TC23
    Scenario: Accessibility - API documentation is accessible
    Given I am a user with assistive technology
    When I access the API documentation for /1.0/kb/catalog/product
    Then the documentation should be readable by screen readers and comply with accessibility standards