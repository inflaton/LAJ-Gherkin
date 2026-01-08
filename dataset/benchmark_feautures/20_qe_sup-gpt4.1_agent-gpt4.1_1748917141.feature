Feature: Retrieve bundles for account via GET /1.0/kb/accounts/{accountId}/bundles
As a KillBill API user,
I want to retrieve bundles for a specific account,
so that I can view and manage bundles associated with that account.

  Background:
  Given the KillBill API service is running and reachable
  And the database contains accounts with various bundle configurations (including accounts with no bundles, one bundle, and multiple bundles)
  And valid and invalid account UUIDs are available for testing
  And valid authentication tokens are set in the request headers

    @TC01
    Scenario: Successful retrieval of bundles for a valid accountId with no query parameters
    Given an account exists with accountId = <valid_accountId> and has multiple bundles
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles
    Then the response status code should be 200
    And the response body should be a JSON array of Bundle objects
    And each Bundle object should contain all required fields as per the Bundle definition
    And the response should not include audit information by default

    @TC02
    Scenario: Successful retrieval with externalKey filter
    Given an account exists with accountId = <valid_accountId> and has bundles with various externalKeys
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles?externalKey=<existing_externalKey>
    Then the response status code should be 200
    And the response body should be a JSON array containing only bundles with externalKey = <existing_externalKey>

    @TC03
    Scenario: Successful retrieval with bundlesFilter parameter
    Given an account exists with accountId = <valid_accountId> and has bundles matching and not matching <bundlesFilter>
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles?bundlesFilter=<filter_value>
    Then the response status code should be 200
    And the response body should be a JSON array containing only bundles matching <filter_value>

    @TC04
    Scenario: Successful retrieval with audit parameter set to FULL
    Given an account exists with accountId = <valid_accountId> and has at least one bundle
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles?audit=FULL
    Then the response status code should be 200
    And each Bundle object in the response should include complete audit information

    @TC05
    Scenario: Successful retrieval with audit parameter set to MINIMAL
    Given an account exists with accountId = <valid_accountId> and has at least one bundle
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles?audit=MINIMAL
    Then the response status code should be 200
    And each Bundle object in the response should include minimal audit information

    @TC06
    Scenario: Successful retrieval with all query parameters combined
    Given an account exists with accountId = <valid_accountId> and has bundles with various externalKeys and matching <bundlesFilter>
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles?externalKey=<existing_externalKey>&bundlesFilter=<filter_value>&audit=FULL
    Then the response status code should be 200
    And the response body should be a JSON array containing only bundles with externalKey = <existing_externalKey> and matching <filter_value>
    And each Bundle object should include complete audit information

    @TC07
    Scenario: Retrieval for account with no bundles
    Given an account exists with accountId = <valid_accountId_no_bundles> and has no bundles
    When I perform GET /1.0/kb/accounts/<valid_accountId_no_bundles>/bundles
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC08
    Scenario: Retrieval for account with a single bundle
    Given an account exists with accountId = <valid_accountId_single_bundle> and has one bundle
    When I perform GET /1.0/kb/accounts/<valid_accountId_single_bundle>/bundles
    Then the response status code should be 200
    And the response body should be a JSON array with exactly one Bundle object

    @TC09
    Scenario: Retrieval with invalid accountId format
    Given an accountId = <malformed_accountId> that does not match the UUID pattern
    When I perform GET /1.0/kb/accounts/<malformed_accountId>/bundles
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId format

    @TC10
    Scenario: Retrieval for non-existent accountId
    Given an accountId = <nonexistent_accountId> that does not exist in the system
    When I perform GET /1.0/kb/accounts/<nonexistent_accountId>/bundles
    Then the response status code should be 404
    And the response body should contain an error message indicating account not found

    @TC11
    Scenario: Retrieval with unsupported audit parameter value
    Given an account exists with accountId = <valid_accountId>
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles?audit=INVALID
    Then the response status code should be 400
    And the response body should indicate an invalid value for the audit parameter

    @TC12
    Scenario: Retrieval with extra/unexpected query parameters
    Given an account exists with accountId = <valid_accountId>
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles?unexpectedParam=unexpected
    Then the response status code should be 200
    And the response body should be a JSON array of Bundle objects (ignoring the extra parameter)

    @TC13
    Scenario: Unauthorized access attempt
    Given an account exists with accountId = <valid_accountId>
    And the request is missing a valid authentication token
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC14
    Scenario: Service unavailable
    Given the KillBill API service is down or unreachable
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles
    Then the response status code should be 503
    And the response body should indicate service unavailability

    @TC15
    Scenario: Malicious input in query parameters (injection/XSS attempt)
    Given an account exists with accountId = <valid_accountId>
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles?externalKey=<malicious_payload>
    Then the response status code should be 400 or 422
    And the response body should indicate invalid input or reject the request

    @TC16
    Scenario: Large data volume (account with many bundles)
    Given an account exists with accountId = <valid_accountId_many_bundles> and has a large number of bundles (e.g., >1000)
    When I perform GET /1.0/kb/accounts/<valid_accountId_many_bundles>/bundles
    Then the response status code should be 200
    And the response body should be a JSON array containing all bundles
    And the response time should be within acceptable limits (e.g., <2 seconds)

    @TC17
    Scenario: Timeout due to long-running operation
    Given an account exists with accountId = <valid_accountId_slow> and the system is under heavy load
    When I perform GET /1.0/kb/accounts/<valid_accountId_slow>/bundles
    Then the response status code should be 504
    And the response body should indicate a timeout occurred

    @TC18
    Scenario: Concurrent requests for the same account
    Given an account exists with accountId = <valid_accountId> and has multiple bundles
    When multiple GET /1.0/kb/accounts/<valid_accountId>/bundles requests are performed concurrently
    Then all responses should have status code 200
    And the response bodies should be consistent and correct

    @TC19
    Scenario: Regression - previously fixed issue for bundles retrieval
    Given a regression test case for a previously fixed bug (e.g., bundles not returned when audit=FULL)
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles?audit=FULL
    Then the response status code should be 200
    And the response body should be correct as per the Bundle definition and include audit information

    @TC20
    Scenario: Backward compatibility with older clients
    Given an account exists with accountId = <valid_accountId>
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles without any query parameters from an older client version
    Then the response status code should be 200
    And the response body should be a JSON array of Bundle objects

    @TC21
    Scenario: Integration - dependent service unavailable
    Given an account exists with accountId = <valid_accountId>
    And the underlying bundle storage service is unavailable
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles
    Then the response status code should be 502
    And the response body should indicate a dependency failure

    @TC22
    Scenario: Data consistency check after bundle creation
    Given an account exists with accountId = <valid_accountId>
    And a new bundle is created for this account
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles
    Then the response should include the newly created bundle

    @TC23
    Scenario: Edge case - minimum and maximum allowed values for query parameters
    Given an account exists with accountId = <valid_accountId>
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles?externalKey=&bundlesFilter=
    Then the response status code should be 200
    And the response body should be a JSON array of Bundle objects (no filtering applied)

    @TC24
    Scenario: Edge case - partial input or unexpected input format
    Given an account exists with accountId = <valid_accountId>
    When I perform GET /1.0/kb/accounts/<valid_accountId>/bundles?externalKey=123@!#&bundlesFilter=abc$%^&audit=FULL
    Then the response status code should be 200 or 400 depending on input validation
    And the response body should be correct or indicate input error

    @TC25
    Scenario: Accessibility - API documentation and response compliance
    Given the API documentation is available
    When I review the API response and documentation
    Then the response structure should comply with OpenAPI/Swagger definition for Bundle
    And all fields should be accessible and correctly typed