# Architecture

The form editor prototype exercises these principles. The API reference
describes the implemented interface. [Feature record](../feature/README.md) ·
[API reference](../api/README.md)

## Goal

MJUX is a Flutter package for applications that need reusable, configurable
interfaces. Its Catalog offers generic UI items assembled from internal Core
components. Utility creates and manages a running instance, including its
state and lifecycle. Dataset is an intended consuming application; the Catalog
must remain useful to other applications and must not contain customer-specific
or other domain-specific screens.

MJUX targets native Flutter applications on Flutter 3.50.0 and later.
Platform verification starts with macOS and expands to the native mobile
and desktop targets required by consumers. Flutter web is outside the
current project scope. Core uses the standalone
`material_ui` package for existing controls. Build a Core component when a
consumer workflow needs reusable behavior that the available controls do not
provide. Each gap records the primitives it can reuse and the behavior MJUX
needs to add. [Core component backlog](../plan/material-ui-component-gaps.md)

## Taxonomy

| Term | Meaning |
| --- | --- |
| **Core** | Internal reusable UI building blocks. Reuse Material controls and implement missing capabilities such as typed numeric input, editable line items, and resizable panels. |
| **Catalog** | The public collection of generic, reusable UI definitions, such as `FormEditor1` and `FormViewer1`. |
| **Catalog item** | One generic definition with a documented configuration, behavior, and events. Numeric suffixes identify variants, not versions. |
| **Utility** | The MJUX runtime responsible for creating and managing Catalog item instances, their state, bindings, actions, and lifecycle. |
| **Surface** | One running instance of a Catalog item. A definition can have multiple independent surfaces. |
| **Host** | The consuming Flutter application, which supplies data and handles application-specific operations. |

## Catalog subdivisions

| Subdivision | Scope | Item examples |
| --- | --- | --- |
| **Form** | View and edit a record or a set of fields, with validation and submit behavior. | Form editor, form viewer |
| **Workspace** | Provide the scaffold and composition for a whole screen. Define screen regions for navigation, actions, and content. | Scaffold, screen composition |
| **Collection** | Present or edit a set of records or values in a consistent view. | Table, sheet, list view, grid view |
| **Storyboard** | Arrange related content in panels and coordinate interactions across them. | Split panel, multipanel, master–detail |

### Workspace variants

| Variant | Scaffold and screen composition |
| --- | --- |
| **Mobile** | One primary content region at a time, compact navigation and actions, and touch-friendly controls. |
| **Desktop/Tablet** | Room for a navigation rail or sidebar, a screen toolbar, and wider content. Use available space for supporting panes and support touch, keyboard, and pointer input. |

Choose the variant from the available window size. A narrow tablet window or
resized desktop window can use the Mobile variant. Both variants can host the
same Catalog items, so resizing should preserve the active record and its
draft. A Storyboard decides which panes are visible and how they coordinate
when the available space changes.

A Workspace can place a Storyboard in its content region. For example, a
record-management Workspace can provide the screen toolbar and navigation. A
master–detail Storyboard can arrange a Collection table and a Form editor and
coordinate which record the editor displays.

The prototype implements `FormEditor1` in Form. The other subdivisions describe
the planned Catalog structure.

## Boundaries

```text
Flutter application or optional protocol adapter
                    │
                    ▼
           Catalog + Utility API
                    │
                    ▼
     Catalog item assembled from Core
                    │
                    ▼
          Surface and its state
```

- External applications and protocol adapters select **Catalog items only**.
  Core components are implementation details and are not exposed for external
  selection through MJUX's public registry or protocol adapters.
- A Catalog item defines a general presentation and interaction pattern. The
  host supplies its configuration, values, labels, and domain-specific behavior.
- Core owns component behavior. Catalog assembles Core components and
  coordinates them within the item. For example, Core implements a resizable
  panel layout and a paged table. A master–detail Storyboard uses them and
  connects the table's selected record to the detail pane.
- Utility manages each surface's interaction state and lifecycle. The host
  owns business rules, authorization, persistence, and authoritative application
  data. UI validation does not replace host validation.
- Catalog item definitions are reusable; their running state is not shared
  between surfaces by default. Disposing one surface must not affect another.
- Public APIs should expose supported Catalog and Utility contracts. Dart's
  `src` directory convention marks Core as internal. Enforce the Catalog-only
  boundary through the types accepted by public APIs and protocol entry points.

## Prototype structure

`lib/mjux.dart` exports the Catalog configuration, save events and results, and
Utility surface API. `Utility.open` accepts a `FormEditor1` directly. The item
uses an internal Core registry to resolve `material_ui` controls by Dart type.
The host app owns the save callback and disposes each surface it opens.

## Design principles

1. **Use typed Dart identities.** Registration and selection in the Dart API
   use types rather than string component or Catalog item IDs, with no `mjux`
   prefix in identifiers. A Core contract and its Flutter builder can remain
   separate so implementations can change without redefining the public item.
2. **Keep definitions separate from instances.** A Catalog item describes a
   reusable UI; each surface has its own values, interaction state, and lifetime.
3. **Make state ownership explicit.** An initial surface state is supplied by the
   host; Utility coordinates local interaction. Define how host updates,
   pending saves, unsaved edits, validation, and disposal interact before
   declaring a behavior stable.
4. **Expose intent, not domain implementations.** An item emits defined events
   such as a save request; the host chooses how to validate and persist it.
   External data does not gain authority to run arbitrary host code.
5. **Preserve data meaning.** Distinguish omitted values, explicit nulls, and
   removal where supported. Do not silently lose decimal precision or large
   integer values at integration boundaries.
6. **Validate at boundaries.** Reject unknown Catalog items, unsupported versions,
   invalid configuration, and invalid bindings with useful errors. Protocol
   adapters accept only supported Catalog items and explicitly permitted actions.
7. **Design for usable Flutter interfaces.** Catalog items should support the
   host's theme and localization and the relevant accessibility, keyboard,
   pointer, touch, text-scaling, and responsive-layout needs.
8. **Version observable contracts.** A Catalog item's variant name is separate
   from its contract version. Define compatibility for configuration, events,
   state transitions, and behavior before publishing an API.

## External formats

MJUX draws on principles from A2UI and other JSON UI systems, including
catalog-based composition, boundary validation, and host-controlled actions.
The native Dart API is the primary interface. JSON and A2UI integration are
optional future possibilities, with no adapter or conformance work currently
committed. A future adapter would need an explicit scope, approved Catalog
items, and compatibility tests before claiming support for a format.

## Questions to resolve

- What typed API should identify and configure Catalog items and their fields?
- What is the exact state and binding contract, including external refreshes,
  active text editing, save races, and late results after disposal?
- Which Utility APIs will be public, and should a host-owned state store be
  supported later?
- What versioning and compatibility rules will apply to Catalog items?
- Which external formats, including A2UI, will MJUX support and at what scope?

The [working plan](../plan/README.md) tracks implementation work. Completed
behavior belongs in [feature documentation](../feature/README.md), and only
available APIs belong in the [API documentation](../api/README.md).
