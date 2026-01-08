Feature: Remove custom fields from account via DELETE /1.0/kb/accounts/{accountId}/customFields
As a KillBill API user,
I want to remove custom fields from an account,
so that I can manage account metadata efficiently.

  Background:
  Given the KillBill API is available
  And the system contains accounts with various custom fields
  And valid authentication and authorization is configured
  And the database is seeded with accounts and custom fields covering all edge cases (e.g., no custom fields, multiple custom fields, maximum allowed custom fields)
  And mock services for external dependencies are set up if required

    @TC01
    Scenario: Successful removal of all custom fields from account (no customField query param)
    Given an account with multiple custom fields exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields without the customField query parameter
    Then the response status code should be 204
    And all custom fields for the account should be removed
    And the response body should be empty
    And a subsequent GET request to /1.0/kb/accounts/{accountId}/customFields should return an empty list

    @TC02
    Scenario: Successful removal of specific custom fields from account (customField query param provided)
    Given an account with three custom fields (A, B, C) exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields with customField=A&customField=B
    Then the response status code should be 204
    And only custom fields A and B should be removed from the account
    And custom field C should remain
    And a subsequent GET request to /1.0/kb/accounts/{accountId}/customFields should return only custom field C

    @TC03
    Scenario: Successful removal with optional headers (X-Killbill-Reason and X-Killbill-Comment)
    Given an account with at least one custom field exists
    And the X-Killbill-CreatedBy header is set to a valid user
    And the X-Killbill-Reason header is set to a valid string
    And the X-Killbill-Comment header is set to a valid string
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields with all optional headers
    Then the response status code should be 204
    And the custom fields should be removed as specified

    @TC04
    Scenario: Successful removal from account with no custom fields
    Given an account exists with no custom fields
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields
    Then the response status code should be 204
    And the response body should be empty
    And a subsequent GET request to /1.0/kb/accounts/{accountId}/customFields should return an empty list

    @TC05
    Scenario: Attempt to remove custom fields with invalid accountId format
    Given an accountId that does not match the uuid pattern
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId

    @TC06
    Scenario: Attempt to remove custom fields from non-existent account
    Given a valid uuid accountId that does not exist in the system
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields
    Then the response status code should be 204
    And the response body should be empty

    @TC07
    Scenario: Attempt to remove custom fields with missing X-Killbill-CreatedBy header
    Given an account with at least one custom field exists
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields without the X-Killbill-CreatedBy header
    Then the response status code should be 400
    And the response body should contain an error message indicating the missing required header

    @TC08
    Scenario: Attempt to remove custom fields with invalid customField UUIDs
    Given an account with at least one custom field exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields with customField=not-a-uuid
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid customField ID

    @TC09
    Scenario: Attempt to remove custom fields with extra unsupported query parameters
    Given an account with at least one custom field exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields with an extra query parameter foo=bar
    Then the response status code should be 204
    And the custom fields should be removed as specified by other valid parameters

    @TC10
    Scenario: Attempt to remove custom fields with unauthorized access
    Given an account with at least one custom field exists
    And the X-Killbill-CreatedBy header is set to a user without delete permissions
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields
    Then the response status code should be 401 or 403
    And the response body should contain an appropriate error message

    @TC11
    Scenario: System error during custom field removal (dependency failure)
    Given an account with at least one custom field exists
    And the X-Killbill-CreatedBy header is set to a valid user
    And the backend service for custom field deletion is unavailable
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields
    Then the response status code should be 500
    And the response body should contain an error message indicating system error

    @TC12
    Scenario: Attempt to remove custom fields with network timeout
    Given an account with at least one custom field exists
    And the X-Killbill-CreatedBy header is set to a valid user
    And the network is experiencing high latency
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields
    Then the request should timeout or return a 504 Gateway Timeout error
    And the operation should not partially complete

    @TC13
    Scenario: Attempt to remove custom fields with large number of customField IDs
    Given an account with the maximum allowed number of custom fields exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields with all customField IDs specified
    Then the response status code should be 204
    And all specified custom fields should be removed

    @TC14
    Scenario: Attempt to remove custom fields with duplicate customField IDs in query
    Given an account with custom fields A and B exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields with customField=A&customField=A&customField=B
    Then the response status code should be 204
    And custom fields A and B should be removed without error

    @TC15
    Scenario: Regression - Previously fixed issue: Removing a custom field that was already deleted
    Given an account with only custom field A exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields with customField=A
    And then sends the same DELETE request again for customField=A
    Then the response status code should be 204 for the second request
    And the response body should be empty

    @TC16
    Scenario: Performance - Remove all custom fields under peak load
    Given an account with many custom fields exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When 100 concurrent DELETE requests are sent to /1.0/kb/accounts/{accountId}/customFields
    Then all requests should complete with status code 204
    And the average response time should be within acceptable threshold (e.g., < 2 seconds)

    @TC17
    Scenario: Integration - Data consistency after deletion
    Given an account with custom fields exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When a DELETE request is sent to /1.0/kb/accounts/{accountId}/customFields
    Then the custom fields should be removed from the account
    And a GET request to any dependent service referencing the account's custom fields should reflect the deletion

    @TC18
    Scenario: State variation - Remove custom fields from partially populated account
    Given an account with some but not all possible custom fields exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields
    Then only the existing custom fields should be affected
    And the response status code should be 204

    @TC19
    Scenario: Security - Attempt SQL injection in accountId
    Given an account with at least one custom field exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/1%27%3BDELETE+FROM+accounts--/customFields
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid accountId

    @TC20
    Scenario: Security - Attempt XSS in customField parameter
    Given an account with at least one custom field exists
    And the X-Killbill-CreatedBy header is set to a valid user
    When the user sends a DELETE request to /1.0/kb/accounts/{accountId}/customFields with customField=<script>alert(1)</script>
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid customField ID