# tests — clean-pass

Last verified: 2026-06-01

<!-- NOTE: when this date is >90 days old Check 14 flips from PASS to a
staleness WARN. run-self-tests.sh deliberately does NOT assert on Check 14
for this fixture, so no yearly refresh is strictly required — but refreshing
keeps the fixture a true zero-noise baseline. -->

## Scenario 1: golden path

Lint a valid widget fixture. Expected: clean report, exit 0.

## Scenario 2: edge case

Lint an empty widget fixture. Expected: a warning is emitted.

## Scenario 3: error case

Lint a missing fixture file. Expected: readable error, non-zero exit.
