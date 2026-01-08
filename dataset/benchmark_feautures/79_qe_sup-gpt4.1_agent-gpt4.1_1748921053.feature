Feature: Retrieve a credit by ID via GET /1.0/kb/credits/{creditId}
As a KillBill API user,
I want to retrieve a credit by its unique ID,
so that I can view the details of a specific credit (InvoiceItem of type CREDIT_ADJ or CBA_ADJ).

  Background:
  Given the KillBill API is running and accessible
  And the database is seeded with InvoiceItem data including at least one CREDIT_ADJ and one CBA_ADJ
  And I have a valid authentication token
  And the API endpoint /1.0/kb/credits/{creditId} is available

    @TC01
    Scenario: Successful retrieval of a CREDIT_ADJ credit by valid creditId
    Given a valid creditId corresponding to an InvoiceItem of type CREDIT_ADJ exists in the system
    When I send a GET request to /1.0/kb/credits/{creditId} with this creditId
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a valid InvoiceItem JSON object
    And the InvoiceItem type should be CREDIT_ADJ
    And the creditId in the response should match the requested creditId

    @TC02
    Scenario: Successful retrieval of a CBA_ADJ credit by valid creditId
    Given a valid creditId corresponding to an InvoiceItem of type CBA_ADJ exists in the system
    When I send a GET request to /1.0/kb/credits/{creditId} with this creditId
    Then the response status code should be 200
    And the response Content-Type should be application/json
    And the response body should be a valid InvoiceItem JSON object
    And the InvoiceItem type should be CBA_ADJ
    And the creditId in the response should match the requested creditId

    @TC03
    Scenario: Retrieval when no InvoiceItem of type CREDIT_ADJ or CBA_ADJ exists
    Given the database contains no InvoiceItem of type CREDIT_ADJ or CBA_ADJ
    When I send a GET request to /1.0/kb/credits/{creditId} with any creditId
    Then the response status code should be 404
    And the response body should contain an error message indicating credit not found

    @TC04
    Scenario: Retrieval with a non-existent creditId
    Given a creditId that does not exist in the system
    When I send a GET request to /1.0/kb/credits/{creditId} with this creditId
    Then the response status code should be 404
    And the response body should contain an error message indicating credit not found

    @TC05
    Scenario: Retrieval with an invalid creditId format (not a UUID)
    Given an invalid creditId value 'invalid-uuid-format'
    When I send a GET request to /1.0/kb/credits/{creditId} with this value
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid creditId

    @TC06
    Scenario: Retrieval with a missing authentication token
    Given a valid creditId exists in the system
    When I send a GET request to /1.0/kb/credits/{creditId} without an authentication token
    Then the response status code should be 401
    And the response body should contain an authentication error message

    @TC07
    Scenario: Retrieval with an expired or invalid authentication token
    Given a valid creditId exists in the system
    When I send a GET request to /1.0/kb/credits/{creditId} with an expired or invalid authentication token
    Then the response status code should be 401
    And the response body should contain an authentication error message

    @TC08
    Scenario: Retrieval with extra unexpected query parameters
    Given a valid creditId exists in the system
    When I send a GET request to /1.0/kb/credits/{creditId}?extra=unexpected
    Then the response status code should be 200
    And the response body should be a valid InvoiceItem JSON object
    And the extra parameter should be ignored

    @TC09
    Scenario: Retrieval when the system is under degraded performance
    Given a valid creditId exists in the system
    And the system is experiencing high load
    When I send a GET request to /1.0/kb/credits/{creditId}
    Then the response status code should be 200
    And the response should be returned within the acceptable response time threshold (e.g., <2s)

    @TC10
    Scenario: Retrieval when the dependent database is unavailable
    Given the database service is down
    When I send a GET request to /1.0/kb/credits/{creditId} with any creditId
    Then the response status code should be 503
    And the response body should contain a service unavailable error message

    @TC11
    Scenario: Retrieval with a valid creditId that is not of type CREDIT_ADJ or CBA_ADJ
    Given a valid creditId exists in the system but is not of type CREDIT_ADJ or CBA_ADJ
    When I send a GET request to /1.0/kb/credits/{creditId} with this creditId
    Then the response status code should be 404
    And the response body should contain an error message indicating credit not found

    @TC12
    Scenario: Security test - SQL injection attempt in creditId
    Given a malicious creditId value '1234-5678-9012-3456-7890;DROP TABLE InvoiceItem;'
    When I send a GET request to /1.0/kb/credits/{creditId} with this value
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid creditId
    And the system should not be compromised

    @TC13
    Scenario: Security test - XSS attempt in creditId
    Given a malicious creditId value '<script>alert(1)</script>'
    When I send a GET request to /1.0/kb/credits/{creditId} with this value
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid creditId
    And the system should not execute any script

    @TC14
    Scenario: Retrieval with a very large UUID as creditId (boundary test)
    Given a syntactically valid but unusually large UUID value as creditId
    When I send a GET request to /1.0/kb/credits/{creditId} with this value
    Then the response status code should be 404
    And the response body should contain an error message indicating credit not found

    @TC15
    Scenario: Regression - Retrieval of creditId previously known to cause issues
    Given a creditId that previously caused a bug exists in the system
    When I send a GET request to /1.0/kb/credits/{creditId} with this creditId
    Then the response status code should be 200
    And the response body should be a valid InvoiceItem JSON object
    And the InvoiceItem type should be CREDIT_ADJ or CBA_ADJ

    @TC16
    Scenario: Retrieval with partial creditId (truncated UUID)
    Given a creditId that is a truncated version of a valid UUID
    When I send a GET request to /1.0/kb/credits/{creditId} with this value
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid creditId

    @TC17
    Scenario: Retrieval with whitespace-padded creditId
    Given a valid creditId exists in the system with leading and trailing whitespace in the request
    When I send a GET request to /1.0/kb/credits/{creditId} with this value
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid creditId

    @TC18
    Scenario: Retrieval when system is empty (no credits at all)
    Given the database is empty
    When I send a GET request to /1.0/kb/credits/{creditId} with any creditId
    Then the response status code should be 404
    And the response body should contain an error message indicating credit not found

    @TC19
    Scenario: Performance - Multiple concurrent retrieval requests
    Given multiple valid creditIds exist in the system
    When I send 100 concurrent GET requests to /1.0/kb/credits/{creditId} for these creditIds
    Then all responses should have status code 200
    And all responses should be returned within the acceptable response time threshold (e.g., <2s)

    @TC20
    Scenario: API backward compatibility
    Given a valid creditId exists in the system
    And a client using a previous version of the API (if supported) sends a GET request
    When I send a GET request to /1.0/kb/credits/{creditId} with this creditId
    Then the response status code should be 200
    And the response body should be a valid InvoiceItem JSON object
    And the structure should remain backward compatible