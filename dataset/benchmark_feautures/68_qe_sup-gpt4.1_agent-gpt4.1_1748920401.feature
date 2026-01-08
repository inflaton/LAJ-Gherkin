Feature: Upload Catalog XML via POST /1.0/kb/catalog/xml
As a KillBill API user,
I want to upload a new catalog version in XML format,
so that I can manage and update the product catalog.

  Background:
  Given the KillBill API server is running and reachable
  And the API endpoint POST /1.0/kb/catalog/xml is available
  And valid authentication and authorization are configured (if required)
  And the database is seeded with relevant catalog data (empty, partial, or full as needed)
  And any required dependencies or external services are mocked or available

    @TC01
    Scenario: Successful upload of valid catalog XML with all headers
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    And the X-Killbill-Reason header is set to "Initial upload"
    And the X-Killbill-Comment header is set to "Uploading new catalog version"
    When the client sends a POST request to /1.0/kb/catalog/xml with the XML payload and all headers
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI
    And the Location header is present and contains the catalog resource URL
    And the new catalog version is available in the system

    @TC02
    Scenario: Successful upload of valid catalog XML with only required header
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    And the X-Killbill-Reason header is not set
    And the X-Killbill-Comment header is not set
    When the client sends a POST request to /1.0/kb/catalog/xml with the XML payload and only the required header
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI
    And the Location header is present and contains the catalog resource URL

    @TC03
    Scenario: Successful upload with additional optional headers
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    And the X-Killbill-Reason header is set to "Monthly update"
    And the X-Killbill-Comment header is not set
    When the client sends a POST request to /1.0/kb/catalog/xml with the XML payload and optional headers
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI

    @TC04
    Scenario: Successful upload when the catalog database is empty
    Given the catalog database is empty
    And a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the new catalog version is available in the system

    @TC05
    Scenario: Successful upload when the catalog database has existing data
    Given the catalog database contains existing catalog versions
    And a well-formed catalog XML payload for a new version
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the new catalog version is available in the system

    @TC06
    Scenario: Upload with missing required header X-Killbill-CreatedBy
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is missing
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 400
    And the response body contains an error message indicating the missing header

    @TC07
    Scenario: Upload with empty X-Killbill-CreatedBy header
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to an empty string
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 400
    And the response body contains an error message indicating the invalid header value

    @TC08
    Scenario: Upload with malformed/invalid XML payload
    Given a malformed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 400
    And the response body contains an error message indicating invalid XML

    @TC09
    Scenario: Upload with empty request body
    Given an empty request body
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 400
    And the response body contains an error message indicating missing body

    @TC10
    Scenario: Upload with unsupported content type
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    And the Content-Type header is set to "application/json"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 400
    And the response body contains an error message indicating invalid content type

    @TC11
    Scenario: Upload with extra/unexpected headers
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    And an extra header X-Extra-Header is set to "extra-value"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI

    @TC12
    Scenario: Upload with very large XML payload (approaching system limits)
    Given a very large but well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201 or 400 depending on system limits
    And the response body contains a confirmation string or an error message about payload size

    @TC13
    Scenario: Upload with minimal valid XML payload
    Given a minimal valid catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI

    @TC14
    Scenario: Upload with invalid authentication (if authentication is required)
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    And the authentication token is missing or invalid
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 401 or 403
    And the response body contains an error message indicating unauthorized access

    @TC15
    Scenario: Upload with network interruption during upload
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml and the network connection is interrupted
    Then the API does not process the catalog upload
    And no new catalog version is created

    @TC16
    Scenario: Upload when the backend service is unavailable
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    And the backend service is down
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 503
    And the response body contains an error message indicating service unavailability

    @TC17
    Scenario: Upload with XML containing unsupported or malicious content (security test)
    Given a catalog XML payload containing unsupported or malicious content (e.g., XXE, script injection)
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 400 or 422
    And the response body contains an error message indicating invalid or dangerous content

    @TC18
    Scenario: Upload with partial/corrupted XML payload
    Given a partially transmitted or corrupted XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 400
    And the response body contains an error message indicating malformed XML

    @TC19
    Scenario: Performance - Upload under normal load
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends 10 POST requests to /1.0/kb/catalog/xml in quick succession
    Then each API response is received within 2 seconds
    And all uploads are successful (status code 201)

    @TC20
    Scenario: Performance - Upload under concurrent load
    Given 20 well-formed catalog XML payloads
    And the X-Killbill-CreatedBy header is set to "test-user"
    When 20 clients concurrently send POST requests to /1.0/kb/catalog/xml
    Then all API responses are received within acceptable performance thresholds (e.g., 5 seconds)
    And all uploads are successful (status code 201)

    @TC21
    Scenario: Regression - Upload with previously problematic XML (known bug)
    Given a catalog XML payload that previously triggered a known bug
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the bug is not reproduced

    @TC22
    Scenario: Regression - Backward compatibility with previous clients
    Given a well-formed catalog XML payload generated by an older client
    And the X-Killbill-CreatedBy header is set to "legacy-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI

    @TC23
    Scenario: Upload with whitespace-only XML payload
    Given an XML payload containing only whitespace
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 400
    And the response body contains an error message indicating invalid XML

    @TC24
    Scenario: Upload with XML containing special characters and unicode
    Given a well-formed catalog XML payload containing special characters and unicode
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI

    @TC25
    Scenario: Upload with duplicate catalog version
    Given a well-formed catalog XML payload with a version already present in the system
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201 or 409 depending on system behavior
    And the response body contains a confirmation string or an error message indicating duplicate version

    @TC26
    Scenario: Upload with additional, unexpected parameters in the request
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    And additional query parameters are appended to the URL
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI

    @TC27
    Scenario: Upload with minimal headers and large whitespace in XML
    Given a well-formed catalog XML payload with large whitespace
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI

    @TC28
    Scenario: Upload with XML containing comments and CDATA sections
    Given a well-formed catalog XML payload containing XML comments and CDATA sections
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI

    @TC29
    Scenario: Upload with XML using different encodings (UTF-8, UTF-16)
    Given a well-formed catalog XML payload encoded in UTF-8
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI

    Given a well-formed catalog XML payload encoded in UTF-16
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI

    @TC30
    Scenario: Upload with XML containing boundary values for all fields
    Given a well-formed catalog XML payload with boundary values (e.g., min/max lengths, numbers)
    And the X-Killbill-CreatedBy header is set to "test-user"
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the response body contains a confirmation string or URI

    @TC31
    Scenario: Accessibility - Upload via accessible client
    Given a well-formed catalog XML payload
    And the X-Killbill-CreatedBy header is set to "test-user"
    And the client is using assistive technology (e.g., screen reader)
    When the client sends a POST request to /1.0/kb/catalog/xml
    Then the API responds with status code 201
    And the response body is accessible and readable by assistive technology