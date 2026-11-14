# Material UI component gaps for consumer apps

## Prioritized Core component backlog

This is a backlog for MJUX on Flutter **3.50.0 or later** and the standalone
`material_ui` package. The comparison uses `material_ui` 1.11.0. Each row
names reusable behavior to develop in Core. Use existing controls as building
blocks and add the missing behavior once, behind the public Catalog items.
The proposed order starts with capabilities shared across the most workflows.
A consumer's first release can move a workflow-specific item earlier.
[Material UI package and API catalog][material]

| Order | Component gap | What MJUX Core will develop | Example consumers |
| --- | --- | --- | --- |
| 1 | **Searchable combobox** | Provide local and asynchronous record selection with typed identities, distinct query and selected value, disambiguating result details, keyboard navigation, and loading, empty, retry and clear states. [Combobox contract](#combobox-contract) | EMR, EHR and ERP lookups, plus CRM, POS and chat recipients |
| 2 | **Configurable record table and filter bar** | Add a column chooser with show/hide and column reordering, alongside host-driven paging, sorting, filtering and stable row selection. Start with `PaginatedDataTable` where it meets the workflow. [Column contract](#table-column-contract) | ERP inventory, clinical record lists, POS transactions, CRM contacts |
| 3 | **Typed form fields and validation feedback** | Add exact decimal, money, quantity and large-integer entry using Material text fields. Distinguish date-only values, local times and instants in typed bindings for existing pickers. Support locale-aware entry, intermediate drafts, units, host field errors and accessible error navigation in Form. | ERP, POS, EMR, EHR, CRM |
| 4 | **Responsive panel layout** | Develop a reusable panel layout that can show content side by side on wide screens and one pane at a time on narrow screens. Supply sizing, resizing and focus behavior as needed. The master–detail Storyboard coordinates record selection and navigation. | ERP, EMR, EHR, CRM, chat |
| 5 | **Editable line items and advanced grid** | Start with quantity and price editors, row add/remove and accessible validation. Add keyboard cell navigation, batch edits and pinned rows or columns as needed. Evaluate `TableView` for lazy two-axis rendering before building a viewport. [TableView][table-view] | ERP orders, POS carts, clinical orders |
| 6 | **Attachment field and preview** | Provide a generic attachment list, progress, retry, remove, and preview for supported types. Delegate file selection, capture, storage and access to the host. | ERP documents, clinical records, CRM, chat |
| 7 | **Activity timeline and record context** | Render chronological entries with date grouping, status, expandable details and paged history. Reuse a lazy Flutter list. Provide a record header that can stay visible and show the current identity, status and source supplied by the host. | Clinical history, ERP transaction history, CRM activity |
| 8 | **Appointment and resource schedule** | Render agenda or calendar views and host-supplied slots or events. Expose date navigation, selection and edit intents. Add resource lanes and recurrence display when needed. | EMR and EHR appointments, CRM meetings, ERP resource planning |
| 9 | **Transaction controls** | Add touch-friendly quantity and amount entry, a scan-input status display, and reusable views for host-supplied totals and transaction outcomes. Use them in checkout and receipt review compositions. | POS checkout and refunds, ERP order review |
| 10 | **Message history and composer** | Add grouped message rows, multiline drafts, reply context, unread indicators, attachments and pending or failed sends with retry. Preserve scroll position when loading older messages or receiving new ones. | Chat, CRM messaging, support |
| 11 | **Structured note editor** | Use multiline plain text for the first simple flow. Add rich editing, sections or inline content only where a consumer needs them. Keep draft, validation and host-controlled read-only behavior consistent with other editors. | EMR/EHR notes, CRM notes, chat composition when applicable |
| 12 | **Chart and report views** | Add chart rendering, accessible summaries and interaction when reporting workflows require them. Reuse table and date-range controls. Export and printing can be host actions. | ERP reports, POS analytics, clinical trends, CRM reporting |
| 13 | **Board view** | Present grouped records, selection and move requests with a keyboard-accessible alternative to drag and drop. The host supplies allowed transitions. | CRM pipeline, ERP work queues |

Items 1–4 form a practical first delivery for record workflows. They can be
exercised together by opening a paged list, finding a record with a lookup,
editing it, and showing the result of a save. Item 5 becomes an earlier
requirement for a consumer that starts with order entry or POS.

## Combobox contract

This is a high-priority Core component for EMR, EHR and ERP. Form Catalog
items expose its field configuration. Collection items can reuse it for
filters and editable cells. Its implementation can reuse Material's
`Autocomplete` and menu primitives. [Autocomplete][autocomplete]

- Support a supplied local option list and a host-provided asynchronous search.
  Keep the selected record's typed identity separate from its display label
  and the current query text. Show secondary details to distinguish records
  with the same label.
- Support opening the choices, typing to filter, keyboard selection, Escape
  to dismiss, and optional clearing. Define selection-only behavior first.
  Decide free-text entry and multi-selection as explicit extensions.
- Show loading, no results, failure and retry states. Ignore obsolete search
  results after a new query or surface disposal. Preserve the selected value
  when it falls outside the currently loaded options.
- Accept required, disabled, read-only and host validation states. Keep
  database queries, terminology rules and authorization in the host.

Acceptance includes duplicate labels with different identities, rapid typing
with responses arriving out of order, clearing an optional value, keyboard
selection, and preserving the selected identity across result refreshes.

## Table column contract

Column visibility and order are part of the first Collection table contract.
Core provides the column chooser and reordering behavior. Utility owns the
current view state and emits preference changes for host persistence.

- Give each column a stable typed identity. Apply one ordered visible-column
  list to both headers and cells. Sorting, filtering and edits address the
  column identity even after it moves.
- Let users show and hide optional columns through a column chooser. Allow
  Catalog configuration to declare essential columns and define a usable
  empty state when every optional column is hidden.
- Allow column rearrangement using drag and drop and keyboard-accessible
  move controls. Restoring a hidden column should retain its configured order.
- Accept initial visibility and ordering from the host, emit changes, and
  offer reset to the Catalog defaults. The host maps typed identities to
  persisted keys and stores preferences per user and view.
- Reconcile restored preferences with the current column definitions by
  dropping removed identities and placing newly added columns deterministically.

Acceptance includes hiding and restoring a column, moving a sorted column,
matching header/cell order after every change, preserving row selection and
draft edits, and restoring preferences after column definitions change.

## What Material already supplies

- **Controls and layout:** Use Material forms, text fields, menus, selection
  controls, buttons, dialogs, progress indicators, search surfaces and
  navigation. Apply the host's theme and localization and verify the composed
  UI with keyboard, touch, text scaling and screen readers. [Material UI
  package and API catalog][material]
- **Tabular display:** `DataTable` supports selectable rows and sorting hooks.
  `PaginatedDataTable` reads rows through `DataTableSource` and supplies page
  controls. MJUX adds the host request and UI state contract. Measure large
  and wide tables on the target devices. The package documents the cost of
  laying out large `DataTable` instances. [DataTable][table] ·
  [PaginatedDataTable][paged]
- **Search and date selection:** `Autocomplete` already accepts a caller's
  options builder, including asynchronous options. Date, date-range and time
  pickers can supply date inputs. The backlog covers the reusable lookup
  behavior and appointment presentation on top of those primitives.
  [Autocomplete][autocomplete] · [Date range picker][dates] ·
  [Time picker][time]
- **Lists:** Flutter's `ListView.builder` already builds items on demand.
  Reuse it for record lists, activity and messages. Paging state and
  history scroll behavior belong in the relevant composition.
  [ListView.builder][list]
- **Companion packages:** Flutter's `two_dimensional_scrollables` provides a
  `TableView` with lazy cell creation and pinned rows and columns. It can
  supply the viewport for a dense sheet. A host can use `file_selector` for
  native file dialogs and pass the results to an attachment component.
  Evaluate `material_layout` for adaptive and resizable panes before writing
  a split layout. [TableView][table-view] · [File selector][files] ·
  [Material layout][layout]

## Coverage by consumer workflow

Consumer apps compose the generic Catalog items and supply the domain labels,
configuration, data and actions. The examples below scope the gaps and can
serve as workflow fixtures.

| Consumer | First workflows to exercise | Host responsibilities |
| --- | --- | --- |
| **ERP** | Search and filter inventory, edit a record, enter order lines, review totals, and view reports. [Odoo purchase orders][erp] | Inventory and accounting rules, approvals, document generation and integrations. |
| **POS** | Find an item by search or scan, edit the cart, review totals, request payment, and show receipt or refund status. [Odoo POS][pos] | Scanner, terminal, cash drawer and printer adapters. Pricing, tax, discounts, payment confirmation and offline reconciliation. |
| **EMR** | Find and verify a patient, open encounter history, document a visit, and review proposed orders or appointments. [OpenMRS patient chart][emr] | Patient identity, clinical validation, terminology, order workflow, booking rules and audit records. |
| **EHR** | Review longitudinal history, grouped results and trends, and imported records or documents. [OpenMRS modules][ehr] | Authorization, patient and record matching, interoperability, data provenance and audit records. |
| **CRM** | Find a contact, edit a record, log activity and review opportunities. Add a board or scheduler if the workflow uses it. [Dynamics 365 activities][crm] | Access, activity persistence, scheduling, lead assignment and pipeline rules. |
| **Chat** | Open a conversation, page older messages, compose and send, and handle an attachment or failed send. [Mattermost messaging][chat] · [Slack history][history] | Transport, message storage, upload permissions and delivery state. |

## Placement in MJUX

- **Core** develops the missing reusable components listed above. Reuse
  `material_ui` and Flutter primitives inside each component where they cover
  the required behavior. Keep Core types internal to MJUX.
- **Catalog** exposes generic items through four subdivisions. Document each
  item's configuration, states and events. The consuming app assembles its
  domain workflows.
- **Utility** owns surface lifecycle and interaction state. Define the
  relevant host update and event contracts for each item. The consumer
  performs queries and operations and supplies results. The current
  `FormEditor1` prototype provides text and choice fields with host-owned
  saving. [Prototype feature record](../feature/README.md)

| Catalog subdivision | First backlog items it serves | Further examples |
| --- | --- | --- |
| [Form][subdivisions] | Searchable combobox, typed form fields and validation | Attachment field, structured note editor, transaction inputs |
| [Workspace][workspace] | Mobile and Desktop/Tablet screen scaffolds and composition | Single-region mobile record browser, desktop or tablet workspace with a toolbar and room for supporting panes |
| Collection | Table with show/hide, column order, paging and filters | Sheet and editable line items, list and grid views, activity timeline, agenda, message history, board |
| Storyboard | Responsive master–detail arrangement | Split panel and multipanel arrangements for coordinating collections, forms and related content |

The same gap can support more than one subdivision. For example, a record
browsing screen uses a Workspace scaffold around a master–detail Storyboard,
with a Collection table and a Form editor as its panes.

Accept a gap as covered when a consumer can exercise it through Catalog and
Utility using representative data and failure cases. For the first record
workflow, verify stale lookup responses, page and selection changes, decimal
and large-integer round trips, and save rejection without losing edits. Add
the applicable keyboard, accessibility, layout and performance checks for
each supported platform.
[Flutter accessibility testing][accessibility]

[material]: https://pub.dev/packages/material_ui
[table]: https://pub.dev/documentation/material_ui/latest/material_ui/DataTable-class.html
[paged]: https://pub.dev/documentation/material_ui/latest/material_ui/PaginatedDataTable-class.html
[autocomplete]: https://pub.dev/documentation/material_ui/latest/material_ui/Autocomplete-class.html
[dates]: https://pub.dev/documentation/material_ui/latest/material_ui/showDateRangePicker.html
[time]: https://pub.dev/documentation/material_ui/latest/material_ui/showTimePicker.html
[list]: https://api.flutter.dev/flutter/widgets/ListView/ListView.builder.html
[table-view]: https://pub.dev/documentation/two_dimensional_scrollables/latest/two_dimensional_scrollables/TableView-class.html
[files]: https://pub.dev/packages/file_selector
[layout]: https://pub.dev/documentation/material_layout/latest/
[erp]: https://github.com/odoo/documentation/blob/19.0/content/applications/inventory_and_mrp/purchase/manage_deals/rfq.rst
[pos]: https://github.com/odoo/documentation/blob/19.0/content/applications/sales/point_of_sale/use.rst
[emr]: https://o3-docs.openmrs.org/en-US/docs/configure-o3/configure-the-patient-chart/
[ehr]: https://o3-docs.openmrs.org/en-US/docs/key-repositories/
[crm]: https://learn.microsoft.com/en-us/dynamics365/sales/manage-activities
[chat]: https://docs.mattermost.com/end-user-guide/collaborate/communicate-with-messages
[history]: https://docs.slack.dev/reference/methods/conversations.history/
[accessibility]: https://docs.flutter.dev/ui/accessibility/accessibility-testing
[subdivisions]: ../architecture/README.md#catalog-subdivisions
[workspace]: ../architecture/README.md#workspace-variants
