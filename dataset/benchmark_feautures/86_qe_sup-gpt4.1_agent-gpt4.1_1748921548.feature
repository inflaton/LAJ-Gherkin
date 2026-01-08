Feature: Retrieve tags for a specific invoice item via GET /1.0/kb/invoiceItems/{invoiceItemId}/tags
As a KillBill API user,
I want to retrieve tags for a specific invoice item,
so that I can view associated tags for auditing, reporting, or operational purposes.

  Background:
  Given the KillBill API is available at the configured baseUrl
  And the database is seeded with invoice items, accounts, and tags in various states (active, deleted)
  And valid and invalid UUIDs for invoice items and accounts are available
  And a valid authentication token is present in the request headers
  And the API client is configured to send and receive JSON

    @TC01
    Scenario: Successful retrieval of tags for an invoice item with minimal parameters
    Given an invoice item exists with ID <valid_invoiceItemId> and is associated with account <valid_accountId>
    And the invoice item has active tags
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<valid_accountId>
    Then the API responds with HTTP 200
    And the response body contains a JSON array of Tag objects for the invoice item
    And each Tag object conforms to the #/definitions/Tag schema

    @TC02
    Scenario: Successful retrieval of tags including deleted tags
    Given an invoice item exists with ID <valid_invoiceItemId> and is associated with account <valid_accountId>
    And the invoice item has both active and deleted tags
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameters accountId=<valid_accountId> and includedDeleted=true
    Then the API responds with HTTP 200
    And the response body contains all Tag objects, including those marked as deleted

    @TC03
    Scenario: Successful retrieval of tags with audit level FULL
    Given an invoice item exists with ID <valid_invoiceItemId> and is associated with account <valid_accountId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameters accountId=<valid_accountId> and audit=FULL
    Then the API responds with HTTP 200
    And each Tag object in the response contains full audit information

    @TC04
    Scenario: Successful retrieval of tags with audit level MINIMAL
    Given an invoice item exists with ID <valid_invoiceItemId> and is associated with account <valid_accountId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameters accountId=<valid_accountId> and audit=MINIMAL
    Then the API responds with HTTP 200
    And each Tag object in the response contains minimal audit information

    @TC05
    Scenario: Retrieval when no tags exist for the invoice item
    Given an invoice item exists with ID <valid_invoiceItemId> and is associated with account <valid_accountId>
    And the invoice item has no tags
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<valid_accountId>
    Then the API responds with HTTP 200
    And the response body is an empty JSON array

    @TC06
    Scenario: Retrieval with all optional parameters combined
    Given an invoice item exists with ID <valid_invoiceItemId> and is associated with account <valid_accountId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameters accountId=<valid_accountId>, includedDeleted=true, and audit=FULL
    Then the API responds with HTTP 200
    And the response body contains all Tag objects, including deleted, with full audit information

    @TC07
    Scenario: Error when invoiceItemId is invalid format
    Given an invalid invoice item ID <invalid_invoiceItemId> (not matching UUID pattern)
    And a valid account ID <valid_accountId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<invalid_invoiceItemId>/tags with query parameter accountId=<valid_accountId>
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid invoiceItemId format

    @TC08
    Scenario: Error when accountId is invalid format
    Given a valid invoice item ID <valid_invoiceItemId>
    And an invalid account ID <invalid_accountId> (not matching UUID pattern)
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<invalid_accountId>
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid accountId format

    @TC09
    Scenario: Error when invoice item does not exist
    Given a non-existent invoice item ID <nonexistent_invoiceItemId>
    And a valid account ID <valid_accountId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<nonexistent_invoiceItemId>/tags with query parameter accountId=<valid_accountId>
    Then the API responds with HTTP 404
    And the response body contains an error message indicating invoice item not found

    @TC10
    Scenario: Error when account does not exist
    Given a valid invoice item ID <valid_invoiceItemId>
    And a non-existent account ID <nonexistent_accountId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<nonexistent_accountId>
    Then the API responds with HTTP 404
    And the response body contains an error message indicating account not found

    @TC11
    Scenario: Error when required accountId parameter is missing
    Given a valid invoice item ID <valid_invoiceItemId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags without the accountId query parameter
    Then the API responds with HTTP 400
    And the response body contains an error message indicating missing required parameter accountId

    @TC12
    Scenario: Error when authentication token is missing or invalid
    Given a valid invoice item ID <valid_invoiceItemId> and account ID <valid_accountId>
    And the authentication token is missing or invalid
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<valid_accountId>
    Then the API responds with HTTP 401
    And the response body contains an error message indicating unauthorized access

    @TC13
    Scenario: Error when includedDeleted has invalid value
    Given a valid invoice item ID <valid_invoiceItemId> and account ID <valid_accountId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter includedDeleted=invalid
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid boolean value for includedDeleted

    @TC14
    Scenario: Error when audit has unsupported value
    Given a valid invoice item ID <valid_invoiceItemId> and account ID <valid_accountId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter audit=INVALID
    Then the API responds with HTTP 400
    And the response body contains an error message indicating unsupported audit value

    @TC15
    Scenario: Edge case with extra unexpected query parameters
    Given a valid invoice item ID <valid_invoiceItemId> and account ID <valid_accountId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameters accountId=<valid_accountId> and extraParam=unexpected
    Then the API responds with HTTP 200
    And the response body contains the expected tags, ignoring the extra parameter

    @TC16
    Scenario: Edge case with maximum allowed invoice item and account ID lengths
    Given invoiceItemId and accountId at maximum allowed UUID length
    When the user sends a GET request to /1.0/kb/invoiceItems/<max_length_invoiceItemId>/tags with query parameter accountId=<max_length_accountId>
    Then the API responds with HTTP 200
    And the response body contains the tags for the invoice item

    @TC17
    Scenario: Edge case with minimum allowed invoice item and account ID lengths
    Given invoiceItemId and accountId at minimum allowed UUID length
    When the user sends a GET request to /1.0/kb/invoiceItems/<min_length_invoiceItemId>/tags with query parameter accountId=<min_length_accountId>
    Then the API responds with HTTP 200
    And the response body contains the tags for the invoice item

    @TC18
    Scenario: System error when backend service is unavailable
    Given a valid invoice item ID <valid_invoiceItemId> and account ID <valid_accountId>
    And the backend tag service is unavailable
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<valid_accountId>
    Then the API responds with HTTP 503
    And the response body contains an error message indicating service unavailable

    @TC19
    Scenario: Security test with SQL injection in invoiceItemId
    Given a malicious invoice item ID <sql_injection_invoiceItemId>
    And a valid account ID <valid_accountId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<sql_injection_invoiceItemId>/tags with query parameter accountId=<valid_accountId>
    Then the API responds with HTTP 400 or 404
    And the response body does not leak sensitive information

    @TC20
    Scenario: Security test with XSS payload in accountId
    Given a valid invoice item ID <valid_invoiceItemId>
    And a malicious account ID <xss_payload_accountId>
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<xss_payload_accountId>
    Then the API responds with HTTP 400
    And the response body does not execute or reflect the payload

    @TC21
    Scenario: Performance test under normal load
    Given multiple concurrent requests for valid invoice item IDs and account IDs
    When the user sends GET requests to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<valid_accountId>
    Then the API responds with HTTP 200 within the expected response time threshold

    @TC22
    Scenario: Performance test under peak load
    Given a high volume of concurrent requests for valid invoice item IDs and account IDs
    When the user sends GET requests to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<valid_accountId>
    Then the API responds with HTTP 200 for all requests
    And response times remain within acceptable limits
    And no data loss or corruption occurs

    @TC23
    Scenario: Regression test for previously fixed bug with deleted tags visibility
    Given an invoice item with tags previously marked as deleted
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<valid_accountId> and includedDeleted=true
    Then the API responds with HTTP 200
    And deleted tags are included in the response as expected

    @TC24
    Scenario: Integration test with downstream audit logging service
    Given a valid invoice item ID <valid_invoiceItemId> and account ID <valid_accountId>
    And the audit logging service is operational
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<valid_accountId> and audit=FULL
    Then the API responds with HTTP 200
    And audit logs are generated and sent to the downstream service

    @TC25
    Scenario: Integration test with downstream audit logging service unavailable
    Given a valid invoice item ID <valid_invoiceItemId> and account ID <valid_accountId>
    And the audit logging service is unavailable
    When the user sends a GET request to /1.0/kb/invoiceItems/<valid_invoiceItemId>/tags with query parameter accountId=<valid_accountId> and audit=FULL
    Then the API responds with HTTP 200 or 503 depending on failover design
    And an appropriate error or warning is logged

    @TC26
    Scenario: State variation with empty database
    Given the database contains no invoice items, accounts, or tags
    When the user sends a GET request to /1.0/kb/invoiceItems/<any_invoiceItemId>/tags with query parameter accountId=<any_accountId>
    Then the API responds with HTTP 404
    And the response body contains an error message indicating not found

    @TC27
    Scenario: State variation with partially populated database
    Given the database contains some invoice items and accounts, but not the requested ones
    When the user sends a GET request to /1.0/kb/invoiceItems/<missing_invoiceItemId>/tags with query parameter accountId=<missing_accountId>
    Then the API responds with HTTP 404
    And the response body contains an error message indicating not found