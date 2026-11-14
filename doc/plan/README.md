# Development plan

This is the working plan for MJUX, a Flutter package consumed by other Flutter
apps. Update the status and scope as decisions are made and work progresses.

The [architecture](../architecture/README.md) records the goals and rules.
Document completed work in [feature](../feature/README.md), and document only
currently available consumer APIs in [api](../api/README.md). The earlier
[development guideline](../mjux-development-guideline.md) provides background.
The current [Catalog subdivisions](../architecture/README.md#catalog-subdivisions)
are Form, Workspace, Collection, and Storyboard. Storyboard is a subdivision
of Catalog for panel layouts. Utility is the runtime.

The [Material UI component gap analysis](material-ui-component-gaps.md)
orders the component backlog for ERP, POS, EMR, EHR, CRM, and chat apps.

## Status

- The `0.1.0` prototype exercises a generic form editor through the Catalog,
  with independent state for each surface. [Feature record](../feature/README.md) ·
  [API reference](../api/README.md)
- **Status labels:** Planned, in progress, completed, or blocked. Add a short
  reason and next step when marking work blocked.

## Review follow-up — Open

The review on 2026-11-14 reproduced an overflow when a ten-field `FormEditor1`
is mounted directly in `Scaffold.body` at 800 by 600. Core's Panel uses a
plain Column, which leaves the lower fields and Save action beyond the
viewport. Establish the scrolling contract at the Surface/Catalog boundary
and verify long forms, short windows and keyboard-reduced space. Keep nested
use inside an existing scrolling Workspace supported.

## 1. Define the first contract — In progress

The prototype accepts typed `FormEditor1` configuration with text and choice
fields, required-field validation, and save snapshots. It uses object identity
for field keys and preserves omitted keys and explicit nulls in value maps.
Numeric field types, contract versioning, and the host update API remain open.

- Define `FormEditor1` as a generic Catalog item, independent of any business
  entity. Specify field configuration, initial values, validation feedback,
  supported actions and host-facing events.
- Specify type-based Dart registration and selection for Catalog items, with
  internal Core registration. Do not require callers to use string identifiers
  or an `mjux` prefix.
- Define how a consuming app creates, observes, updates and disposes a surface.
  Describe errors for unsupported items, invalid configuration and invalid
  updates.
- Decide the behavior of missing values, explicit nulls, and deletion. Preserve
  decimal and large-integer precision where applicable.
- Write representative contract examples and acceptance criteria before
  implementation. Keep illustrative APIs clearly labeled as proposals.

**Acceptance:** A reader can describe the generic form's inputs, interactions,
outputs and lifecycle without needing a domain-specific form or a Core component
in the consuming app.

## 2. Establish the Flutter package and Core — In progress

The package exports Catalog and Utility APIs. The internal type-based Core
registry uses `material_ui` widgets. The supported platforms and accessibility,
localization, and theming baseline remain open.

- Set up the Flutter package, its public exports and an example consuming app.
- Use the internal type-based registry to assemble Material controls and new
  Core components. The first form already uses Material text input, selection,
  buttons, and containers.
- Develop the missing reusable components and extensions from the
  [Core backlog](material-ui-component-gaps.md#prioritized-core-component-backlog).
  Prioritize the [searchable combobox](material-ui-component-gaps.md#combobox-contract)
  for EMR, EHR and ERP and the
  [table column controls](material-ui-component-gaps.md#table-column-contract)
  for show/hide and rearrangement. Add exact numeric fields and host validation
  feedback in `FormEditor1` as part of the shared record workflow.
  For each gap, record which primitives it reuses and what behavior Core adds.
  Exercise it through the first Catalog item that needs it.
- Keep Core registration and individual Core components out of the supported
  consumer-facing API and any external protocol adapter.
- Define an accessibility, localization, theming and responsive-layout baseline
  for the target platforms.

**Acceptance:** The example app can depend on the package without importing
internal Core components; the required Core behavior is verified in isolation.

## 3. Build Catalog and Utility — In progress

`Utility.open` accepts `FormEditor1` directly. Each surface tracks its draft
and last saved values. Save results apply to the request snapshot, preserving
later edits. Disposal prevents a pending result from updating the surface.
Catalog lookup across multiple items and host refresh behavior remain planned.

- Implement a type-based Catalog registry with items organized under Form,
  Workspace, Collection, and Storyboard. Start with `FormEditor1` using Core.
  An app selects the generic Catalog item and supplies its fields and data.
- Define [Mobile and Desktop/Tablet Workspace variants](../architecture/README.md#workspace-variants)
  for the same record workflow. Check that changing the window width preserves
  the selected record and any unsaved form edits.
- Create one Utility-managed surface per mounted instance, with independent
  values and interaction state. Track draft and original values, dirty and
  touched fields, validation feedback and pending, success or failure states as
  supported by the final contract.
- Route user actions through Utility, emit declared events to the host, and
  accept host responses. The host retains authorization, business rules,
  persistence and authoritative domain data.
- Define how external refresh interacts with unsaved edits, including active
  text selection and input composition. Define edits made during a save and
  ignore late results after disposal.
- Verify two simultaneous surfaces, successful and failed saves, invalid
  configuration, refresh during editing and disposal while work is pending.

**Acceptance:** A consumer app can use the generic form end to end without
access to Core. Two surfaces do not share state, and the agreed save and
refresh semantics have tests.

## 4. Prove integration and publish documentation — In progress

The example app uses the public package import to edit two inventory records.
It saves to an in-memory list and rejects duplicate names in the host callback.
Dataset integration and cross-platform verification remain planned.
[Example app](../../example/lib/main.dart)

- Exercise the form in a consuming app with representative metadata and data;
  evaluate Dataset integration once the generic contract is ready.
- Verify theme, localization, keyboard navigation, focus, screen-reader labels,
  text scaling and responsive layout on the supported target platforms.
- Document each completed behavior and its verification in the feature area.
  Add usage examples and API reference to the API area only when the API exists.
- Assess a shared contract and conformance fixtures for future Genux
  compatibility; do not assume implementation or migration is complete.

**Acceptance:** The documented consumer example runs against the current
package, and completed feature and API documentation match the implementation.

## External format principles

MJUX draws on A2UI's approach to declarative interfaces, registered components,
validated input, and host-controlled actions. Apply those principles through
MJUX's own Catalog and Utility contracts. The Dart API remains the primary
interface. See [MJUX Permanent Strategy](mjux-permanent-strategy.md) for the
strategic direction and [JSON UI Landscape Analysis](json-ui-landscape-analysis.md)
for background.

A2UI integration and other external format adapters are optional future
possibilities. No adapter, protocol conformance, or reference implementation is
scheduled in this plan. If a consumer need leads to a future adapter, define its
scope and compatibility separately. The adapter must preserve the Catalog-only
boundary, validate inputs, and route permitted actions through the host.

## Decisions still open

- Exact Dart interfaces, builder signatures, field identifiers and versioning.
- Whether and how external state stores are supported.
- Refresh and conflict policy for dirty forms, and save result correlation.
- Native Flutter target coverage beyond the macOS prototype. The SDK baseline
  is Flutter 3.50.0 and later, with the standalone `material_ui` package.
  Numeric validation targets native Dart execution.
- Whether a future consumer need warrants support for an external protocol.
- Scope and timing of Dataset and future Genux integration.

## Maintaining this plan

Mark a task complete only after implementation and appropriate verification.
Record completed behavior in the feature area, add consumer-facing usage in the
API area, and link back to the relevant plan item. Keep unfinished decisions and
follow-up work here; change the architecture documentation when a project rule
or goal changes.
