Feature: Block an account via POST /1.0/kb/accounts/{accountId}/block
As a KillBill API user,
I want to add a blocking state to an account or its components,
so that I can control access or suspend activity as needed.

  Background:
  Given the KillBill API is available
  And the database contains accounts with diverse states (active, inactive, partially blocked)
  And valid authentication and authorization tokens are present
  And the BlockingState schema is known and accessible
  And all required headers and content types are configured

    @TC01
    Scenario: Successful blocking of an account with minimal required data
    Given an existing account with accountId 'valid-uuid-1'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-1/block with the request body
    Then the response status code should be 201
    And the response body should be a JSON array containing the created BlockingState object(s)
    And the BlockingState should reflect the requested block

    @TC02
    Scenario: Successful blocking with all optional parameters and headers
    Given an existing account with accountId 'valid-uuid-2'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'adminUser'
    And header X-Killbill-Reason is set to 'Suspicious activity'
    And header X-Killbill-Comment is set to 'Manual review required'
    And query parameter requestedDate is set to '2024-07-01'
    And query parameter pluginProperty is set to ['prop1', 'prop2']
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-2/block with all parameters
    Then the response status code should be 201
    And the response body should contain the BlockingState(s) with the correct effective date and plugin properties

    @TC03
    Scenario: Blocking with only requestedDate provided
    Given an existing account with accountId 'valid-uuid-3'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'opsUser'
    And query parameter requestedDate is set to '2024-08-01'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-3/block
    Then the response status code should be 201
    And the BlockingState effective date should match '2024-08-01'

    @TC04
    Scenario: Blocking with only pluginProperty provided
    Given an existing account with accountId 'valid-uuid-4'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'pluginUser'
    And query parameter pluginProperty is set to ['customProp']
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-4/block
    Then the response status code should be 201
    And the BlockingState should reflect the plugin properties

    @TC05
    Scenario: Blocking when no data exists for the account
    Given an accountId 'valid-uuid-5' exists but has no prior blocking states
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-5/block
    Then the response status code should be 201
    And the response body should contain the new BlockingState

    @TC06
    Scenario: Blocking when account does not exist
    Given a non-existent accountId 'nonexistent-uuid'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/nonexistent-uuid/block
    Then the response status code should be 404
    And the response body should indicate account not found

    @TC07
    Scenario: Invalid accountId format
    Given an invalid accountId 'bad-id'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/bad-id/block
    Then the response status code should be 400
    And the response body should indicate invalid accountId

    @TC08
    Scenario: Missing required header X-Killbill-CreatedBy
    Given an existing account with accountId 'valid-uuid-6'
    And a valid BlockingState JSON body is prepared
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-6/block without X-Killbill-CreatedBy
    Then the response status code should be 400
    And the response body should indicate missing required header

    @TC09
    Scenario: Missing request body
    Given an existing account with accountId 'valid-uuid-7'
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-7/block without a request body
    Then the response status code should be 400
    And the response body should indicate malformed request

    @TC10
    Scenario: Malformed JSON in request body
    Given an existing account with accountId 'valid-uuid-8'
    And header X-Killbill-CreatedBy is set to 'testUser'
    And the request body is not valid JSON
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-8/block
    Then the response status code should be 400
    And the response body should indicate malformed request body

    @TC11
    Scenario: Unauthorized access attempt
    Given an existing account with accountId 'valid-uuid-9'
    And a valid BlockingState JSON body is prepared
    And no authentication token is provided
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-9/block
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC12
    Scenario: System error - database unavailable
    Given the database is unavailable
    And an existing account with accountId 'valid-uuid-10'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-10/block
    Then the response status code should be 503
    And the response body should indicate service unavailable

    @TC13
    Scenario: Security - SQL injection attempt in accountId
    Given an accountId 'valid-uuid-11;DROP TABLE accounts;'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-11;DROP TABLE accounts;/block
    Then the response status code should be 400
    And the response body should indicate invalid accountId

    @TC14
    Scenario: Security - Malicious payload in request body
    Given an existing account with accountId 'valid-uuid-12'
    And the request body contains a script tag or malicious payload
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-12/block
    Then the response status code should be 400
    And the response body should indicate invalid or unsafe input

    @TC15
    Scenario: Edge case - empty pluginProperty array
    Given an existing account with accountId 'valid-uuid-13'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'testUser'
    And query parameter pluginProperty is set to []
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-13/block
    Then the response status code should be 201
    And the response body should contain the BlockingState(s)

    @TC16
    Scenario: Edge case - maximum allowed field lengths in BlockingState
    Given an existing account with accountId 'valid-uuid-14'
    And a BlockingState JSON body is prepared with all string fields at maximum allowed length
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-14/block
    Then the response status code should be 201
    And the response body should contain the BlockingState(s) with all fields correctly stored

    @TC17
    Scenario: Edge case - minimum allowed values in BlockingState
    Given an existing account with accountId 'valid-uuid-15'
    And a BlockingState JSON body is prepared with minimum (non-null) values
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-15/block
    Then the response status code should be 201
    And the response body should contain the BlockingState(s) with correct values

    @TC18
    Scenario: Extra parameters provided in query string
    Given an existing account with accountId 'valid-uuid-16'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'testUser'
    And query parameter extraParam is set to 'extraValue'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-16/block
    Then the response status code should be 201
    And the response body should ignore extra parameters

    @TC19
    Scenario: Long-running operation (simulate slow downstream)
    Given an existing account with accountId 'valid-uuid-17'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'testUser'
    And downstream service is artificially delayed
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-17/block
    Then the response status code should be 201
    And the response time should be within acceptable timeout limits

    @TC20
    Scenario: Large payload (BlockingState array near size limit)
    Given an existing account with accountId 'valid-uuid-18'
    And a BlockingState JSON body with a large number of entries near the maximum allowed payload size
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-18/block
    Then the response status code should be 201
    And the response body should contain all BlockingState(s) created

    @TC21
    Scenario: Integration - pluginProperty triggers plugin interaction
    Given an existing account with accountId 'valid-uuid-19'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'testUser'
    And query parameter pluginProperty is set to ['triggerPlugin']
    And the plugin service is available
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-19/block
    Then the response status code should be 201
    And the plugin should process the property and the response should reflect plugin output

    @TC22
    Scenario: Integration - plugin service unavailable
    Given an existing account with accountId 'valid-uuid-20'
    And a valid BlockingState JSON body is prepared
    And header X-Killbill-CreatedBy is set to 'testUser'
    And query parameter pluginProperty is set to ['triggerPlugin']
    And the plugin service is unavailable
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-20/block
    Then the response status code should be 503
    And the response body should indicate plugin service unavailable

    @TC23
    Scenario: Regression - previously fixed issue with duplicate BlockingState
    Given an existing account with accountId 'valid-uuid-21'
    And a BlockingState JSON body that previously caused duplicate entries
    And header X-Killbill-CreatedBy is set to 'testUser'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-21/block
    Then the response status code should be 201
    And the response body should not contain duplicate BlockingState entries

    @TC24
    Scenario: Regression - backward compatibility with old clients
    Given an existing account with accountId 'valid-uuid-22'
    And a BlockingState JSON body using only fields supported by previous API versions
    And header X-Killbill-CreatedBy is set to 'legacyUser'
    When the user sends a POST request to /1.0/kb/accounts/valid-uuid-22/block
    Then the response status code should be 201
    And the response body should be compatible with previous clients

    @TC25
    Scenario: Performance - high concurrency
    Given 100 concurrent requests to block different accounts
    And each request has a valid BlockingState JSON body
    And header X-Killbill-CreatedBy is set to 'perfUser'
    When the requests are sent simultaneously to /1.0/kb/accounts/{accountId}/block
    Then all responses should return 201 within acceptable response time thresholds

    @TC26
    Scenario: Performance - resource utilization under load
    Given a high volume of requests to block accounts over a sustained period
    And each request is valid
    When the requests are processed
    Then the system should not exceed acceptable CPU, memory, and network usage

    @TC27
    Scenario: Accessibility - API documentation and error messages
    Given a user with accessibility needs
    When the user reviews the API documentation and error messages
    Then all documentation and responses should be screen reader compatible and meet accessibility standards