---
name: add-screen
description: Builds a Market List page or bottom sheet: the files, route, state holder wiring, loading, error and empty states, accessibility labels, and widget tests. Use when building or changing a screen to match PRD section 6.
---

# Add a screen

Use this for each screen in `docs/PRD.md` section 6 (6.0 to 6.4). A state holder is a Bloc or a Cubit.

Mistake it prevents: showing the empty state while data loads, overflowing at 320 dp, leaving out semantic labels, or wiring a holder with the wrong scope.

## Inputs

- The screen's entry in PRD section 6: purpose, UI elements, and its empty, loading, and error states.
- The screen's state holders in PRD section 10.1 and their transitions in sections 10.2 to 10.6.

## Pick the form first

| The surface is | Build | Where | Route |
| --- | --- | --- | --- |
| A screen (`/`, `/settings`, `/list`, `/item-form`) | A page | `features/<feature>/presentation/pages/` | Yes |
| The first-run sheet or the share sheet | A widget shown with `showModalBottomSheet` | `features/<feature>/presentation/widgets/` | No |
| A confirm | An `AlertDialog` | `features/<feature>/presentation/widgets/` | No |

## Steps

1. Read the inputs. Copy labels and empty messages from the PRD entry. Put its error messages in `presentation/failure_messages.dart`.
2. Create the files listed for that screen in PRD section 9.1. If a widget needs a file the tree does not list, ask the user.
3. For a page, add its route name and argument class to `lib/core/router/app_router.dart`.
4. Provide the state holders. A screen with two holders in PRD 10.1 provides both. Pass the route arguments to the holder's constructor. `SettingsCubit` is the root instance and is already provided at the app root, so do not create another. The Settings screen reads it. The Lists screen reads its state for the default currency (AGENTS.md, Import rules). Every other holder is built per screen.
5. Render every status the holder defines in PRD sections 10.2 to 10.6. Match each to the screen's PRD section 6 entry. Lists and List Detail show Retry on failure. The Item Form, Settings, and first-run sheet show a message and stay open. Rebuild only what changes with `BlocSelector` or `buildWhen` (PRD 10.7). Handle one-time effects as set out in AGENTS.md (State and routes).
6. Add a tooltip and a semantic label to every icon button. List Detail item rows use the label format in PRD NFR-012.
7. Write widget tests in `test/features/<feature>/presentation/`:
   - each state the screen has
   - 320 x 568 dp
   - text scale 2.0
   - the tap-target guideline
   - each icon button, found by its tooltip
   - the NFR-012 label on List Detail item rows

   Then run the milestone's Verify command from PRD section 15.

## References

- `AGENTS.md`: State and routes, UI rules, Import rules.
- `analysis_options.yaml`: package imports and `const` constructors.
- `test/architecture_test.dart`: pages reach other pages only through `core/router`.
- `.agents/rules/protected-files.md`: do not skip or delete tests.
- `docs/PRD.md`: sections 5 (NFR-009 to NFR-012), 6, 7, 9.1, 10.
