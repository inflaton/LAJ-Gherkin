Feature: Search Custom Fields API (GET /1.0/kb/customFields/search/{searchKey})
As a KillBill API user,
I want to search for custom fields using a general search key with pagination and audit controls,
so that I can efficiently locate and review custom field data.

  Background:
  Given the KillBill API is running and accessible
  And a valid authentication token is present in the request headers
  And the database contains a diverse set of CustomField records with varying values
  And the API endpoint /1.0/kb/customFields/search/{searchKey} is available

    @TC01
    Scenario: Successful search with only required path parameter (happy path)
    Given the database contains CustomField records with various field names and values
    When the user performs GET /1.0/kb/customFields/search/"email"
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects matching the search key "email"
    And the response array may be empty if no matches are found

    @TC02
    Scenario: Successful search with pagination parameters (limit and offset)
    Given the database contains more than 100 CustomField records matching the search key "user"
    When the user performs GET /1.0/kb/customFields/search/"user"?limit=50&offset=0
    Then the response status code should be 200
    And the response body should be a JSON array of up to 50 CustomField objects matching the search key "user"
    And the response should include the first 50 matching records
    When the user performs GET /1.0/kb/customFields/search/"user"?limit=50&offset=50
    Then the response status code should be 200
    And the response body should be a JSON array of the next 50 CustomField objects matching the search key "user"

    @TC03
    Scenario: Successful search with audit parameter set to FULL
    Given the database contains CustomField records matching the search key "account"
    When the user performs GET /1.0/kb/customFields/search/"account"?audit=FULL
    Then the response status code should be 200
    And each CustomField object in the response should include full audit information

    @TC04
    Scenario: Successful search with audit parameter set to MINIMAL
    Given the database contains CustomField records matching the search key "plan"
    When the user performs GET /1.0/kb/customFields/search/"plan"?audit=MINIMAL
    Then the response status code should be 200
    And each CustomField object in the response should include minimal audit information

    @TC05
    Scenario: Successful search with audit parameter set to NONE (explicit)
    Given the database contains CustomField records matching the search key "subscription"
    When the user performs GET /1.0/kb/customFields/search/"subscription"?audit=NONE
    Then the response status code should be 200
    And each CustomField object in the response should not include audit information

    @TC06
    Scenario: Search returns no matching records (empty response)
    Given the database contains no CustomField records matching the search key "nonexistentkey"
    When the user performs GET /1.0/kb/customFields/search/"nonexistentkey"
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC07
    Scenario: Search with maximum allowed limit parameter
    Given the database contains many CustomField records matching the search key "maxlimit"
    When the user performs GET /1.0/kb/customFields/search/"maxlimit"?limit=1000
    Then the response status code should be 200
    And the response body should be a JSON array of up to 1000 CustomField objects

    @TC08
    Scenario: Search with minimum allowed limit parameter (limit=1)
    Given the database contains CustomField records matching the search key "minlimit"
    When the user performs GET /1.0/kb/customFields/search/"minlimit"?limit=1
    Then the response status code should be 200
    And the response body should be a JSON array with at most 1 CustomField object

    @TC09
    Scenario: Search with offset beyond available records
    Given the database contains 10 CustomField records matching the search key "offsettest"
    When the user performs GET /1.0/kb/customFields/search/"offsettest"?offset=100
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC10
    Scenario: Search with extra unsupported query parameters
    Given the database contains CustomField records matching the search key "extra"
    When the user performs GET /1.0/kb/customFields/search/"extra"?foo=bar
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects matching the search key "extra"
    And unsupported parameters should be ignored

    @TC11
    Scenario: Search with malformed limit parameter (non-integer)
    Given the user provides limit="abc" as a query parameter
    When the user performs GET /1.0/kb/customFields/search/"malformed"?limit=abc
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid parameter format

    @TC12
    Scenario: Search with negative limit parameter
    Given the user provides limit=-1 as a query parameter
    When the user performs GET /1.0/kb/customFields/search/"negativelimit"?limit=-1
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid parameter value

    @TC13
    Scenario: Search with negative offset parameter
    Given the user provides offset=-5 as a query parameter
    When the user performs GET /1.0/kb/customFields/search/"negativeoffset"?offset=-5
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid parameter value

    @TC14
    Scenario: Search with invalid audit parameter value
    Given the user provides audit="INVALID" as a query parameter
    When the user performs GET /1.0/kb/customFields/search/"invalidaudit"?audit=INVALID
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid audit value

    @TC15
    Scenario: Search with missing authentication token
    Given the user omits the authentication token in the request headers
    When the user performs GET /1.0/kb/customFields/search/"authfail"
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication failure

    @TC16
    Scenario: Search with invalid authentication token
    Given the user provides an invalid authentication token in the request headers
    When the user performs GET /1.0/kb/customFields/search/"authfail"
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication failure

    @TC17
    Scenario: Search when backend service is unavailable
    Given the backend service is down or unreachable
    When the user performs GET /1.0/kb/customFields/search/"servicefail"
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailability

    @TC18
    Scenario: Search with special characters in searchKey (XSS/injection attempt)
    Given the user provides a searchKey containing special characters "<script>alert(1)</script>"
    When the user performs GET /1.0/kb/customFields/search/"<script>alert(1)</script>"
    Then the response status code should be 200 or 400 depending on input validation
    And the response body should not execute or reflect unescaped input
    And the system should not be vulnerable to XSS or injection

    @TC19
    Scenario: Search with large payload (stress test)
    Given the database contains a very large number of CustomField records matching the search key "stress"
    When the user performs GET /1.0/kb/customFields/search/"stress"?limit=1000
    Then the response status code should be 200
    And the response time should be within acceptable thresholds (e.g., <2s)
    And the response body should be a JSON array of up to 1000 CustomField objects

    @TC20
    Scenario: Concurrent search requests (performance and concurrency)
    Given the database contains CustomField records matching the search key "concurrent"
    When multiple users perform GET /1.0/kb/customFields/search/"concurrent" simultaneously
    Then all responses should have status code 200
    And each response should return the correct subset of CustomField objects
    And the system should not experience race conditions or data inconsistency

    @TC21
    Scenario: Regression - previously fixed bug with empty searchKey
    Given the user provides an empty string as searchKey
    When the user performs GET /1.0/kb/customFields/search/""
    Then the response status code should be 200 or 400 depending on business rules
    And the response should be consistent with current API definition

    @TC22
    Scenario: Backward compatibility - legacy clients using only path parameter
    Given a legacy client performs GET /1.0/kb/customFields/search/"legacy"
    When the request is made without any query parameters
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects matching the search key "legacy"

    @TC23
    Scenario: Integration - data consistency with dependent services
    Given the system is integrated with external services that may update CustomField data
    When the user performs GET /1.0/kb/customFields/search/"integration"
    Then the response should reflect the most recent data from all integrated sources

    @TC24
    Scenario: Accessibility - API documentation and error messages
    Given the user accesses API documentation for /1.0/kb/customFields/search/{searchKey}
    When the user reviews error responses
    Then all error messages should be descriptive, accessible, and follow API guidelines

    @TC25
    Scenario: Search with partial input or unexpected input format
    Given the user provides a searchKey with only whitespace or unusual characters
    When the user performs GET /1.0/kb/customFields/search/"   "
    Then the response status code should be 200 or 400 depending on input validation
    And the response should not cause system errors or crashes

    @TC26
    Scenario: Search with very long searchKey value (boundary test)
    Given the user provides a searchKey of maximum allowed length (e.g., 255 characters)
    When the user performs GET /1.0/kb/customFields/search/{very_long_key}
    Then the response status code should be 200 or 400 depending on input validation
    And the system should handle the request gracefully without crashing

    @TC27
    Scenario: Search with Unicode and non-ASCII characters in searchKey
    Given the user provides a searchKey containing Unicode characters (e.g., "测试🔍")
    When the user performs GET /1.0/kb/customFields/search/"测试🔍"
    Then the response status code should be 200
    And the response body should be a JSON array of CustomField objects matching the Unicode search key

    @TC28
    Scenario: Search with audit parameter in combination with pagination
    Given the database contains CustomField records matching the search key "auditpage"
    When the user performs GET /1.0/kb/customFields/search/"auditpage"?limit=10&offset=5&audit=FULL
    Then the response status code should be 200
    And the response body should be a JSON array of up to 10 CustomField objects with full audit information, starting from the 6th record

    @TC29
    Scenario: Search with all query parameters set to default values
    Given the database contains CustomField records matching the search key "defaults"
    When the user performs GET /1.0/kb/customFields/search/"defaults"?limit=100&offset=0&audit=NONE
    Then the response status code should be 200
    And the response body should be a JSON array of up to 100 CustomField objects without audit information

    @TC30
    Scenario: Search with unsupported HTTP method
    Given the user attempts to perform POST /1.0/kb/customFields/search/"wrongmethod"
    When the request is made
    Then the response status code should be 405
    And the response body should indicate that the method is not allowed