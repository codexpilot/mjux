# MJUX documentation

MJUX is a Flutter package for reusable interfaces. The `0.1.0` prototype
implements `FormEditor1` and opens independent surfaces in a consuming app.
The package can be used as a local dependency for evaluation.

| Folder | Purpose | Current status |
| --- | --- | --- |
| [architecture](architecture/README.md) | Goals, terminology, principles, and boundaries that guide development. | Initial direction. |
| [plan](plan/README.md) | Working plan, priorities, open decisions, and acceptance criteria. | Form editor prototype in place. |
| [feature](feature/README.md) | Record of functionality completed from the plan. | Independent form surfaces with host-owned saving. |
| [api](api/README.md) | Documentation for the current implemented API available to consuming apps. | `FormEditor1`, `Utility`, `Surface`, and `SurfaceView`. |

## Documentation workflow

1. Record the purpose, rules, and boundaries in architecture documentation.
2. Track planned work and acceptance criteria in the working plan.
3. When a feature is implemented and verified, record its delivered behavior in
   the feature documentation and update its status in the plan.
4. Document the public API that actually exists in the relevant release or
   current repository stage. Update the API documentation when it changes.

Design ideas and illustrative examples belong in architecture or plan until
they are implemented. Feature and API documentation must describe the
implemented behavior, with limitations and the applicable version or commit.

The [original development guideline](mjux-development-guideline.md) provides
historical context. The [current architecture](architecture/README.md) places
Storyboard within Catalog alongside Form, Workspace, and Collection, and
calls the runtime Utility.
