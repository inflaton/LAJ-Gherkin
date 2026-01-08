Feature: Retrieve available add-ons for a given product via GET /1.0/kb/catalog/availableAddons
As a KillBill API user,
I want to retrieve available add-ons for a given base product and optional price list,
so that I can present or select valid add-on plans for a product.

  Background:
  Given the KillBill API server is running and reachable
  And the /1.0/kb/catalog/availableAddons endpoint is available
  And the database contains a diverse set of products, price lists, and add-ons
  And valid and invalid authentication tokens are available
  And the system clock is synchronized

    @TC01
    Scenario: Successful retrieval with no query parameters (all add-ons)
    Given the system contains multiple base products and add-ons
    When the user sends a GET request to /1.0/kb/catalog/availableAddons with no query parameters
    Then the response code should be 200
    And the response body should be a JSON array of PlanDetail objects for all available add-ons
    And the response content-type should be application/json
    And the response time should be less than 2 seconds

    @TC02
    Scenario: Successful retrieval with only baseProductName specified
    Given a base product "BaseProductA" exists with associated add-ons
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?baseProductName=BaseProductA
    Then the response code should be 200
    And the response body should be a JSON array of PlanDetail objects relevant to "BaseProductA"
    And each PlanDetail should reference add-ons valid for "BaseProductA"
    And the response content-type should be application/json

    @TC03
    Scenario: Successful retrieval with only priceListName specified
    Given a price list "StandardPriceList" exists with associated add-ons
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?priceListName=StandardPriceList
    Then the response code should be 200
    And the response body should be a JSON array of PlanDetail objects relevant to "StandardPriceList"
    And the response content-type should be application/json

    @TC04
    Scenario: Successful retrieval with baseProductName and priceListName specified
    Given a base product "BaseProductA" and price list "StandardPriceList" exist with associated add-ons
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?baseProductName=BaseProductA&priceListName=StandardPriceList
    Then the response code should be 200
    And the response body should be a JSON array of PlanDetail objects relevant to both "BaseProductA" and "StandardPriceList"
    And the response content-type should be application/json

    @TC05
    Scenario: Successful retrieval with all parameters specified (including accountId)
    Given a base product "BaseProductA", price list "StandardPriceList", and accountId "123e4567-e89b-12d3-a456-426614174000" exist
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?baseProductName=BaseProductA&priceListName=StandardPriceList&accountId=123e4567-e89b-12d3-a456-426614174000
    Then the response code should be 200
    And the response body should be a JSON array of PlanDetail objects relevant to the specified base product, price list, and tenant context
    And the response content-type should be application/json

    @TC06
    Scenario: Retrieval when no add-ons exist for the given base product
    Given a base product "BaseProductNoAddons" exists with no associated add-ons
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?baseProductName=BaseProductNoAddons
    Then the response code should be 200
    And the response body should be an empty JSON array
    And the response content-type should be application/json

    @TC07
    Scenario: Retrieval when the catalog is empty
    Given the catalog contains no products or add-ons
    When the user sends a GET request to /1.0/kb/catalog/availableAddons
    Then the response code should be 200
    And the response body should be an empty JSON array
    And the response content-type should be application/json

    @TC08
    Scenario: Invalid baseProductName parameter (non-existent product)
    Given the base product "NonExistentProduct" does not exist
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?baseProductName=NonExistentProduct
    Then the response code should be 404
    And the response body should contain an error message indicating base product not found

    @TC09
    Scenario: Invalid priceListName parameter (non-existent price list)
    Given the price list "NonExistentPriceList" does not exist
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?priceListName=NonExistentPriceList
    Then the response code should be 404
    And the response body should contain an error message indicating price list not found

    @TC10
    Scenario: Invalid accountId parameter (malformed UUID)
    Given the accountId parameter is set to "invalid-uuid"
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?accountId=invalid-uuid
    Then the response code should be 400
    And the response body should contain an error message indicating invalid UUID format

    @TC11
    Scenario: Missing authentication token (if required)
    Given authentication is required and the request lacks a valid token
    When the user sends a GET request to /1.0/kb/catalog/availableAddons
    Then the response code should be 401
    And the response body should contain an authentication error message

    @TC12
    Scenario: Unauthorized access with invalid authentication token
    Given authentication is required and the request contains an invalid token
    When the user sends a GET request to /1.0/kb/catalog/availableAddons
    Then the response code should be 401
    And the response body should contain an authentication error message

    @TC13
    Scenario: System error - catalog service unavailable
    Given the catalog service is down or unreachable
    When the user sends a GET request to /1.0/kb/catalog/availableAddons
    Then the response code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC14
    Scenario: System error - database failure
    Given the database is down or not responding
    When the user sends a GET request to /1.0/kb/catalog/availableAddons
    Then the response code should be 500
    And the response body should contain a generic server error message

    @TC15
    Scenario: Security - SQL injection attempt in baseProductName
    Given a malicious baseProductName parameter with SQL injection content "BaseProductA'; DROP TABLE products;--"
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?baseProductName=BaseProductA'; DROP TABLE products;--
    Then the response code should be 400 or 422
    And the response body should contain an error message indicating invalid input
    And no data should be altered in the database

    @TC16
    Scenario: Security - XSS attempt in priceListName
    Given a malicious priceListName parameter with XSS content "<script>alert('xss')</script>"
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?priceListName=<script>alert('xss')</script>
    Then the response code should be 400 or 422
    And the response body should contain an error message indicating invalid input

    @TC17
    Scenario: Extra/unsupported parameters are ignored
    Given the user provides an extra query parameter "foo=bar"
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?foo=bar
    Then the response code should be 200
    And the response body should be a JSON array of PlanDetail objects (all add-ons)
    And the extra parameter should not affect the result

    @TC18
    Scenario: Large data volume - many add-ons returned
    Given the system contains 1000+ add-ons for a base product "BaseProductA"
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?baseProductName=BaseProductA
    Then the response code should be 200
    And the response body should be a JSON array with 1000+ PlanDetail objects
    And the response time should be less than 5 seconds

    @TC19
    Scenario: Partial input - only accountId specified
    Given a valid accountId "123e4567-e89b-12d3-a456-426614174000" exists
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?accountId=123e4567-e89b-12d3-a456-426614174000
    Then the response code should be 200
    And the response body should be a JSON array of PlanDetail objects relevant to the account's tenant context

    @TC20
    Scenario: Timeout condition - slow backend
    Given the backend is intentionally delayed to exceed timeout threshold
    When the user sends a GET request to /1.0/kb/catalog/availableAddons
    Then the response code should be 504
    And the response body should contain a timeout error message

    @TC21
    Scenario: Regression - previously fixed issue with empty price list
    Given a previously fixed bug where empty priceListName caused a 500 error
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?priceListName=
    Then the response code should be 200
    And the response body should be a JSON array of PlanDetail objects (all add-ons or filtered appropriately)

    @TC22
    Scenario: Regression - backward compatibility
    Given a client using the previous version of the API with only baseProductName
    When the user sends a GET request to /1.0/kb/catalog/availableAddons?baseProductName=BaseProductA
    Then the response code should be 200
    And the response body should be a JSON array of PlanDetail objects

    @TC23
    Scenario: Concurrent requests
    Given multiple users send GET requests to /1.0/kb/catalog/availableAddons concurrently
    When 100 requests are sent in parallel
    Then all responses should have code 200
    And each response body should be a valid JSON array of PlanDetail objects
    And the system should not degrade below acceptable response times