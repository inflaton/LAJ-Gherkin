Feature: Retrieve a subscription bundle by external key via GET /1.0/kb/bundles
As a KillBill API user,
I want to retrieve a bundle by its external key,
so that I can view bundle details and audit information as needed.

  Background:
  Given the KillBill API is running and accessible
  And the database contains multiple bundles with diverse external keys
  And valid authentication tokens are available
  And the API endpoint /1.0/kb/bundles is reachable

    @TC01
    Scenario: Successful retrieval of bundle by external key (happy path)
    Given a bundle exists with externalKey "BUNDLE-123"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-123
    Then the response status should be 200
    And the response body should be a JSON array containing exactly one Bundle object with externalKey "BUNDLE-123"
    And the Bundle object should not be marked as deleted
    And the response Content-Type should be application/json

    @TC02
    Scenario: Retrieval with includedDeleted=true returns deleted bundles
    Given a deleted bundle exists with externalKey "BUNDLE-DEL"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-DEL&includedDeleted=true
    Then the response status should be 200
    And the response body should be a JSON array containing the deleted Bundle object with externalKey "BUNDLE-DEL"
    And the Bundle object should be marked as deleted

    @TC03
    Scenario: Retrieval with audit=FULL returns full audit information
    Given a bundle exists with externalKey "BUNDLE-AUDIT"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-AUDIT&audit=FULL
    Then the response status should be 200
    And the Bundle object in the response should contain full audit fields

    @TC04
    Scenario: Retrieval with audit=MINIMAL returns minimal audit information
    Given a bundle exists with externalKey "BUNDLE-AUDIT"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-AUDIT&audit=MINIMAL
    Then the response status should be 200
    And the Bundle object in the response should contain minimal audit fields

    @TC05
    Scenario: Retrieval with audit=NONE omits audit information
    Given a bundle exists with externalKey "BUNDLE-AUDIT"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-AUDIT&audit=NONE
    Then the response status should be 200
    And the Bundle object in the response should not contain audit fields

    @TC06
    Scenario: Retrieval with includedDeleted=false does not return deleted bundles
    Given a deleted bundle exists with externalKey "BUNDLE-DEL"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-DEL&includedDeleted=false
    Then the response status should be 404
    And the response body should indicate bundle not found

    @TC07
    Scenario: Retrieval with missing required parameter externalKey
    Given the user omits the externalKey parameter
    When the user sends GET /1.0/kb/bundles
    Then the response status should be 400
    And the response body should indicate missing required parameter

    @TC08
    Scenario: Retrieval with non-existent externalKey
    Given no bundle exists with externalKey "NON-EXISTENT"
    When the user sends GET /1.0/kb/bundles?externalKey=NON-EXISTENT
    Then the response status should be 404
    And the response body should indicate bundle not found

    @TC09
    Scenario: Retrieval with invalid includedDeleted value
    Given a bundle exists with externalKey "BUNDLE-123"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-123&includedDeleted=notaboolean
    Then the response status should be 400
    And the response body should indicate invalid parameter value

    @TC10
    Scenario: Retrieval with invalid audit value
    Given a bundle exists with externalKey "BUNDLE-123"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-123&audit=INVALID
    Then the response status should be 400
    And the response body should indicate invalid parameter value

    @TC11
    Scenario: Unauthorized access attempt
    Given a bundle exists with externalKey "BUNDLE-123"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-123 without authentication token
    Then the response status should be 401
    And the response body should indicate authentication required

    @TC12
    Scenario: Forbidden access attempt with insufficient permissions
    Given a bundle exists with externalKey "BUNDLE-123"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-123 with a token lacking required permissions
    Then the response status should be 403
    And the response body should indicate insufficient permissions

    @TC13
    Scenario: System error (dependency failure)
    Given a bundle exists with externalKey "BUNDLE-123"
    And the database is unavailable
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-123
    Then the response status should be 503
    And the response body should indicate service unavailable

    @TC14
    Scenario: Large payload with multiple bundles having same externalKey (data anomaly)
    Given multiple bundles exist with externalKey "BUNDLE-DUPLICATE"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-DUPLICATE
    Then the response status should be 200
    And the response body should be a JSON array containing all Bundle objects with externalKey "BUNDLE-DUPLICATE"

    @TC15
    Scenario: Extra unsupported parameters are ignored
    Given a bundle exists with externalKey "BUNDLE-123"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-123&foo=bar
    Then the response status should be 200
    And the response body should be a JSON array containing the Bundle object with externalKey "BUNDLE-123"

    @TC16
    Scenario: Empty response when no bundles exist in the system
    Given the database contains no bundles
    When the user sends GET /1.0/kb/bundles?externalKey=ANYKEY
    Then the response status should be 404
    And the response body should indicate bundle not found

    @TC17
    Scenario: Response time is within acceptable threshold
    Given a bundle exists with externalKey "BUNDLE-123"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-123
    Then the response status should be 200
    And the response should be received within 500ms

    @TC18
    Scenario: Concurrent requests for the same externalKey
    Given a bundle exists with externalKey "BUNDLE-123"
    When multiple users send GET /1.0/kb/bundles?externalKey=BUNDLE-123 concurrently
    Then all responses should have status 200
    And each response should contain the correct Bundle object

    @TC19
    Scenario: SQL injection attempt in externalKey parameter
    Given the user attempts to inject SQL via externalKey parameter
    When the user sends GET /1.0/kb/bundles?externalKey=' OR '1'='1
    Then the response status should be 404 or 400
    And the response body should not expose sensitive error details

    @TC20
    Scenario: XSS attempt in externalKey parameter
    Given the user attempts to inject XSS via externalKey parameter
    When the user sends GET /1.0/kb/bundles?externalKey=<script>alert(1)</script>
    Then the response status should be 404 or 400
    And the response body should not execute or reflect script tags

    @TC21
    Scenario: Recovery from transient network failure
    Given a bundle exists with externalKey "BUNDLE-123"
    And a transient network failure occurs during the request
    When the user retries the GET /1.0/kb/bundles?externalKey=BUNDLE-123
    Then the response status should be 200
    And the response body should contain the Bundle object

    @TC22
    Scenario: Backward compatibility with previous API clients
    Given a bundle exists with externalKey "BUNDLE-123"
    When a legacy client sends GET /1.0/kb/bundles?externalKey=BUNDLE-123
    Then the response status should be 200
    And the response body should be compatible with previous Bundle schema

    @TC23
    Scenario: Regression - previously fixed bug for non-ASCII externalKey
    Given a bundle exists with externalKey "BÜNDLE-ÜNICODE"
    When the user sends GET /1.0/kb/bundles?externalKey=BÜNDLE-ÜNICODE
    Then the response status should be 200
    And the response body should contain the Bundle object with externalKey "BÜNDLE-ÜNICODE"

    @TC24
    Scenario: Maximum allowed length for externalKey
    Given a bundle exists with an externalKey of maximum allowed length (e.g., 255 chars)
    When the user sends GET /1.0/kb/bundles?externalKey=<max_length_key>
    Then the response status should be 200
    And the response body should contain the Bundle object with the long externalKey

    @TC25
    Scenario: Minimum allowed length for externalKey
    Given a bundle exists with an externalKey of minimum allowed length (e.g., 1 char)
    When the user sends GET /1.0/kb/bundles?externalKey=A
    Then the response status should be 200
    And the response body should contain the Bundle object with externalKey "A"

    @TC26
    Scenario: Unexpected input format for externalKey
    Given a bundle exists with externalKey "BUNDLE-123"
    When the user sends GET /1.0/kb/bundles?externalKey=%00BUNDLE-123
    Then the response status should be 404 or 400
    And the response body should not expose sensitive error details

    @TC27
    Scenario: Very large number of bundles in the database
    Given the database contains 10,000 bundles
    And a bundle exists with externalKey "BUNDLE-9999"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-9999
    Then the response status should be 200
    And the response body should contain the Bundle object with externalKey "BUNDLE-9999"

    @TC28
    Scenario: Service downtime
    Given the KillBill API service is down
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-123
    Then the response status should be 503
    And the response body should indicate service unavailable

    @TC29
    Scenario: Partial input (externalKey parameter present but empty)
    Given the user sends externalKey parameter with an empty value
    When the user sends GET /1.0/kb/bundles?externalKey=
    Then the response status should be 400
    And the response body should indicate invalid parameter value

    @TC30
    Scenario: Response contains required Bundle fields
    Given a bundle exists with externalKey "BUNDLE-123"
    When the user sends GET /1.0/kb/bundles?externalKey=BUNDLE-123
    Then the response status should be 200
    And the Bundle object in the response should contain all required fields as per Bundle definition