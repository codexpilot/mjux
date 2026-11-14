# JSON UI Landscape Analysis

**Date:** 2026-01-23  
**Status:** Research complete  
**Relates to:** [MJUX Permanent Strategy](mjux-permanent-strategy.md)

## Executive Summary

This analysis surveys **Vercel json-render** (AI-constrained generation), **A2UI** (agent-to-UI streaming protocol), and **JsonUI** (data-driven React runtime). Their use of defined catalogs, validation, and controlled interactions offers ideas for MJUX's architecture. MJUX's current direction borrows design principles from A2UI. Protocol integration is optional future work and is not a committed deliverable.

## The Three Approaches

### 1. Vercel json-render — AI-Constrained Component Generation

**Source:** [json-render.dev](https://json-render.dev/) | [InfoQ coverage](https://www.infoq.com/news/2026/03/vercel-json-render/)

**Core Concept:** LLMs generate JSON specifications constrained to a predefined component catalog using Zod schemas. The catalog acts as the primary defense against hallucination.

**Architecture:**
```typescript
import { defineCatalog } from '@json-render/core';
import { z } from 'zod';

const catalog = defineCatalog(schema, {
  components: {
    Card: {
      props: z.object({ title: z.string() }),
      slots: ["default"],
      description: "A card container"
    },
    Metric: {
      props: z.object({
        label: z.string(),
        value: z.union([z.string(), z.number()]),
        format: z.enum(["currency", "percent", "number"]).nullable()
      })
    }
  },
  actions: {
    export_report: { description: "Export dashboard to PDF" }
  }
});
```

**Key Features:**
- **Streaming progressive rendering** as JSON arrives
- **Cross-platform:** React, Vue, Svelte, Solid (web), React Native (mobile) from same catalog
- **36 pre-built shadcn/ui components** ready to use
- **Zod-based validation:** Every prop tightly constrained, bounded strings, explicit enums, capped arrays
- **No arbitrary code execution:** AI generates only declarative JSON

**Security Model:**
> "Every prop should be as tightly constrained as possible... The tighter the constraints, the more predictable" — [OrchestKit docs](https://orchestkit.dev/docs/reference/skills/json-render-catalog)

**Design Philosophy:**
> "Instead of having the model generate arbitrary code, you let it generate structured JSON that maps to a predefined set of components. You control which components exist, what props they accept, and how interactions flow through the system." — [LogRocket](https://blog.logrocket.com/vercel-json-render-dynamic-ui/)

### 2. A2UI — Agent-to-UI Streaming Protocol

**Source:** [a2ui.org](https://a2ui.org/) | [GitHub](https://github.com/a2ui-project/a2ui) | [pub.dev/a2ui_flutter](https://pub.dev/packages/a2ui_flutter)

**Core Concept:** Open standard for agents to "speak UI" via declarative JSON streams. Multi-platform renderers (React, Angular, Lit, Flutter, SwiftUI, Jetpack Compose) render native components from the same protocol.

**Protocol Versions:**
- **v1.0** (current): Streaming protocol with `createSurface`, `updateComponents`, `updateDataModel`, and `deleteSurface`
- **v0.9/v0.9.1** (legacy): Previous surface model
- **v0.8** (legacy): Original specification

**v1.0 Basic Catalog Components:**

| Category | Components |
|----------|------------|
| **Layout** | Row, Column, List, Card, Tabs, Modal, Divider |
| **Display** | Text, Image, Icon, Video, AudioPlayer |
| **Input** | Button, TextField, CheckBox, ChoicePicker, Slider, DateTimeInput |

[Source: A2UI v1.0 Basic Catalog](https://a2ui.org/specification/v1.0-basic-catalog-implementation-guide/)

**Architecture:**
```
Agent (Server) → JSON Stream → A2UI Core → Framework Adapter → Widget Catalog → Native UI
```

**Message Flow:** See the [A2UI message reference](https://a2ui.org/concepts/messages/) for version-specific examples and semantics.

**Flutter Implementation:**
- **Package:** `a2ui_flutter` renders A2UI protocol v1.0 and v0.9
- **Architecture:** `a2ui_core` (message processor) + `a2ui_flutter` (widget adapter) + catalog
- **Custom components:** Pair JSON schema with widget builder, register in app's catalog
- **Basic catalog included:** Standard components out of the box

**Real-World Example:**
> "In our implementation, we built a catalog of 56 components covering metrics, charts, lists, traceability views and analytics dashboards. Each component is designed as a reusable, production-ready building block that can be composed in different contexts." — [ICS Flutter A2UI blog](https://www.ics.com/blog/mastering-generative-ui-flutter-a2ui)

**Security Model:**
> "A2UI treats all external agents as potentially malicious... It operates on three principles:
> 1. Declarative data format: Pure JSON, no executable code, no JavaScript, no HTML injection
> 2. Component catalog whitelisting: Agents can only request pre-approved components
> 3. Safe validation: Components validate all inputs before rendering"
> — [Grid Dynamics](https://www.griddynamics.com/blog/ai-agent-for-ui-a2ui)

**Design Philosophy:**
> "Agents send a declarative JSON format describing the intent of the UI. The client application then renders this using its own native component library" — [A2UI GitHub](https://github.com/a2ui-project/a2ui)

### 3. JsonUI — Data-Driven React Runtime

**Source:** [jsonui.org](https://www.jsonui.org/)

**Core Concept:** JSON-based, data-driven UI runtime for React (web). UI model defines component tree, data bindings, validation rules, and event behavior in one place. When model changes, rendered UI follows immediately.

**Architecture:**
```javascript
import { JsonUI } from '@jsonui/react';

const model = {
  $comp: 'View',
  $children: [
    { $comp: 'Text', $children: 'Hello JSONUI' },
    {
      $comp: 'Edit',
      store: 'data',
      path: '/profile/firstName',
      label: 'First name'
    }
  ]
};

export function Example() {
  return <JsonUI model={model} />;
}
```

**Key Features:**
- **Reactive data binding:** Store updates trigger immediate UI updates
- **Component specifications:** Define custom components with schemas
- **Validation rules** embedded in model
- **Event behavior** declared in JSON
- **React Native planned** (currently React web only)

**Design Philosophy:**
> "The UI model defines component tree, data bindings, validation rules, and event behavior in one place" — [jsonui.org](https://www.jsonui.org/)

## Comparative Analysis

### Shared Security Model: The Catalog Constraint

All three approaches converge on the same security architecture:

1. **Pre-approved component catalog** (whitelist)
2. **Typed props/schema validation** (Zod, JSON Schema)
3. **No arbitrary code execution** (declarative JSON only)
4. **Framework-native rendering** (not DOM string injection)

MJUX also has a Catalog boundary:

```
External Request → Catalog Items Only → Core Components (internal) → Native Widgets
```

### Differentiation Matrix

| Aspect | json-render | A2UI | JsonUI | MJUX |
|--------|-------------|------|--------|------|
| **Primary Use Case** | AI generative UI | Agent streaming UI | Data-driven apps | Enterprise app UI |
| **Protocol** | JSON (one-shot or streaming) | JSON streaming | JSON model | Dart API |
| **Platform Support** | React, Vue, Svelte, Solid, RN | React, Angular, Lit, Flutter, SwiftUI, Compose | React (RN planned) | Flutter |
| **Schema System** | Zod | JSON Schema | Custom | Dart types |
| **Component Model** | Props + slots | Props + children + paths | Props + bindings | Config + initial values |
| **State Management** | Actions | Agent-driven updates | Store + paths | Surface state per instance |
| **Versioning** | Catalog-level | Protocol versions (v0.8, v0.9, v1.0) | Not specified | Planned |
| **Flutter Support** | ✅ React Native | ✅ Native (`a2ui_flutter`) | ❌ (planned RN) | ✅ Core strength |
| **Maturity** | New (2026) | Active (v1.0 released) | Active | Prototype |

### A2UI and MJUX Design Principles

A2UI and MJUX both use defined UI building blocks and separate reusable
specifications from running surfaces. A2UI also illustrates how to document
validation, bindings, lifecycle, and events at the boundary of a UI system.
These are useful references for MJUX's Dart API and Catalog design.

A2UI components and MJUX Catalog items operate at different levels of
composition. A2UI paths and MJUX's identity-based `FieldKey` also have
different representations. Any future integration would need an explicit
mapping, a supported catalog and version, and tests of observable behavior.

## Implications for MJUX

MJUX's permanent status justifies investment in its Catalog and Core backlog.
Prioritize components according to consumer workflows and develop the Dart API
as the primary interface. Apply the following principles from the research:

- Define supported Catalog items, inputs, interactions, and lifecycle behavior.
- Validate configuration and route actions through host-approved operations.
- Keep each surface's state independent and define host refresh and save behavior.
- Version observable contracts and document compatibility across releases.
- Keep domain rules, authorization, and persistence with the host.

A2UI integration remains an option if a concrete use case arises. The current
strategy has no adapter, conformance, or A2UI catalog deliverable. A future
evaluation can examine existing Flutter SDKs, the MJUX Catalog boundary, and
the protocol and data contracts required by the use case.

## Sources

- [Vercel json-render Documentation](https://json-render.dev/docs)
- [InfoQ: Vercel Releases JSON-Render](https://www.infoq.com/news/2026/03/vercel-json-render/)
- [LogRocket: Vercel's JSON Render](https://blog.logrocket.com/vercel-json-render-dynamic-ui/)
- [A2UI v1.0 Protocol Specification](https://a2ui.org/specification/v1.0-a2ui/)
- [A2UI v1.0 Basic Catalog Guide](https://a2ui.org/specification/v1.0-basic-catalog-implementation-guide/)
- [a2ui_flutter package](https://pub.dev/packages/a2ui_flutter)
- [ICS: Mastering Generative UI in Flutter with A2UI](https://www.ics.com/blog/mastering-generative-ui-flutter-a2ui)
- [Grid Dynamics: AI agent for UI design](https://www.griddynamics.com/blog/ai-agent-for-ui-a2ui)
- [JsonUI.org](https://www.jsonui.org/)
- [OrchestKit: Json Render Catalog](https://orchestkit.dev/docs/reference/skills/json-render-catalog)
- [Medium: A2UI Components Explained](https://medium.com/@visrow/a2ui-components-explained-building-agent-driven-user-interfaces-with-a-declarative-protocol-8f413167c1a9)
- [DEV: A2UI 1.0 in Next.js](https://dev.to/zforzain2000/a2ui-10-in-nextjs-the-deep-dive-and-your-first-agent-screen-43kk)
