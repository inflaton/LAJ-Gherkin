Feature: Update Bundle External Key via PUT /1.0/kb/bundles/{bundleId}/renameKey
As a KillBill API user,
I want to update the external key of a subscription bundle,
so that I can manage bundle identifiers efficiently and resolve key conflicts.

  Background:
  Given the KillBill API is accessible and the endpoint /1.0/kb/bundles/{bundleId}/renameKey is available
  And the database contains bundles with unique external keys for each account
  And a valid authentication token is set (if required by the environment)
  And the request is made with Content-Type application/json

    @TC01
    Scenario: Successful update of bundle external key (Happy Path)
    Given a bundle exists with bundleId 'valid-bundle-uuid' and externalKey 'old-key'
    And the new externalKey 'new-bundle-external-key' is not used by any other bundle for the same account
    And the request header X-Killbill-CreatedBy is set to 'test-user'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with body {"externalKey": "new-bundle-external-key"}
    Then the response status code should be 204
    And the bundle with bundleId 'valid-bundle-uuid' should have externalKey updated to 'new-bundle-external-key'

    @TC02
    Scenario: Update with missing required header X-Killbill-CreatedBy (Error Scenario)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey without X-Killbill-CreatedBy header
    Then the response status code should be 400
    And the response body should contain an error message indicating missing required header

    @TC03
    Scenario: Update with malformed bundleId (Error Scenario)
    Given no bundle exists with bundleId 'malformed-id'
    When the user sends a PUT request to /1.0/kb/bundles/malformed-id/renameKey with a valid body and headers
    Then the response status code should be 400
    And the response body should indicate invalid bundleId format

    @TC04
    Scenario: Update with non-existent bundleId (Error Scenario)
    Given no bundle exists with bundleId 'nonexistent-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/nonexistent-uuid/renameKey with a valid body and headers
    Then the response status code should be 404
    And the response body should indicate bundle not found

    @TC05
    Scenario: Update with externalKey already used by another bundle for same account (Error Scenario)
    Given two bundles exist for the same account: bundleA with externalKey 'keyA' and bundleB with externalKey 'keyB'
    And the request is to update bundleA's externalKey to 'keyB'
    When the user sends a PUT request to /1.0/kb/bundles/{bundleA-id}/renameKey with body {"externalKey": "keyB"} and valid headers
    Then the response status code should be 400
    And the response body should indicate externalKey conflict

    @TC06
    Scenario: Update with missing request body (Error Scenario)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with no body and valid headers
    Then the response status code should be 400
    And the response body should indicate missing request body

    @TC07
    Scenario: Update with malformed JSON body (Error Scenario)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with malformed JSON body and valid headers
    Then the response status code should be 400
    And the response body should indicate JSON parse error

    @TC08
    Scenario: Update with missing externalKey in body (Error Scenario)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with body {} and valid headers
    Then the response status code should be 400
    And the response body should indicate missing externalKey

    @TC09
    Scenario: Update with extra fields in body (Edge Case)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with body {"externalKey": "extra-key", "foo": "bar"} and valid headers
    Then the response status code should be 204
    And the bundle with bundleId 'valid-bundle-uuid' should have externalKey updated to 'extra-key'

    @TC10
    Scenario: Update with extremely long externalKey (Edge Case)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    And the new externalKey is a string of 255 characters
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with body {"externalKey": "<255-char-string>"} and valid headers
    Then the response status code should be 204 or 400 depending on system limits
    And the response should indicate success or key length violation

    @TC11
    Scenario: Update with empty externalKey (Edge Case)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with body {"externalKey": ""} and valid headers
    Then the response status code should be 400
    And the response body should indicate invalid externalKey

    @TC12
    Scenario: Unauthorized update attempt (Error Scenario)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with valid body but missing or invalid authentication token
    Then the response status code should be 401 or 403
    And the response body should indicate unauthorized or forbidden access

    @TC13
    Scenario: Update with system dependency/service unavailable (Integration/Error Scenario)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    And the database or dependent service is unavailable
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with valid body and headers
    Then the response status code should be 503
    And the response body should indicate service unavailable

    @TC14
    Scenario: Update with X-Killbill-Reason and X-Killbill-Comment headers (Happy Path)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    And the headers X-Killbill-Reason and X-Killbill-Comment are set
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with valid body and all headers
    Then the response status code should be 204
    And the bundle with bundleId 'valid-bundle-uuid' should have externalKey updated

    @TC15
    Scenario: Update when no bundles exist in the system (Edge Case)
    Given the database contains no bundles
    When the user sends a PUT request to /1.0/kb/bundles/some-uuid/renameKey with valid body and headers
    Then the response status code should be 404
    And the response body should indicate bundle not found

    @TC16
    Scenario: Update with large payload (Performance/Edge Case)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with a very large but valid JSON body and valid headers
    Then the response status code should be 204 or 400 depending on payload limits
    And the response time should be within acceptable thresholds

    @TC17
    Scenario: Concurrent updates to the same bundle (Performance/Concurrency)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When multiple users send concurrent PUT requests to /1.0/kb/bundles/valid-bundle-uuid/renameKey with different valid externalKeys and headers
    Then only one request should succeed with 204, others should fail with 400 or 409 depending on conflict resolution

    @TC18
    Scenario: Regression - update with previously problematic externalKey
    Given a bundle exists with bundleId 'valid-bundle-uuid' and a known problematic externalKey 'problem-key'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with body {"externalKey": "problem-key"} and valid headers
    Then the response status code should be 204 or 400 as per fixed issue
    And the response should match expected behavior

    @TC19
    Scenario: Update with special characters in externalKey (Edge Case)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with body {"externalKey": "key-!@#$%^&*()_+"} and valid headers
    Then the response status code should be 204 or 400 depending on allowed character set
    And the response should indicate success or invalid characters

    @TC20
    Scenario: Update with trailing/leading spaces in externalKey (Edge Case)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with body {"externalKey": "  spaced-key  "} and valid headers
    Then the response status code should be 204 or 400 depending on trimming/validation rules
    And the bundle should reflect the correct externalKey value

    @TC21
    Scenario: Update with additional unexpected header (Edge Case)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with valid body, required headers, and an extra header X-Unexpected: "foo"
    Then the response status code should be 204
    And the bundle with bundleId 'valid-bundle-uuid' should have externalKey updated

    @TC22
    Scenario: Verify backward compatibility (Regression)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request using legacy clients with valid body and headers
    Then the response status code should be 204
    And the bundle with bundleId 'valid-bundle-uuid' should have externalKey updated

    @TC23
    Scenario: Response time under normal load (Performance)
    Given a bundle exists with bundleId 'valid-bundle-uuid'
    When the user sends a PUT request to /1.0/kb/bundles/valid-bundle-uuid/renameKey with valid body and headers
    Then the response time should be less than 500ms

    @TC24
    Scenario: Accessibility - API documentation is accessible (Accessibility)
    Given the API documentation for PUT /1.0/kb/bundles/{bundleId}/renameKey is published
    When a screen reader user accesses the documentation
    Then all required fields, parameters, and error codes are clearly described
    And the documentation is navigable via keyboard and screen reader