Feature: Retrieve custom fields for a specific invoice payment via GET /1.0/kb/invoicePayments/{paymentId}/customFields
As a KillBill API user,
I want to retrieve custom fields for an invoice payment by its paymentId,
so that I can view all metadata associated with a particular invoice payment.

  Background:
  Given the KillBill API is available
  And the user has valid authentication credentials
  And the database contains invoice payments with and without custom fields
  And the user knows a valid paymentId in UUID format
  And the API endpoint /1.0/kb/invoicePayments/{paymentId}/customFields is reachable

    @TC01
    Scenario: Successful retrieval of custom fields with default audit level (NONE)
    Given an invoice payment exists with paymentId "{validPaymentId}"
    And the payment has custom fields associated
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields without query parameters
    Then the API responds with HTTP 200
    And the response body is a JSON array of CustomField objects corresponding to the payment
    And the audit information in each object is at the NONE level

    @TC02
    Scenario: Successful retrieval of custom fields with audit=FULL
    Given an invoice payment exists with paymentId "{validPaymentId}"
    And the payment has custom fields associated
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields with query parameter audit=FULL
    Then the API responds with HTTP 200
    And the response body is a JSON array of CustomField objects including FULL audit information

    @TC03
    Scenario: Successful retrieval of custom fields with audit=MINIMAL
    Given an invoice payment exists with paymentId "{validPaymentId}"
    And the payment has custom fields associated
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields with query parameter audit=MINIMAL
    Then the API responds with HTTP 200
    And the response body is a JSON array of CustomField objects including MINIMAL audit information

    @TC04
    Scenario: Successful retrieval when invoice payment has no custom fields
    Given an invoice payment exists with paymentId "{validPaymentIdNoCustomFields}"
    And the payment has no custom fields
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentIdNoCustomFields}/customFields
    Then the API responds with HTTP 200
    And the response body is an empty JSON array

    @TC05
    Scenario: Successful retrieval with extra query parameters (ignored)
    Given an invoice payment exists with paymentId "{validPaymentId}"
    And the payment has custom fields associated
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields with query parameter foo=bar
    Then the API responds with HTTP 200
    And the response body is a JSON array of CustomField objects

    @TC06
    Scenario: Invalid paymentId format
    Given the user provides an invalid paymentId "not-a-uuid"
    When the user sends a GET request to /1.0/kb/invoicePayments/not-a-uuid/customFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid paymentId format

    @TC07
    Scenario: Non-existent paymentId
    Given the user provides a syntactically valid but non-existent paymentId "00000000-0000-0000-0000-000000000000"
    When the user sends a GET request to /1.0/kb/invoicePayments/00000000-0000-0000-0000-000000000000/customFields
    Then the API responds with HTTP 404
    And the response body contains an error message indicating payment not found

    @TC08
    Scenario: Unauthorized access (no authentication token)
    Given the user does not provide authentication credentials
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields
    Then the API responds with HTTP 401
    And the response body contains an authentication error message

    @TC09
    Scenario: Unauthorized access (invalid authentication token)
    Given the user provides an invalid authentication token
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields
    Then the API responds with HTTP 401
    And the response body contains an authentication error message

    @TC10
    Scenario: Service unavailable
    Given the KillBill API service is down
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields
    Then the API responds with HTTP 503
    And the response body contains a service unavailable error message

    @TC11
    Scenario: Large number of custom fields for a payment
    Given an invoice payment exists with paymentId "{validPaymentIdLargeFields}"
    And the payment has 1000 custom fields associated
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentIdLargeFields}/customFields
    Then the API responds with HTTP 200
    And the response body is a JSON array of 1000 CustomField objects

    @TC12
    Scenario: Response time within acceptable threshold
    Given an invoice payment exists with paymentId "{validPaymentId}"
    And the payment has custom fields associated
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields
    Then the API responds within 500ms
    And the response body is a JSON array of CustomField objects

    @TC13
    Scenario: SQL injection attempt in paymentId
    Given the user provides a paymentId with SQL injection pattern "1 OR 1=1"
    When the user sends a GET request to /1.0/kb/invoicePayments/1%20OR%201=1/customFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid paymentId format

    @TC14
    Scenario: XSS attempt in paymentId
    Given the user provides a paymentId with XSS pattern "<script>alert('x')</script>"
    When the user sends a GET request to /1.0/kb/invoicePayments/%3Cscript%3Ealert('x')%3C/script%3E/customFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid paymentId format

    @TC15
    Scenario: Retry after transient network failure
    Given an invoice payment exists with paymentId "{validPaymentId}"
    And a transient network failure occurs during the first request
    When the user retries the GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields
    Then the API responds with HTTP 200
    And the response body is a JSON array of CustomField objects

    @TC16
    Scenario: Backward compatibility - previous clients using audit=NONE explicitly
    Given an invoice payment exists with paymentId "{validPaymentId}"
    And the payment has custom fields associated
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields with query parameter audit=NONE
    Then the API responds with HTTP 200
    And the response body is a JSON array of CustomField objects with NONE audit info

    @TC17
    Scenario: Integration - dependent service for custom fields is unavailable
    Given the dependent custom fields service is down
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields
    Then the API responds with HTTP 502
    And the response body contains an error message indicating dependency failure

    @TC18
    Scenario: Data consistency after custom field update
    Given an invoice payment exists with paymentId "{validPaymentId}"
    And a custom field was recently added to the payment
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields
    Then the API responds with HTTP 200
    And the response body includes the newly added custom field

    @TC19
    Scenario: Regression - previously fixed issue with empty custom fields array
    Given an invoice payment exists with paymentId "{validPaymentIdNoCustomFields}"
    And the payment has no custom fields (previously caused a 500 error)
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentIdNoCustomFields}/customFields
    Then the API responds with HTTP 200
    And the response body is an empty JSON array

    @TC20
    Scenario: Partial input - paymentId with trailing spaces
    Given the user provides a paymentId "{validPaymentId} " with trailing space
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}%20/customFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid paymentId format

    @TC21
    Scenario: Unexpected input format - paymentId with special characters
    Given the user provides a paymentId "@!#%$^" with special characters
    When the user sends a GET request to /1.0/kb/invoicePayments/@!#%$^/customFields
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid paymentId format

    @TC22
    Scenario: System state - empty database (no invoice payments)
    Given the database contains no invoice payments
    When the user sends a GET request to /1.0/kb/invoicePayments/{anyPaymentId}/customFields
    Then the API responds with HTTP 404
    And the response body contains an error message indicating payment not found

    @TC23
    Scenario: System state - partially populated database
    Given the database contains some invoice payments, some with and some without custom fields
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields
    Then the API responds with HTTP 200
    And the response body is a JSON array of CustomField objects if custom fields exist, or an empty array if not

    @TC24
    Scenario: Performance under concurrent requests
    Given multiple users send concurrent GET requests to /1.0/kb/invoicePayments/{validPaymentId}/customFields
    When the system is under peak load
    Then all responses are HTTP 200
    And the average response time is within acceptable limits

    @TC25
    Scenario: Malformed audit parameter value
    Given an invoice payment exists with paymentId "{validPaymentId}"
    When the user sends a GET request to /1.0/kb/invoicePayments/{validPaymentId}/customFields with query parameter audit=INVALID
    Then the API responds with HTTP 400
    And the response body contains an error message indicating invalid audit parameter value