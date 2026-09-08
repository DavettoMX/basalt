Feature: <feature name>
  As a <role>
  I want <goal>
  So that <benefit>

  Scenario: <scenario name>
    Given <precondition>
    When <action>
    Then <expected outcome>

  # Add scenarios. These are VISIBLE (it's the spec). Step DEFINITIONS live in
  # qa/hidden/steps/<domain>/ and are agent deny-read. A spec fails the verdict
  # if any scenario's steps fail — but the agent never sees the steps or their
  # assertion details.