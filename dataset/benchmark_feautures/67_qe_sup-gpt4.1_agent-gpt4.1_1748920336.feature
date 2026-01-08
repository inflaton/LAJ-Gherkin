Feature: Retrieve full catalog as XML via GET /1.0/kb/catalog/xml
As a KillBill API user,
I want to retrieve the catalog in XML format (optionally for a specific date or account),
so that I can access catalog information in a standardized, parseable format.

  Background:
  Given the KillBill API server is running and accessible
  And the database contains catalog data with multiple versions and at least one account
  And a valid authentication token is present in the request headers
  And the API endpoint /1.0/kb/catalog/xml is available

    @TC01
    Scenario: Successful retrieval of latest catalog as XML (no parameters)
    Given the system contains at least one catalog version
    When the user sends a GET request to /1.0/kb/catalog/xml with no query parameters
    Then the response status code should be 200
    And the response Content-Type should be text/xml
    And the response body should contain the latest catalog in valid XML format

    @TC02
    Scenario: Successful retrieval of catalog as XML for a specific requestedDate
    Given the system contains catalog versions effective at multiple dates
    And the requestedDate matches an existing catalog version
    When the user sends a GET request to /1.0/kb/catalog/xml with requestedDate set to a valid date-time string
    Then the response status code should be 200
    And the response Content-Type should be text/xml
    And the response body should contain the catalog version effective at the requestedDate in valid XML format

    @TC03
    Scenario: Successful retrieval of catalog as XML for a specific accountId
    Given the system contains at least one account and tenant-specific catalog features are enabled
    When the user sends a GET request to /1.0/kb/catalog/xml with accountId set to a valid UUID
    Then the response status code should be 200
    And the response Content-Type should be text/xml
    And the response body should contain the catalog for the specified account in valid XML format

    @TC04
    Scenario: Successful retrieval of catalog as XML with both requestedDate and accountId
    Given the system contains catalog versions for multiple accounts and effective dates
    When the user sends a GET request to /1.0/kb/catalog/xml with both requestedDate and accountId set to valid values
    Then the response status code should be 200
    And the response Content-Type should be text/xml
    And the response body should contain the catalog version for the specified account and date in valid XML format

    @TC05
    Scenario: Retrieval when no catalog exists in the system
    Given the system contains no catalog data
    When the user sends a GET request to /1.0/kb/catalog/xml
    Then the response status code should be 404 or 400
    And the response body should contain an error message indicating no catalog found

    @TC06
    Scenario: Retrieval when requestedDate does not match any catalog version
    Given the system contains catalog versions but none effective at the requestedDate
    When the user sends a GET request to /1.0/kb/catalog/xml with requestedDate set to a non-matching date
    Then the response status code should be 404 or 400
    And the response body should contain an error message indicating no catalog found for the requested date

    @TC07
    Scenario: Retrieval with invalid requestedDate format
    Given the user provides a requestedDate parameter that is not a valid date-time string
    When the user sends a GET request to /1.0/kb/catalog/xml with requestedDate set to an invalid value
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid date format

    @TC08
    Scenario: Retrieval with invalid accountId format
    Given the user provides an accountId parameter that is not a valid UUID
    When the user sends a GET request to /1.0/kb/catalog/xml with accountId set to an invalid value
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid account ID

    @TC09
    Scenario: Retrieval with extra unsupported query parameters
    Given the user provides additional unsupported query parameters
    When the user sends a GET request to /1.0/kb/catalog/xml with extra parameters
    Then the response status code should be 200
    And the response body should contain the catalog as per the other valid parameters

    @TC10
    Scenario: Unauthorized access attempt
    Given the request is missing a valid authentication token
    When the user sends a GET request to /1.0/kb/catalog/xml
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication failure

    @TC11
    Scenario: Forbidden access due to insufficient permissions
    Given the user is authenticated but lacks permission to access the catalog
    When the user sends a GET request to /1.0/kb/catalog/xml
    Then the response status code should be 403
    And the response body should contain an error message indicating insufficient permissions

    @TC12
    Scenario: Service unavailable or dependency failure
    Given the catalog service or a dependent service is down
    When the user sends a GET request to /1.0/kb/catalog/xml
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC13
    Scenario: Malicious payload or injection attempt in query parameters
    Given the user provides a query parameter value containing an injection attempt (e.g., SQL/XML injection string)
    When the user sends a GET request to /1.0/kb/catalog/xml with the malicious value
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid input
    And the system should not execute any unintended commands

    @TC14
    Scenario: Recovery from transient network failure
    Given a transient network failure occurs during the request
    When the user retries the GET request to /1.0/kb/catalog/xml
    Then the response status code should be 200 if the service is restored
    And the response body should contain the expected catalog XML

    @TC15
    Scenario: Empty response when catalog is empty
    Given the catalog exists but contains no products or plans
    When the user sends a GET request to /1.0/kb/catalog/xml
    Then the response status code should be 200
    And the response body should contain a valid but empty catalog XML structure

    @TC16
    Scenario: Retrieval with maximum allowed parameter lengths
    Given the user provides requestedDate and accountId at their maximum allowed lengths
    When the user sends a GET request to /1.0/kb/catalog/xml
    Then the response status code should be 200 or 400 depending on validity
    And the response body should be valid XML or an error message as appropriate

    @TC17
    Scenario: Retrieval with very large catalog data
    Given the system contains a catalog with a very large number of products and plans
    When the user sends a GET request to /1.0/kb/catalog/xml
    Then the response status code should be 200
    And the response body should contain the entire catalog in valid XML format
    And the response time should be within acceptable limits (e.g., <2 seconds)

    @TC18
    Scenario: Concurrent requests for catalog XML
    Given multiple users send GET requests to /1.0/kb/catalog/xml simultaneously
    When the requests are processed
    Then each response status code should be 200
    And each response body should contain the correct catalog XML
    And no data corruption or race condition should occur

    @TC19
    Scenario: Regression - previously fixed issue with malformed XML
    Given a previous bug caused malformed XML in the response
    When the user sends a GET request to /1.0/kb/catalog/xml
    Then the response body should always be well-formed XML as per schema

    @TC20
    Scenario: Backward compatibility with older clients
    Given older clients expect the XML response format as per previous API versions
    When the user sends a GET request to /1.0/kb/catalog/xml
    Then the response should be compatible with the expected XML schema

    @TC21
    Scenario: Performance under peak load
    Given the system is under simulated peak load with many concurrent requests
    When users send GET requests to /1.0/kb/catalog/xml
    Then the average response time should remain within defined SLAs
    And the system should not return 5xx errors due to overload

    @TC22
    Scenario: Response to timeout condition
    Given the catalog retrieval operation exceeds the configured timeout
    When the user sends a GET request to /1.0/kb/catalog/xml
    Then the response status code should be 504
    And the response body should indicate a timeout occurred

    @TC23
    Scenario: Accessibility - screen reader compatibility (if UI displays XML)
    Given the XML is displayed in a browser-based UI
    When a screen reader is used
    Then the XML content should be accessible and properly announced

    @TC24
    Scenario: Accessibility - compliance with accessibility standards (if UI displays XML)
    Given the XML is displayed in a browser-based UI
    When the user navigates using keyboard and assistive technologies
    Then the page should comply with WCAG 2.1 AA standards