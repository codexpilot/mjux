# MJUX Permanent Strategy

**Original date:** 2026-01-23  
**Updated:** 2026-11-14  
**Status:** Strategic direction  
**Supersedes:** Original transitional Genux migration strategy

## Context

The [original development guideline](../mjux-development-guideline.md) proposed
MJUX as a transitional UI for Dataset while Genux developed its components.
MJUX is now a permanent Flutter UI package for Dataset and other consumers.
Its [Core component backlog](material-ui-component-gaps.md) is a long-term
investment, prioritized by the needs of actual workflows.

## Principles drawn from A2UI and other JSON UI systems

MJUX borrows design principles from A2UI and other JSON UI systems. Its own
architecture and consumer requirements determine how those principles apply.

- Provide a catalog of approved, generic interface definitions.
- Keep reusable implementation components internal to the package.
- Validate configuration and bindings at the public boundary.
- Separate a reusable definition from each running surface and its state.
- Express user actions as events that the host can authorize and handle.
- Leave business rules, persistence, and authoritative data with the host.
- Version observable contracts and preserve data meaning across boundaries.

The native Dart API is MJUX's primary interface. A2UI support is optional and
there is no current commitment to build an adapter, implement its Basic
Catalog, or claim protocol conformance. A future consumer need may justify a
separate evaluation. The [landscape analysis](json-ui-landscape-analysis.md)
provides background on these systems.

## Numeric precision

Exact decimal, money, quantity, and large-integer entry is a priority for
financial and clinical workflows. The contract should cover locale-aware
entry, intermediate drafts, scale and rounding, units, host validation, and
precision-preserving values across supported platforms. Entry text and stored
values have distinct responsibilities.

Define the public value types and ownership of any numeric dependency as part
of the first contract. The [AIX numeric integration plan](aix-numeric-integration.md)
records an architecture decision to use AIX Numeric. Its precision and platform
behavior still need verification against that contract.

## Relationship with Genux

MJUX and Genux can develop independently. If Dataset needs interchangeable
implementations, agree on a shared host-facing contract and verify the same
configuration, bindings, events, state, and lifecycle behavior against both.
Dataset must select the implementation through its integration. Compatibility
requires explicit design and verification.

## Strategic path

### Build the foundation

The [working plan](README.md) tracks current status and acceptance criteria.
The immediate work is to define the `FormEditor1` contract, resolve the
scrolling overflow, build Core priorities 1–4, and prove representative Dataset
workflows through the Dart API. Verify the first workflow in Dataset's actual
app shell, including theme and localization integration.

### Expand the Catalog

Use consumer workflows to prioritize the remaining Core backlog, including
editable line items, attachments, timelines, scheduling, transaction controls,
messaging, structured notes, reports, and board views. Develop reusable Core
behavior behind generic Catalog items, verify it through the Dart API, and
document completed behavior and acceptance tests.

An external format adapter may be considered when a concrete consumer needs
one. Such work would require a separate scope and decision, including its
supported protocol and Catalog, host-authorized actions, data exposure, and
compatibility tests.

## Architecture decision records

### ADR-001 — MJUX is permanent

MJUX is a long-term Flutter UI package for enterprise applications. Core and
Catalog work should support ongoing consumer needs and maintain documented
compatibility across releases.

### ADR-002 — Dart is the primary API

MJUX applies selected ideas from A2UI to its own design. Protocol integration,
including A2UI, is optional and requires a separate decision when a consumer
use case warrants it. The current development path uses the native Dart API.

### ADR-003 — Catalog is the external boundary

Consumers access generic Catalog and Utility contracts. Core components remain
internal implementation details. Any future protocol entry point must validate
its input, expose only approved Catalog items, and respect host authority over
actions and data. Catalog selection alone does not authorize an operation.

### ADR-004 — Numeric precision is a first-class feature

MJUX will support exact decimal, money, quantity, and large-integer fields as
part of its Catalog contracts. The numeric representation, dependency, input
semantics, and compatibility with Dataset remain to be settled and verified.

## Success metrics

These targets are planning goals. The working plan records actual status.

### Short-term (6 months)

- Dataset uses `FormEditor1` in a production workflow.
- Scrolling overflow is fixed and the contract versioning strategy is defined.
- Core priorities 1–4 are implemented and verified.

### Medium-term (12 months)

- Core priorities 5–8 are implemented.
- Dataset uses MJUX in at least three workflows, including form, table, and
  workspace use cases.
- Numeric precision is validated in production.

### Long-term (24 months)

- All 13 Core backlog priorities are complete.
- Dataset uses MJUX for a majority of its CRUD workflows.
- Shipped Catalog contracts maintain their documented compatibility.

## Open questions

1. What are the detailed decimal and numeric requirements, and who owns the
   reusable numeric implementation?
2. Which Dataset workflows should consume MJUX first, and on what timeline?
3. Does Dataset need interchangeability with Genux, and what shared host-facing
   behavior would that require?
4. Is there a concrete consumer need for an external format in the future?

## References

- [JSON UI landscape analysis](json-ui-landscape-analysis.md)
- [Core component backlog](material-ui-component-gaps.md)
- [Working plan](README.md)
- [Original development guideline](../mjux-development-guideline.md)
- [Architecture](../architecture/README.md)
