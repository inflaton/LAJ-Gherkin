Feature: Trigger invoice generation for all parked accounts via POST /1.0/kb/admin/invoices
As an administrator,
I want to trigger invoice generation for all parked accounts using the admin API,
so that I can ensure all parked accounts are properly invoiced with operational flexibility.

  Background:
  Given the KillBill system is running and accessible
  And the API endpoint POST /1.0/kb/admin/invoices is available
  And the database contains a diverse set of accounts, including parked and non-parked accounts
  And the administrator has a valid authentication token
  And the administrator knows the required headers (X-Killbill-CreatedBy)

    @TC01
    Scenario: Successful invoice generation for all parked accounts with default parameters
    Given there are parked accounts in the system
    And the administrator provides a valid X-Killbill-CreatedBy header
    When the administrator sends a POST request to /1.0/kb/admin/invoices with no query parameters
    Then the response code should be 200
    And the response should be application/json
    And invoices should be generated for all parked accounts up to the default limit (100)

    @TC02
    Scenario: Successful invoice generation with explicit offset and limit
    Given there are more than 100 parked accounts in the system
    And the administrator provides a valid X-Killbill-CreatedBy header
    When the administrator sends a POST request to /1.0/kb/admin/invoices with offset=50 and limit=25
    Then the response code should be 200
    And the response should be application/json
    And invoices should be generated for 25 parked accounts starting from the 51st parked account

    @TC03
    Scenario: Successful invoice generation with all optional headers provided
    Given there are parked accounts in the system
    And the administrator provides X-Killbill-CreatedBy, X-Killbill-Reason, and X-Killbill-Comment headers
    When the administrator sends a POST request to /1.0/kb/admin/invoices
    Then the response code should be 200
    And the response should be application/json
    And the operation should be auditable with the provided reason and comment

    @TC04
    Scenario: Successful invoice generation when no parked accounts exist
    Given there are no parked accounts in the system
    And the administrator provides a valid X-Killbill-CreatedBy header
    When the administrator sends a POST request to /1.0/kb/admin/invoices
    Then the response code should be 200
    And the response should be application/json
    And the response should indicate no invoices were generated

    @TC05
    Scenario: Error when missing required X-Killbill-CreatedBy header
    Given there are parked accounts in the system
    And the administrator omits the X-Killbill-CreatedBy header
    When the administrator sends a POST request to /1.0/kb/admin/invoices
    Then the response code should be 400 or 401
    And the response should contain an error message indicating the missing required header

    @TC06
    Scenario: Error with invalid offset or limit values
    Given there are parked accounts in the system
    And the administrator provides a valid X-Killbill-CreatedBy header
    When the administrator sends a POST request with offset=-1 or limit=0 or limit=-10
    Then the response code should be 400
    And the response should contain an error message indicating invalid parameter values

    @TC07
    Scenario: Error with non-integer offset or limit
    Given there are parked accounts in the system
    And the administrator provides a valid X-Killbill-CreatedBy header
    When the administrator sends a POST request with offset=abc or limit=xyz
    Then the response code should be 400
    And the response should contain an error message about parameter type

    @TC08
    Scenario: Error when unauthorized user attempts the operation
    Given there are parked accounts in the system
    And the administrator provides an invalid or expired authentication token
    When the administrator sends a POST request to /1.0/kb/admin/invoices
    Then the response code should be 401 or 403
    And the response should contain an error message about authorization

    @TC09
    Scenario: Error when server or dependency is unavailable
    Given there are parked accounts in the system
    And the KillBill backend or a required service is down
    When the administrator sends a POST request to /1.0/kb/admin/invoices
    Then the response code should be 503
    And the response should contain an error message indicating service unavailability

    @TC10
    Scenario: Edge case with maximum allowed limit value
    Given there are more than 1000 parked accounts in the system
    And the administrator provides a valid X-Killbill-CreatedBy header
    When the administrator sends a POST request with limit set to the maximum allowed (e.g., 1000)
    Then the response code should be 200
    And the response should be application/json
    And invoices should be generated for up to 1000 parked accounts

    @TC11
    Scenario: Edge case with extra unexpected query parameters
    Given there are parked accounts in the system
    And the administrator provides a valid X-Killbill-CreatedBy header
    When the administrator sends a POST request with an extra query parameter foo=bar
    Then the response code should be 200 or 400
    And the response should either ignore the extra parameter or return an error about unsupported parameter

    @TC12
    Scenario: Edge case with extremely large data volume
    Given there are over 10,000 parked accounts in the system
    And the administrator provides a valid X-Killbill-CreatedBy header
    When the administrator sends a POST request to /1.0/kb/admin/invoices with limit=10000
    Then the response code should be 200
    And the response should be application/json
    And invoices should be generated for up to 10,000 parked accounts
    And response time should be within acceptable operational thresholds

    @TC13
    Scenario: Edge case with partial input (only offset provided)
    Given there are parked accounts in the system
    And the administrator provides a valid X-Killbill-CreatedBy header
    When the administrator sends a POST request with offset=20 and no limit
    Then the response code should be 200
    And the response should be application/json
    And invoices should be generated for parked accounts starting from the 21st, up to the default limit (100)

    @TC14
    Scenario: Security test - injection attempt in headers
    Given there are parked accounts in the system
    And the administrator provides X-Killbill-CreatedBy with a malicious payload (e.g., SQL injection attempt)
    When the administrator sends a POST request to /1.0/kb/admin/invoices
    Then the response code should be 400 or 403
    And the response should not reveal stack traces or sensitive information

    @TC15
    Scenario: Recovery from transient network failure
    Given there are parked accounts in the system
    And a transient network failure occurs during the request
    When the administrator retries the POST request after failure
    Then the response code should be 200 if the retry is successful
    And invoices should not be generated multiple times for the same accounts

    @TC16
    Scenario: Regression - previously fixed bug with header parsing
    Given there are parked accounts in the system
    And the administrator provides all required and optional headers
    When the administrator sends a POST request to /1.0/kb/admin/invoices
    Then the response code should be 200
    And the response should be application/json
    And header values should be properly parsed and recorded

    @TC17
    Scenario: Regression - backward compatibility with older clients
    Given there are parked accounts in the system
    And the administrator uses an older client version that does not send optional headers
    When the administrator sends a POST request to /1.0/kb/admin/invoices
    Then the response code should be 200
    And the response should be application/json

    @TC18
    Scenario: Performance under concurrent requests
    Given there are a large number of parked accounts in the system
    And multiple administrators send concurrent POST requests to /1.0/kb/admin/invoices
    When the system processes these requests
    Then all responses should be 200
    And invoices should be generated exactly once per parked account
    And system resource utilization should remain within acceptable limits

    @TC19
    Scenario: Accessibility - API documentation is accessible
    Given the administrator accesses the API documentation for POST /1.0/kb/admin/invoices
    When using a screen reader or accessibility tool
    Then all required fields and usage notes should be clearly described
    And documentation should be navigable and compliant with accessibility standards