Feature: List children accounts via GET /1.0/kb/accounts/{accountId}/children
As a KillBill API user,
I want to retrieve the list of children accounts for a given parent account,
so that I can view and manage child account relationships and details.

  Background:
  Given the KillBill API server is running and reachable
  And the database is seeded with parent and child accounts with diverse data
  And valid authentication tokens are available
  And the API endpoint /1.0/kb/accounts/{accountId}/children is accessible

    @TC01
    Scenario: Successful retrieval of children accounts with default parameters
    Given a valid parent accountId with one or more children
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children with no query parameters
    Then the response status code should be 200
    And the response body should be a JSON array of Account objects representing all children accounts
    And each Account object should not contain balance or CBA fields
    And the audit information should be NONE

    @TC02
    Scenario: Successful retrieval with accountWithBalance=true
    Given a valid parent accountId with multiple children
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children?accountWithBalance=true
    Then the response status code should be 200
    And each Account object in the response should include the account balance field
    And CBA information should not be present
    And audit information should be NONE

    @TC03
    Scenario: Successful retrieval with accountWithBalanceAndCBA=true
    Given a valid parent accountId with multiple children
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children?accountWithBalanceAndCBA=true
    Then the response status code should be 200
    And each Account object in the response should include both balance and CBA fields
    And audit information should be NONE

    @TC04
    Scenario: Successful retrieval with audit=FULL
    Given a valid parent accountId with multiple children
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children?audit=FULL
    Then the response status code should be 200
    And each Account object in the response should include full audit information

    @TC05
    Scenario: Successful retrieval with audit=MINIMAL
    Given a valid parent accountId with multiple children
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children?audit=MINIMAL
    Then the response status code should be 200
    And each Account object in the response should include minimal audit information

    @TC06
    Scenario: Successful retrieval with all combinations of query parameters
    Given a valid parent accountId with multiple children
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children with combinations of:
      | accountWithBalance | accountWithBalanceAndCBA | audit   |
      | true              | false                    | FULL    |
      | false             | true                     | MINIMAL |
      | true              | true                     | NONE    |
      | false             | false                    | FULL    |
    Then the response status code should be 200
    And the response payload should match the expected fields and audit level for each combination

    @TC07
    Scenario: Retrieval when parent account has no children
    Given a valid parent accountId with no children accounts
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC08
    Scenario: Retrieval when no accounts exist in the system
    Given the system database is empty
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children with any accountId
    Then the response status code should be 404
    And the response body should contain an error message indicating parent account not found

    @TC09
    Scenario: Invalid parent accountId format
    Given an accountId that does not match the required UUID pattern
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children
    Then the response status code should be 400
    And the response body should contain an error message about invalid accountId

    @TC10
    Scenario: Parent accountId not found
    Given a valid UUID accountId that does not exist in the system
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children
    Then the response status code should be 404
    And the response body should contain an error message indicating parent account not found

    @TC11
    Scenario: Unauthorized access attempt
    Given a valid parent accountId
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children without authentication token
    Then the response status code should be 401
    And the response body should indicate authentication is required

    @TC12
    Scenario: Forbidden access with insufficient permissions
    Given a valid parent accountId
    And the user has a valid token but lacks required permissions
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children
    Then the response status code should be 403
    And the response body should indicate insufficient permissions

    @TC13
    Scenario: Extra unexpected query parameters
    Given a valid parent accountId
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children?unexpectedParam=foo
    Then the response status code should be 200
    And the response body should ignore the extra parameter and return the default response

    @TC14
    Scenario: System error - dependency unavailable
    Given a valid parent accountId
    And the account service dependency is down
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC15
    Scenario: Large data volume - parent with many children
    Given a valid parent accountId with 10,000 child accounts
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children
    Then the response status code should be 200
    And the response body should contain all 10,000 Account objects
    And the response time should be within acceptable performance thresholds (e.g., < 2 seconds)

    @TC16
    Scenario: Malformed query parameter values
    Given a valid parent accountId
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children?accountWithBalance=notABoolean
    Then the response status code should be 400
    And the response body should contain an error message about invalid parameter value

    @TC17
    Scenario: Attempted injection via accountId
    Given a malicious accountId value designed to inject code
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children
    Then the response status code should be 400
    And the response body should indicate invalid input
    And the system should not execute any injected code

    @TC18
    Scenario: Timeout condition
    Given a valid parent accountId
    And the backend is intentionally delayed
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children
    Then the response status code should be 504
    And the response body should indicate a timeout occurred

    @TC19
    Scenario: Regression - previously fixed bug for missing children when balance requested
    Given a valid parent accountId with children
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children?accountWithBalance=true
    Then the response status code should be 200
    And all children accounts should be returned with balance fields populated

    @TC20
    Scenario: Backward compatibility - legacy clients omitting new parameters
    Given a valid parent accountId
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children omitting all optional parameters
    Then the response status code should be 200
    And the response should be as per the default behavior

    @TC21
    Scenario: Concurrent access by multiple users
    Given multiple valid parent accountIds
    When multiple users concurrently send GET requests to /1.0/kb/accounts/{accountId}/children
    Then all responses should have status code 200
    And each response should return correct children accounts for each parent

    @TC22
    Scenario: Integration - audit information consistency with audit service
    Given a valid parent accountId
    And the audit service is available
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children?audit=FULL
    Then the audit information in each Account object should match the audit service records

    @TC23
    Scenario: Data consistency after child account creation
    Given a valid parent accountId
    And a new child account is created for this parent
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children
    Then the response should include the newly created child account

    @TC24
    Scenario: Empty response when all children are deleted
    Given a valid parent accountId with children
    And all child accounts are deleted
    When the user sends a GET request to /1.0/kb/accounts/{accountId}/children
    Then the response status code should be 200
    And the response body should be an empty JSON array

    @TC25
    Scenario: Partial input - missing accountId
    Given the endpoint is called without specifying accountId in the path
    When the user sends a GET request to /1.0/kb/accounts//children
    Then the response status code should be 404
    And the response body should indicate resource not found