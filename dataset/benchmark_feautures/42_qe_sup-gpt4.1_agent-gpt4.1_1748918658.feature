Feature: GET /1.0/kb/admin/queues - Retrieve queue entries
As an administrator,
I want to retrieve queue entries with flexible filtering options,
so that I can monitor and manage system queues efficiently.

  Background:
  Given the KillBill system is running and accessible
  And the API endpoint /1.0/kb/admin/queues is available
  And the database is seeded with diverse queue entries for multiple accounts, queue names, and service names
  And valid and invalid account IDs are available
  And valid authentication tokens are set in the request headers

    @TC01
    Scenario: Successful retrieval with no query parameters (default behavior)
    Given the database contains queue entries
    When the admin sends a GET request to /1.0/kb/admin/queues with no query parameters
    Then the response status code should be 200
    And the response content type should be application/octet-stream
    And the response body should contain all queue entries (withHistory=true, withInProcessing=true, withBusEvents=true, withNotifications=true by default)

    @TC02
    Scenario: Successful retrieval with accountId filter
    Given a valid accountId exists with associated queue entries
    When the admin sends a GET request to /1.0/kb/admin/queues with accountId=<valid_account_id>
    Then the response status code should be 200
    And the response body should contain only queue entries for that accountId

    @TC03
    Scenario: Successful retrieval with queueName filter
    Given queue entries exist with queueName 'INVOICE_QUEUE'
    When the admin sends a GET request to /1.0/kb/admin/queues with queueName=INVOICE_QUEUE
    Then the response status code should be 200
    And the response body should contain only entries from 'INVOICE_QUEUE'

    @TC04
    Scenario: Successful retrieval with serviceName filter
    Given queue entries exist with serviceName 'payment-service'
    When the admin sends a GET request to /1.0/kb/admin/queues with serviceName=payment-service
    Then the response status code should be 200
    And the response body should contain only entries for 'payment-service'

    @TC05
    Scenario: Successful retrieval with minDate and maxDate filters
    Given queue entries exist between 2023-01-01 and 2023-12-31
    When the admin sends a GET request to /1.0/kb/admin/queues with minDate=2023-01-01 and maxDate=2023-12-31
    Then the response status code should be 200
    And the response body should contain only entries within the specified date range

    @TC06
    Scenario: Successful retrieval with withHistory=false
    Given queue entries exist with and without history
    When the admin sends a GET request to /1.0/kb/admin/queues with withHistory=false
    Then the response status code should be 200
    And the response body should not include history data

    @TC07
    Scenario: Successful retrieval with withInProcessing=false
    Given queue entries exist with in-processing status
    When the admin sends a GET request to /1.0/kb/admin/queues with withInProcessing=false
    Then the response status code should be 200
    And the response body should not include in-processing entries

    @TC08
    Scenario: Successful retrieval with withBusEvents=false
    Given queue entries exist with bus events
    When the admin sends a GET request to /1.0/kb/admin/queues with withBusEvents=false
    Then the response status code should be 200
    And the response body should not include bus events

    @TC09
    Scenario: Successful retrieval with withNotifications=false
    Given queue entries exist with notifications
    When the admin sends a GET request to /1.0/kb/admin/queues with withNotifications=false
    Then the response status code should be 200
    And the response body should not include notifications

    @TC10
    Scenario: Successful retrieval with all filters combined
    Given queue entries exist for accountId=<valid_account_id>, queueName='INVOICE_QUEUE', serviceName='payment-service', within date range, and with various flags
    When the admin sends a GET request to /1.0/kb/admin/queues with all query parameters set to valid values
    Then the response status code should be 200
    And the response body should contain only entries matching all filter criteria

    @TC11
    Scenario: Successful retrieval when no queue entries exist
    Given the database contains no queue entries
    When the admin sends a GET request to /1.0/kb/admin/queues
    Then the response status code should be 200
    And the response body should be empty

    @TC12
    Scenario: Successful retrieval with extra/unexpected parameters
    Given the database contains queue entries
    When the admin sends a GET request to /1.0/kb/admin/queues with extra parameter foo=bar
    Then the response status code should be 200
    And the response body should contain queue entries as per default behavior

    @TC13
    Scenario: Invalid accountId format
    Given an invalid accountId format (not a UUID)
    When the admin sends a GET request to /1.0/kb/admin/queues with accountId=invalid_format
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid account ID

    @TC14
    Scenario: Valid accountId not found
    Given a valid accountId UUID that does not exist in the system
    When the admin sends a GET request to /1.0/kb/admin/queues with accountId=<nonexistent_account_id>
    Then the response status code should be 404
    And the response body should contain an error message indicating account not found

    @TC15
    Scenario: Unauthorized access attempt
    Given the admin does not provide a valid authentication token
    When the admin sends a GET request to /1.0/kb/admin/queues
    Then the response status code should be 401
    And the response body should indicate unauthorized access

    @TC16
    Scenario: Service unavailable
    Given the backend service is down
    When the admin sends a GET request to /1.0/kb/admin/queues
    Then the response status code should be 503
    And the response body should indicate service unavailable

    @TC17
    Scenario: Injection attack attempt in query parameters
    Given a malicious input is provided in queueName (e.g., queueName='INVOICE_QUEUE; DROP TABLE queues;')
    When the admin sends a GET request to /1.0/kb/admin/queues with the malicious queueName
    Then the response status code should be 400 or sanitized
    And the response body should not expose internal errors

    @TC18
    Scenario: Large data volume retrieval
    Given the database contains a large number of queue entries (e.g., 100,000+)
    When the admin sends a GET request to /1.0/kb/admin/queues
    Then the response status code should be 200
    And the response should be returned within acceptable response time thresholds (e.g., <2 seconds)
    And the response body should contain all entries

    @TC19
    Scenario: Timeout condition
    Given the backend takes too long to respond
    When the admin sends a GET request to /1.0/kb/admin/queues
    Then the response status code should be 504
    And the response body should indicate a timeout occurred

    @TC20
    Scenario: Concurrent requests
    Given multiple admins send GET requests to /1.0/kb/admin/queues simultaneously
    When the requests are processed
    Then all responses should have status code 200
    And each response body should contain the correct queue entries as per request parameters

    @TC21
    Scenario: Regression - previously fixed issue for withHistory parameter
    Given a previous bug caused withHistory=false to be ignored
    When the admin sends a GET request to /1.0/kb/admin/queues with withHistory=false
    Then the response status code should be 200
    And the response body should not include history data

    @TC22
    Scenario: Backward compatibility with clients omitting new parameters
    Given a client sends a GET request without new optional parameters
    When the request is processed
    Then the response status code should be 200
    And the response body should match legacy behavior (all flags default to true)

    @TC23
    Scenario: Partial input - only one parameter provided
    Given the admin provides only queueName=INVOICE_QUEUE
    When the admin sends a GET request to /1.0/kb/admin/queues with only queueName
    Then the response status code should be 200
    And the response body should contain only entries from 'INVOICE_QUEUE'

    @TC24
    Scenario: Minimum and maximum allowed values for date parameters
    Given the system supports a defined date range (e.g., 1970-01-01 to 2099-12-31)
    When the admin sends a GET request to /1.0/kb/admin/queues with minDate=1970-01-01 and maxDate=2099-12-31
    Then the response status code should be 200
    And the response body should contain entries within the full supported date range

    @TC25
    Scenario: Malformed date parameters
    Given the admin provides minDate=not-a-date
    When the admin sends a GET request to /1.0/kb/admin/queues with minDate=not-a-date
    Then the response status code should be 400
    And the response body should indicate invalid date format

    @TC26
    Scenario: Security - XSS attempt in serviceName
    Given a malicious input is provided in serviceName (e.g., serviceName='<script>alert(1)</script>')
    When the admin sends a GET request to /1.0/kb/admin/queues with the malicious serviceName
    Then the response status code should be 400 or sanitized
    And the response body should not execute or reflect the script

    @TC27
    Scenario: Recovery from transient network failure
    Given a network failure occurs during the request
    When the admin retries the GET request to /1.0/kb/admin/queues
    Then the response status code should be 200 (if recovered)
    And the response body should contain the expected queue entries

    @TC28
    Scenario: Accessibility - API documentation and error messages
    Given the admin accesses the API documentation
    When the admin reviews the error messages returned by the API
    Then all error messages should be descriptive and accessible
    And error payloads should follow a consistent JSON error schema

    @TC29
    Scenario: Empty response when filters exclude all data
    Given the database contains queue entries
    When the admin sends a GET request to /1.0/kb/admin/queues with filters that match no entries
    Then the response status code should be 200
    And the response body should be empty

    @TC30
    Scenario: Server error (internal failure)
    Given an internal server error occurs during processing
    When the admin sends a GET request to /1.0/kb/admin/queues
    Then the response status code should be 500
    And the response body should indicate an internal server error