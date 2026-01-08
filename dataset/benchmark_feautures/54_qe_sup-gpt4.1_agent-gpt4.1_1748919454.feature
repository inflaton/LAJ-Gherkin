Feature: Remove tags from bundle via DELETE /1.0/kb/bundles/{bundleId}/tags
As a KillBill API user,
I want to remove tags from a bundle,
so that I can manage bundle metadata efficiently.

  Background:
  Given the KillBill API is available
  And the user has valid authentication and authorization
  And the database contains bundles with various tag associations
  And the following headers are set for each request:
    | Header                   | Value              |
    | X-Killbill-CreatedBy     | <valid_user>       |
    | X-Killbill-Reason        | <any_reason>       |
    | X-Killbill-Comment       | <any_comment>      |

    @TC01
    Scenario: Successful removal of all tags from a bundle (no tagDef specified)
    Given a bundle exists with id <valid_bundleId> and has multiple tags
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags with no tagDef query parameter
    Then the response status code should be 204
    And all tags should be removed from the bundle
    And the response body should be empty

    @TC02
    Scenario: Successful removal of specific tags from a bundle
    Given a bundle exists with id <valid_bundleId> and has tags <tagDef1>, <tagDef2>, <tagDef3>
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags with tagDef query parameters set to <tagDef1> and <tagDef3>
    Then the response status code should be 204
    And only tags <tagDef1> and <tagDef3> should be removed from the bundle
    And tag <tagDef2> should remain associated with the bundle
    And the response body should be empty

    @TC03
    Scenario: Successful removal with X-Killbill-Reason and X-Killbill-Comment headers
    Given a bundle exists with id <valid_bundleId> and has tags <tagDef1>, <tagDef2>
    And the headers X-Killbill-Reason and X-Killbill-Comment are set
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags with tagDef=<tagDef1>
    Then the response status code should be 204
    And tag <tagDef1> should be removed from the bundle
    And tag <tagDef2> should remain
    And the response body should be empty

    @TC04
    Scenario: Successful removal when bundle has no tags
    Given a bundle exists with id <valid_bundleId> and has no tags
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags
    Then the response status code should be 204
    And the response body should be empty

    @TC05
    Scenario: Attempt to remove tags with an invalid bundleId format
    Given a bundleId value <invalid_bundleId> that does not match the uuid pattern
    When the user sends a DELETE request to /1.0/kb/bundles/<invalid_bundleId>/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid bundle ID

    @TC06
    Scenario: Attempt to remove tags with a non-existent bundleId
    Given a bundleId value <nonexistent_bundleId> that matches the uuid pattern but does not exist
    When the user sends a DELETE request to /1.0/kb/bundles/<nonexistent_bundleId>/tags
    Then the response status code should be 404
    And the response body should contain an error message indicating bundle not found

    @TC07
    Scenario: Attempt to remove tags with an invalid tagDef UUID
    Given a bundle exists with id <valid_bundleId>
    And a tagDef value <invalid_tagDef> does not match the uuid pattern
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags with tagDef=<invalid_tagDef>
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid tagDef

    @TC08
    Scenario: Attempt to remove tags without X-Killbill-CreatedBy header
    Given a bundle exists with id <valid_bundleId>
    And the X-Killbill-CreatedBy header is missing
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating missing required header

    @TC09
    Scenario: Attempt to remove tags with unauthorized user
    Given a bundle exists with id <valid_bundleId>
    And the user is not authorized to perform the operation
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags
    Then the response status code should be 401
    And the response body should contain an error message indicating unauthorized access

    @TC10
    Scenario: Attempt to remove tags when the KillBill service is unavailable
    Given the KillBill API is unavailable
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags
    Then the response status code should be 503
    And the response body should contain an error message indicating service unavailable

    @TC11
    Scenario: Attempt to remove tags with extra unexpected query parameters
    Given a bundle exists with id <valid_bundleId>
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags with extra query parameter foo=bar
    Then the response status code should be 204
    And the response body should be empty

    @TC12
    Scenario: Attempt to remove tags with a very large number of tagDef parameters
    Given a bundle exists with id <valid_bundleId> and has 1000 tags
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags with tagDef set to all 1000 tag UUIDs
    Then the response status code should be 204
    And all tags should be removed from the bundle
    And the response body should be empty

    @TC13
    Scenario: Attempt to remove tags with partial tagDef values (some valid, some invalid)
    Given a bundle exists with id <valid_bundleId> and has tags <tagDef1>, <tagDef2>
    And the tagDef query parameters are set to <tagDef1> and <invalid_tagDef>
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags
    Then the response status code should be 400
    And the response body should contain an error message indicating invalid tagDef

    @TC14
    Scenario: Attempt to remove tags with XSS or injection in headers
    Given a bundle exists with id <valid_bundleId>
    And the X-Killbill-Comment header contains a script tag or SQL injection string
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags
    Then the response status code should be 400 or 422
    And the response body should contain an error message indicating invalid header value

    @TC15
    Scenario: Performance under concurrent DELETE requests
    Given a bundle exists with id <valid_bundleId> and has multiple tags
    When 100 concurrent DELETE requests are sent to /1.0/kb/bundles/<valid_bundleId>/tags with valid parameters
    Then all responses should have status code 204
    And all tags should be removed from the bundle
    And no data corruption or race conditions should occur

    @TC16
    Scenario: Regression - previously fixed bug where tags were not removed if tagDef was empty array
    Given a bundle exists with id <valid_bundleId> and has tags <tagDef1>, <tagDef2>
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags with tagDef as an empty array
    Then the response status code should be 204
    And all tags should be removed from the bundle
    And the response body should be empty

    @TC17
    Scenario: Integration - verify data consistency after tag removal
    Given a bundle exists with id <valid_bundleId> and has tags <tagDef1>, <tagDef2>
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags with tagDef=<tagDef1>
    Then the response status code should be 204
    And tag <tagDef1> should be removed from the bundle
    And querying the bundle via GET /1.0/kb/bundles/<valid_bundleId> should confirm only <tagDef2> remains

    @TC18
    Scenario: Timeout when removing tags from a bundle with extremely large number of tags
    Given a bundle exists with id <valid_bundleId> and has 10000 tags
    When the user sends a DELETE request to /1.0/kb/bundles/<valid_bundleId>/tags
    Then the response status code should be 504 if operation times out
    Or 204 if operation completes within acceptable time
    And the response body should be empty

    @TC19
    Scenario: Accessibility - ensure error responses are readable by screen readers (if UI involved)
    Given an error response is generated for invalid input
    When the error response is rendered in the UI
    Then the error message should be accessible to screen readers
    And should comply with WCAG standards