Feature: Retrieve blocking states for account via GET /1.0/kb/accounts/{accountId}/block
As a KillBill API user,
I want to retrieve blocking states for a specific account,
so that I can view current blocking states and their details.

  Background:
  Given the KillBill API is running and accessible
  And the database contains accounts with various blocking states
  And valid authentication tokens are set in the request headers

    @TC01
    Scenario: Successful retrieval of all blocking states for an account with no filters
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    And the account has multiple blocking states of different types and services
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with no query parameters
    Then the response status code should be 200
    And the response body should be a JSON array of BlockingState objects for the account
    And each BlockingState object should contain all required fields as per schema

    @TC02
    Scenario: Successful retrieval with blockingStateTypes filter
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    And the account has blocking states of types SUBSCRIPTION, SUBSCRIPTION_BUNDLE, and ACCOUNT
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with query parameter blockingStateTypes=SUBSCRIPTION
    Then the response status code should be 200
    And the response body should only include BlockingState objects with type SUBSCRIPTION

    @TC03
    Scenario: Successful retrieval with blockingStateSvcs filter
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    And the account has blocking states from multiple services (e.g., 'entitlement', 'billing')
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with query parameter blockingStateSvcs=entitlement
    Then the response status code should be 200
    And the response body should only include BlockingState objects with service 'entitlement'

    @TC04
    Scenario: Successful retrieval with both blockingStateTypes and blockingStateSvcs filters
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    And the account has blocking states of type ACCOUNT and service 'billing'
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with query parameters blockingStateTypes=ACCOUNT and blockingStateSvcs=billing
    Then the response status code should be 200
    And the response body should only include BlockingState objects with type ACCOUNT and service 'billing'

    @TC05
    Scenario: Successful retrieval with audit parameter FULL
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with query parameter audit=FULL
    Then the response status code should be 200
    And each BlockingState object should include full audit information as per schema

    @TC06
    Scenario: Successful retrieval with audit parameter MINIMAL
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with query parameter audit=MINIMAL
    Then the response status code should be 200
    And each BlockingState object should include minimal audit information as per schema

    @TC07
    Scenario: Successful retrieval with audit parameter NONE (default)
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with no audit parameter
    Then the response status code should be 200
    And each BlockingState object should not include audit information

    @TC08
    Scenario: Retrieval for account with no blocking states
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456' and no blocking states
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC09
    Scenario: Retrieval for non-existent account
    Given no account exists with accountId 'nonexistent-uuid-0000-0000-0000-0000'
    When I send a GET request to /1.0/kb/accounts/nonexistent-uuid-0000-0000-0000-0000/block
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC10
    Scenario: Invalid accountId format
    Given an invalid accountId 'invalid-id'
    When I send a GET request to /1.0/kb/accounts/invalid-id/block
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId

    @TC11
    Scenario: Invalid value for blockingStateTypes
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with query parameter blockingStateTypes=INVALID_TYPE
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid blockingStateTypes value

    @TC12
    Scenario: Invalid value for audit parameter
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with query parameter audit=INVALID_AUDIT
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid audit value

    @TC13
    Scenario: Extra/unsupported query parameters
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with query parameter foo=bar
    Then the response status code should be 200
    And the response body should not be affected by the extra parameter

    @TC14
    Scenario: Unauthorized access with missing authentication token
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    And the request is sent without authentication headers
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block
    Then the response status code should be 401
    And the response body should contain an error message indicating authentication is required

    @TC15
    Scenario: Unauthorized access with invalid authentication token
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    And the request is sent with an invalid authentication token
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block
    Then the response status code should be 401
    And the response body should contain an error message indicating invalid authentication

    @TC16
    Scenario: Service unavailable or dependency failure
    Given the KillBill service or a required dependency is down
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailability

    @TC17
    Scenario: Large data volume retrieval
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    And the account has a large number of blocking states (e.g., 1000+)
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block
    Then the response status code should be 200
    And the response body should contain all blocking states without truncation
    And the response time should be within acceptable thresholds

    @TC18
    Scenario: Injection attack in query parameter
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with query parameter blockingStateSvcs="entitlement;DROP TABLE accounts;"
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid input
    And the system should not be compromised

    @TC19
    Scenario: Timeout due to long-running operation
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    And the system is under heavy load
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block
    Then the response should be received within the defined timeout threshold or return a 504 status code

    @TC20
    Scenario: Backward compatibility - legacy clients
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    And a legacy client sends a GET request without optional parameters
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block
    Then the response status code should be 200
    And the response body should be compatible with previous API versions

    @TC21
    Scenario: Regression - previously fixed bug for filtering by multiple types and services
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    And the account has blocking states of multiple types and services
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with blockingStateTypes=SUBSCRIPTION&blockingStateSvcs=entitlement&blockingStateSvcs=billing
    Then the response status code should be 200
    And the response body should include only blocking states matching the given types and services

    @TC22
    Scenario: Partial input - missing optional query parameters
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block with only one query parameter set
    Then the response status code should be 200
    And the response body should reflect the applied filter

    @TC23
    Scenario: State variation - empty database
    Given the database contains no accounts
    When I send a GET request to /1.0/kb/accounts/any-uuid-1111-2222-3333-4444/block
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC24
    Scenario: State variation - degraded system performance
    Given the system is experiencing degraded performance
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block
    Then the response status code should be 200 or 503 depending on severity
    And the response time should be logged and monitored

    @TC25
    Scenario: Integration - dependent service unavailable
    Given a dependent service for blocking states is unavailable
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block
    Then the response status code should be 503
    And the response body should contain an error message indicating dependency failure

    @TC26
    Scenario: Data consistency across integrated systems
    Given an account exists with accountId 'valid-uuid-1234-5678-9012-3456'
    And blocking states are updated in an integrated system
    When I send a GET request to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block
    Then the response body should reflect the most recent blocking state data

    @TC27
    Scenario: Resource utilization under concurrent requests
    Given multiple concurrent GET requests to /1.0/kb/accounts/valid-uuid-1234-5678-9012-3456/block
    When the requests are processed
    Then the system should handle concurrent requests without errors or resource exhaustion
    And all responses should be correct and timely