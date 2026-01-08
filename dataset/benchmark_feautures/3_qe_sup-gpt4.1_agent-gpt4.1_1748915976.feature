Feature: Remove tags from account via DELETE /1.0/kb/accounts/{accountId}/tags
As a KillBill API user,
I want to remove tags from an account using the DELETE /1.0/kb/accounts/{accountId}/tags API,
so that I can manage account tags efficiently and ensure correct tag states.

  Background:
  Given the KillBill API server is running and accessible
  And the database contains accounts with various tag states (no tags, one tag, multiple tags)
  And valid and invalid account UUIDs are available for testing
  And valid and invalid tag definition UUIDs are available for testing
  And the API client is authenticated and authorized
  And all requests include the required header X-Killbill-CreatedBy

    @TC01
    Scenario: Successful removal of a single tag from an account
    Given an account exists with at least one tag applied
    And a valid accountId is provided in the path
    And a valid tagDef UUID is provided as a query parameter
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags with the tagDef parameter
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 204
    And the tag is removed from the account in the database
    And the response body is empty

    @TC02
    Scenario: Successful removal of multiple tags from an account
    Given an account exists with multiple tags applied
    And a valid accountId is provided in the path
    And multiple valid tagDef UUIDs are provided as query parameters
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags with all tagDef parameters
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 204
    And all specified tags are removed from the account
    And the response body is empty

    @TC03
    Scenario: Successful removal of all tags when no tagDef is provided
    Given an account exists with multiple tags applied
    And a valid accountId is provided in the path
    And no tagDef query parameter is provided
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 204
    And all tags are removed from the account
    And the response body is empty

    @TC04
    Scenario: Successful removal with additional headers (reason and comment)
    Given an account exists with at least one tag applied
    And a valid accountId is provided in the path
    And a valid tagDef UUID is provided as a query parameter
    And X-Killbill-Reason and X-Killbill-Comment headers are provided
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags with the headers
    Then the API responds with status code 204
    And the tag is removed from the account
    And the response body is empty

    @TC05
    Scenario: Attempt to remove a tag from an account with no tags
    Given an account exists with no tags applied
    And a valid accountId is provided in the path
    And a valid tagDef UUID is provided as a query parameter
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 204
    And the response body is empty
    And the account remains with no tags

    @TC06
    Scenario: Attempt to remove a tag from a non-existent account
    Given a non-existent accountId is provided in the path
    And a valid tagDef UUID is provided as a query parameter
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 400
    And the response body contains an error message indicating invalid account ID

    @TC07
    Scenario: Attempt to remove a tag with an invalid accountId format
    Given an invalid accountId is provided in the path (not a UUID)
    And a valid tagDef UUID is provided as a query parameter
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 400
    And the response body contains an error message indicating invalid account ID

    @TC08
    Scenario: Attempt to remove a tag with an invalid tagDef UUID
    Given an account exists with at least one tag applied
    And a valid accountId is provided in the path
    And an invalid tagDef UUID is provided as a query parameter
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 400
    And the response body contains an error message indicating invalid tagDef

    @TC09
    Scenario: Attempt to remove a tag without providing X-Killbill-CreatedBy header
    Given an account exists with at least one tag applied
    And a valid accountId is provided in the path
    And a valid tagDef UUID is provided as a query parameter
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags without X-Killbill-CreatedBy header
    Then the API responds with status code 400
    And the response body contains an error message indicating missing required header

    @TC10
    Scenario: Attempt to remove AUTO_PAY_OFF tag from account without default payment method
    Given an account exists with the AUTO_PAY_OFF tag applied
    And the account does not have a default payment method
    And a valid accountId is provided in the path
    And the tagDef UUID for AUTO_PAY_OFF is provided as a query parameter
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 400
    And the response body contains an error message indicating the account does not have a default payment method

    @TC11
    Scenario: Attempt to remove tags with extra/unexpected query parameters
    Given an account exists with at least one tag applied
    And a valid accountId is provided in the path
    And a valid tagDef UUID is provided as a query parameter
    And additional unexpected query parameters are included
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 204
    And the tag is removed from the account
    And the response body is empty

    @TC12
    Scenario: Attempt to remove tags while the KillBill service is unavailable
    Given the KillBill API service is down
    And a valid accountId is provided in the path
    And a valid tagDef UUID is provided as a query parameter
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with an appropriate 5xx error code
    And the response body contains an error message indicating service unavailability

    @TC13
    Scenario: Attempt to remove tags with a very large number of tagDef UUIDs
    Given an account exists with many tags applied
    And a valid accountId is provided in the path
    And a large number of valid tagDef UUIDs are provided as query parameters
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 204
    And all specified tags are removed from the account
    And the response body is empty

    @TC14
    Scenario: Attempt to remove tags with malformed tagDef UUIDs
    Given an account exists with at least one tag applied
    And a valid accountId is provided in the path
    And a malformed tagDef value is provided as a query parameter (not a UUID)
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 400
    And the response body contains an error message indicating invalid tagDef

    @TC15
    Scenario: Attempt to remove tags with unauthorized access
    Given an account exists with at least one tag applied
    And a valid accountId is provided in the path
    And a valid tagDef UUID is provided as a query parameter
    And the API client is not authenticated or uses an invalid token
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    Then the API responds with status code 401 or 403
    And the response body contains an error message indicating unauthorized access

    @TC16
    Scenario: Recovery from transient network failure during tag removal
    Given an account exists with at least one tag applied
    And a valid accountId is provided in the path
    And a valid tagDef UUID is provided as a query parameter
    And the network connection is temporarily interrupted during the request
    When the user retries the DELETE request after the network is restored
    Then the API responds with status code 204
    And the tag is removed from the account
    And the response body is empty

    @TC17
    Scenario: Performance under concurrent DELETE requests
    Given multiple accounts each with multiple tags applied
    And valid accountIds and tagDef UUIDs are available
    When multiple users send concurrent DELETE requests to /1.0/kb/accounts/{accountId}/tags
    And all requests include the X-Killbill-CreatedBy header
    Then all requests respond with status code 204 within acceptable response time
    And all specified tags are removed from the respective accounts

    @TC18
    Scenario: Regression - previously fixed bug for tag removal with mixed valid and invalid tagDef UUIDs
    Given an account exists with multiple tags applied
    And a valid accountId is provided in the path
    And both valid and invalid tagDef UUIDs are provided as query parameters
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 400
    And the response body contains an error message indicating invalid tagDef

    @TC19
    Scenario: Regression - backward compatibility with clients omitting optional headers
    Given an account exists with at least one tag applied
    And a valid accountId is provided in the path
    And a valid tagDef UUID is provided as a query parameter
    And X-Killbill-Reason and X-Killbill-Comment headers are omitted
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 204
    And the tag is removed from the account
    And the response body is empty

    @TC20
    Scenario: Edge case - Attempt to remove tags with empty tagDef array
    Given an account exists with at least one tag applied
    And a valid accountId is provided in the path
    And the tagDef query parameter is provided as an empty array
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/tags
    And the X-Killbill-CreatedBy header is set to a valid user
    Then the API responds with status code 204
    And all tags are removed from the account
    And the response body is empty