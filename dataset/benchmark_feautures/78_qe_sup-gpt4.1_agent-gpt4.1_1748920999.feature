Feature: Add a simple plan to the current catalog version via POST /1.0/kb/catalog/simplePlan
As a KillBill API user,
I want to add a simple plan to the catalog using the POST /1.0/kb/catalog/simplePlan endpoint,
so that I can extend the catalog with new plans as needed.

  Background:
  Given the KillBill API is running and accessible
  And the current catalog version exists
  And valid API authentication credentials are available
  And the database is seeded with sample products and plans
  And the endpoint POST /1.0/kb/catalog/simplePlan is available

    @TC01
    Scenario: Successfully add a simple plan with all required fields
    Given a valid X-Killbill-CreatedBy header is provided
    And a valid SimplePlan object with unique planId, valid productName, productCategory, currency, amount, and billingPeriod is provided in the request body
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201
    And the response body contains a confirmation string or URI
    And the new plan is retrievable from the catalog

    @TC02
    Scenario: Successfully add a simple plan with optional headers
    Given a valid X-Killbill-CreatedBy header is provided
    And X-Killbill-Reason and X-Killbill-Comment headers are provided with valid strings
    And a valid SimplePlan object is provided in the request body
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201
    And the response body contains a confirmation string or URI

    @TC03
    Scenario: Attempt to add a simple plan with missing required header X-Killbill-CreatedBy
    Given the X-Killbill-CreatedBy header is missing
    And a valid SimplePlan object is provided in the request body
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 400
    And the response body contains an error message indicating the missing header

    @TC04
    Scenario: Attempt to add a simple plan with missing required fields in SimplePlan object
    Given a valid X-Killbill-CreatedBy header is provided
    And the SimplePlan object is missing the planId field
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 400
    And the response body contains an error message indicating the missing field

    @TC05
    Scenario: Attempt to add a simple plan with invalid values in SimplePlan object
    Given a valid X-Killbill-CreatedBy header is provided
    And the SimplePlan object contains an invalid currency code
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 400
    And the response body contains an error message indicating the invalid currency

    @TC06
    Scenario: Attempt to add a simple plan with a planId that already exists
    Given a valid X-Killbill-CreatedBy header is provided
    And the SimplePlan object contains a planId that already exists in the catalog
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 400
    And the response body contains an error message indicating the conflict

    @TC07
    Scenario: Attempt to add a simple plan with extra, unsupported fields in the SimplePlan object
    Given a valid X-Killbill-CreatedBy header is provided
    And the SimplePlan object contains extra fields not defined in the schema
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201
    And the response body contains a confirmation string or URI

    @TC08
    Scenario: Attempt to add a simple plan with empty request body
    Given a valid X-Killbill-CreatedBy header is provided
    And the request body is empty
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 400
    And the response body contains an error message indicating the missing request body

    @TC09
    Scenario: Attempt to add a simple plan with malformed JSON in the request body
    Given a valid X-Killbill-CreatedBy header is provided
    And the request body contains malformed JSON
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid JSON

    @TC10
    Scenario: Attempt to add a simple plan without authentication
    Given the API request is missing authentication credentials
    And a valid SimplePlan object is provided in the request body
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 401
    And the response body contains an authentication error message

    @TC11
    Scenario: Attempt to add a simple plan when the catalog is unavailable
    Given the catalog service is down or unreachable
    And a valid X-Killbill-CreatedBy header is provided
    And a valid SimplePlan object is provided in the request body
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 503
    And the response body contains a service unavailable error message

    @TC12
    Scenario: Attempt to add a simple plan with maximum allowed field lengths
    Given a valid X-Killbill-CreatedBy header is provided
    And a SimplePlan object with maximum allowed lengths for planId, productName, and other string fields is provided
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201
    And the response body contains a confirmation string or URI

    @TC13
    Scenario: Attempt to add a simple plan with minimum allowed field values
    Given a valid X-Killbill-CreatedBy header is provided
    And a SimplePlan object with minimum allowed values for amount and other fields is provided
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201
    And the response body contains a confirmation string or URI

    @TC14
    Scenario: Attempt to add a simple plan with unsupported HTTP method
    Given a valid X-Killbill-CreatedBy header is provided
    And a valid SimplePlan object is provided in the request body
    When the user sends a GET request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 405
    And the response body contains a method not allowed error message

    @TC15
    Scenario: Attempt to add a simple plan with a very large request payload
    Given a valid X-Killbill-CreatedBy header is provided
    And a SimplePlan object with a very large amount of data (e.g., long comments, large numbers) is provided in the request body
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201 or 400 depending on system limits
    And the response body contains either a confirmation string or an error message indicating payload too large

    @TC16
    Scenario: System recovers from a temporary network failure during plan creation
    Given a valid X-Killbill-CreatedBy header is provided
    And a valid SimplePlan object is provided in the request body
    And a temporary network failure occurs during the request
    When the network recovers and the user retries the POST request
    Then the API responds with HTTP 201
    And the response body contains a confirmation string or URI

    @TC17
    Scenario: Verify response time for plan creation is within acceptable threshold
    Given a valid X-Killbill-CreatedBy header is provided
    And a valid SimplePlan object is provided in the request body
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds within 2 seconds
    And the response body contains a confirmation string or URI

    @TC18
    Scenario: Attempt to add a simple plan with XSS or SQL injection in input fields
    Given a valid X-Killbill-CreatedBy header is provided
    And a SimplePlan object contains script tags or SQL injection patterns in string fields
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid input

    @TC19
    Scenario: Add a simple plan when the catalog is empty
    Given the catalog contains no plans or products
    And a valid X-Killbill-CreatedBy header is provided
    And a valid SimplePlan object with new productName and planId is provided in the request body
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201
    And the response body contains a confirmation string or URI

    @TC20
    Scenario: Add a simple plan when the catalog is partially populated
    Given the catalog contains some products and plans
    And a valid X-Killbill-CreatedBy header is provided
    And a valid SimplePlan object with unique planId is provided in the request body
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201
    And the response body contains a confirmation string or URI

    @TC21
    Scenario: Verify backward compatibility with previous API clients
    Given a valid X-Killbill-CreatedBy header is provided
    And a valid SimplePlan object is provided in the request body using fields supported in previous API versions
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201
    And the response body contains a confirmation string or URI

    @TC22
    Scenario: Concurrent requests to add simple plans
    Given multiple valid X-Killbill-CreatedBy headers are provided
    And multiple valid SimplePlan objects with unique planIds are provided in concurrent requests
    When the users send concurrent POST requests to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201 for each valid request
    And each response body contains a confirmation string or URI

    @TC23
    Scenario: Integration with dependent catalog services
    Given a valid X-Killbill-CreatedBy header is provided
    And a valid SimplePlan object is provided in the request body
    And the dependent catalog services are available
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201
    And the response body contains a confirmation string or URI
    And the new plan is available in dependent catalog services

    @TC24
    Scenario: Integration when dependent catalog services are degraded
    Given a valid X-Killbill-CreatedBy header is provided
    And a valid SimplePlan object is provided in the request body
    And the dependent catalog services are degraded
    When the user sends a POST request to /1.0/kb/catalog/simplePlan
    Then the API responds with HTTP 201 or 503 depending on integration resilience
    And the response body contains either a confirmation string or a service unavailable error message