Feature: Retrieve account invoices via GET /1.0/kb/accounts/{accountId}/invoices
As a KillBill API user,
I want to retrieve invoices for a specific account using the GET /1.0/kb/accounts/{accountId}/invoices endpoint,
so that I can view invoice data filtered by various parameters.

  Background:
  Given the KillBill API is running and accessible
  And the database contains accounts with various invoices (including paid, unpaid, migration, and voided invoices)
  And valid and invalid authentication tokens are available
  And the API endpoint /1.0/kb/accounts/{accountId}/invoices is reachable

    @TC01
    Scenario: Successful retrieval of all invoices for a valid account with no query parameters
    Given an account exists with accountId 'valid-account-uuid'
    And the account has multiple invoices (paid, unpaid, migration, voided)
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with no query parameters and a valid auth token
    Then the response status should be 200
    And the response body should be a JSON array of Invoice objects for the account
    And the response should include all invoice types except migration and voided invoices by default

    @TC02
    Scenario: Retrieve invoices with startDate and endDate filters
    Given an account exists with accountId 'valid-account-uuid'
    And the account has invoices created on various dates
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with startDate '2023-01-01' and endDate '2023-12-31' and a valid auth token
    Then the response status should be 200
    And the response body should include only invoices created between '2023-01-01' and '2023-12-31'

    @TC03
    Scenario: Retrieve invoices with withMigrationInvoices=true
    Given an account exists with migration invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with withMigrationInvoices=true
    Then the response status should be 200
    And the response should include migration invoices

    @TC04
    Scenario: Retrieve only unpaid invoices
    Given an account exists with both paid and unpaid invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with unpaidInvoicesOnly=true
    Then the response status should be 200
    And the response should include only unpaid invoices

    @TC05
    Scenario: Retrieve invoices including voided invoices
    Given an account exists with voided and non-voided invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with includeVoidedInvoices=true
    Then the response status should be 200
    And the response should include voided invoices

    @TC06
    Scenario: Retrieve invoices with audit parameter set to FULL
    Given an account exists with invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with audit=FULL
    Then the response status should be 200
    And the response should include audit information at the FULL level for each invoice

    @TC07
    Scenario: Retrieve invoices with all query parameters combined
    Given an account exists with a diverse set of invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with startDate, endDate, withMigrationInvoices=true, unpaidInvoicesOnly=true, includeVoidedInvoices=true, and audit=MINIMAL
    Then the response status should be 200
    And the response should include only invoices matching all provided filters and audit level MINIMAL

    @TC08
    Scenario: Retrieve invoices with no invoices present for the account
    Given an account exists with accountId 'empty-account-uuid' and no invoices
    When I send a GET request to /1.0/kb/accounts/empty-account-uuid/invoices
    Then the response status should be 200
    And the response body should be an empty JSON array

    @TC09
    Scenario: Retrieve invoices with extra, unsupported query parameters
    Given an account exists with invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with extra query parameter 'foo=bar'
    Then the response status should be 200
    And the response should ignore unsupported parameters and return valid invoices

    @TC10
    Scenario: Invalid accountId format (malformed UUID)
    Given I have an accountId 'invalid-uuid-format'
    When I send a GET request to /1.0/kb/accounts/invalid-uuid-format/invoices
    Then the response status should be 400
    And the response body should contain an error message indicating invalid account ID

    @TC11
    Scenario: Non-existent accountId
    Given I have an accountId 'non-existent-account-uuid' that does not exist in the system
    When I send a GET request to /1.0/kb/accounts/non-existent-account-uuid/invoices
    Then the response status should be 404
    And the response body should contain an error message indicating account not found

    @TC12
    Scenario: Missing authentication token
    Given an account exists with invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices without an authentication token
    Then the response status should be 401
    And the response body should indicate authentication is required

    @TC13
    Scenario: Invalid authentication token
    Given an account exists with invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with an invalid authentication token
    Then the response status should be 401
    And the response body should indicate authentication failure

    @TC14
    Scenario: Service unavailable
    Given the KillBill API service is down or unreachable
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices
    Then the response status should be 503
    And the response body should indicate service unavailable

    @TC15
    Scenario: Injection attack attempt in query parameter
    Given an account exists with invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with startDate="2023-01-01'; DROP TABLE invoices;--"
    Then the response status should be 400 or 422
    And the response body should indicate invalid input or reject the request

    @TC16
    Scenario: Large volume of invoices (performance and pagination)
    Given an account exists with over 10,000 invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices
    Then the response status should be 200
    And the response body should be a JSON array of Invoice objects (may be paginated)
    And the response time should be under 2 seconds

    @TC17
    Scenario: Slow downstream dependency
    Given a dependent service is responding slowly
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices
    Then the response status should be 200 or 504 depending on timeout configuration
    And the response time should not exceed the configured timeout

    @TC18
    Scenario: Concurrent requests for the same account
    Given an account exists with invoices
    When multiple clients send concurrent GET requests to /1.0/kb/accounts/valid-account-uuid/invoices
    Then all responses should be 200
    And the data returned should be consistent across requests

    @TC19
    Scenario: Regression - previously fixed issue with unpaidInvoicesOnly filter
    Given an account exists with both paid and unpaid invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with unpaidInvoicesOnly=true
    Then the response should include only unpaid invoices and exclude paid invoices
    And no regression of previously fixed bugs

    @TC20
    Scenario: Regression - backward compatibility with old clients (no query parameters)
    Given an account exists with invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices without any query parameters
    Then the response should be 200
    And the response body should be a JSON array of Invoice objects as per previous API version

    @TC21
    Scenario: Edge case - startDate after endDate
    Given an account exists with invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with startDate='2023-12-31' and endDate='2023-01-01'
    Then the response status should be 400
    And the response body should indicate invalid date range

    @TC22
    Scenario: Edge case - minimum and maximum allowed dates
    Given an account exists with invoices spanning several years
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with startDate='1970-01-01' and endDate='2100-12-31'
    Then the response status should be 200
    And the response should include all invoices within the allowed date range

    @TC23
    Scenario: Edge case - partial input (only startDate or only endDate)
    Given an account exists with invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with only startDate='2023-01-01'
    Then the response status should be 200
    And the response should include invoices created on or after '2023-01-01'
    When I send a GET request with only endDate='2023-12-31'
    Then the response status should be 200
    And the response should include invoices created on or before '2023-12-31'

    @TC24
    Scenario: Edge case - all boolean query parameters set to true
    Given an account exists with migration, unpaid, and voided invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with withMigrationInvoices=true, unpaidInvoicesOnly=true, includeVoidedInvoices=true
    Then the response status should be 200
    And the response should include only unpaid invoices, including migration and voided ones

    @TC25
    Scenario: Edge case - no invoices match the filters
    Given an account exists with invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with startDate='2099-01-01' and endDate='2099-12-31'
    Then the response status should be 200
    And the response body should be an empty JSON array

    @TC26
    Scenario: Edge case - extremely large accountId value
    Given I have an accountId with 10,000 characters
    When I send a GET request to /1.0/kb/accounts/{very-large-accountId}/invoices
    Then the response status should be 400
    And the response body should indicate invalid account ID

    @TC27
    Scenario: Security - XSS attempt in query parameter
    Given an account exists with invoices
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices with audit="<script>alert('xss')</script>"
    Then the response status should be 400 or 422
    And the response body should indicate invalid input or reject the request

    @TC28
    Scenario: Integration - downstream service returns inconsistent data
    Given a downstream service returns inconsistent invoice data
    When I send a GET request to /1.0/kb/accounts/valid-account-uuid/invoices
    Then the response status should be 200
    And the response should handle inconsistencies gracefully (e.g., log, mask, or sanitize)

    @TC29
    Scenario: Accessibility - API documentation is accessible and describes all parameters
    Given I am a user with accessibility needs
    When I access the API documentation for GET /1.0/kb/accounts/{accountId}/invoices
    Then the documentation should describe all path and query parameters, response codes, and error messages
    And the documentation should be navigable by screen readers