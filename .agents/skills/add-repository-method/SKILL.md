---
name: add-repository-method
description: Implements the data side of a Market List use case: the Drift DAO method, data source method, mapper, repository implementation, DI registration, and tests. Use when a domain repository method exists and needs its data layer, or when the PRD or the user changes a repository method.
---

# Add a repository method

Use this after the domain interface and use case exist. It builds the data side of that method.

Mistake it prevents: a repository that leaks a raw exception, skips the transaction or the parent-list `updated_at` touch, sums totals with a different formula in SQL, or is tested only on the success path.

## Inputs

- The repository interface method in `docs/PRD.md` section 9.4.
- The use case row in `docs/PRD.md` section 9.3. Read its Enforces column and the Failure mapping in AGENTS.md (Use cases and errors).

## Pick the DAO method type first

| The method is | Build |
| --- | --- |
| A stream of one list with its items | `ItemsDao.watchListWithItems(listId)`, one join query (PRD 9.5) |
| The Lists screen summaries | `ListsDao.watchSummaries()` with the SQL total formula in AGENTS.md (Money and data rules) |
| A one-shot read | A DAO method that returns a `Future` instead of a `Stream` |
| A list write or a settings write | One DAO method inside one transaction (AGENTS.md, Database lock) |
| Any item write, duplicate list, restore item, or complete onboarding | One transaction that covers every step (PRD 9.5) |

If the PRD does not name the data source for a multi-table write, stop and ask the user.

## Steps

1. Read the inputs. Pick the DAO method type from the table.
2. Write the DAO method in `lib/core/database/daos/` (`lists_dao.dart`, `items_dao.dart`, or `settings_dao.dart`). For any schema question, follow AGENTS.md (Database lock). Then run `dart run build_runner build --delete-conflicting-outputs`.
3. Add the data source method in `lib/features/<feature>/data/datasources/`. It calls the DAO and lets raw exceptions through.
4. Add the mapper conversions in `lib/features/<feature>/data/mappers/`: rows to entity, entity to companion. Convert `Money`, `Quantity`, and `CurrencyCode` here.
5. Implement the method in `lib/features/<feature>/data/repositories/*_repository_impl.dart`. Catch exceptions and return `Left(Failure)` with the mapping in AGENTS.md (Use cases and errors). Map a `.watch()` stream to `Right` values and its errors to `Left`. For a write, apply the transaction and parent-list `updated_at` rules in AGENTS.md (Database lock). If the data source or repository implementation is new, register it in `lib/core/di/injection.dart`.
6. Write the tests. Cover the repository test cases in AGENTS.md (Use cases and errors), plus these where they apply. Test the throw case with a mocktail fake data source. Test every other case on `NativeDatabase.memory()`.
   - a write that fails halfway leaves no partial row
   - a fake `SQLITE_FULL` on a write returns `StorageFullFailure`
   - the SQL total equals the Dart total (the parity test in AGENTS.md)
   - the onboarding transaction creates the list and saves the settings together

   Put tests in `test/core/database/` or `test/features/<feature>/data/`.
7. Run the milestone's Verify command from PRD section 15.

## References

- `AGENTS.md`: Use cases and errors, Money and data rules, Database lock.
- `test/architecture_test.dart`: only `data` and `core/database` import `drift`.
- `.agents/rules/protected-files.md`: do not skip or delete tests.
- `docs/PRD.md`: sections 8.2, 9.3, 9.4, 9.5.
