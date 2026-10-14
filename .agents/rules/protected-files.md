---
trigger: glob
globs: "**/PRD.md, **/AGENTS.md, **/.agents/rules/*.md, **/analysis_options.yaml, **/architecture_test.dart, **/drift_schemas/**, **/test/**"
description: "Files the agent must not change to make its own work pass: the spec, the rules, the lint config, the architecture test, the schema snapshot, and the test suite."
---

# Protected files

One job: stop the agent from changing the files that judge its work.

## Rules

1. Do not edit `docs/PRD.md`. If it looks wrong, stop and tell the user which section and why.
   Reason: editing the spec to match the code hides a gap instead of reporting it.

2. Do not edit `AGENTS.md` or any file in `.agents/rules/`.
   Reason: the agent must not loosen the rules it works under.

3. Do not edit `analysis_options.yaml`. Fix the code the analyzer flags.
   Reason: silencing a lint hides a defect.

4. Do not edit `test/architecture_test.dart` once it exists. If a needed import is blocked, stop and ask the user to change the rule.
   Reason: a weakened test passes code that breaks the architecture.

5. Do not change any file in `drift_schemas/` after M3.
   Reason: the snapshot proves the schema lock holds. A regenerated snapshot hides a schema change.

6. Do not delete a test file.
   Reason: a deleted test turns a failing run into a passing one.

7. Do not add `skip:` to any test.
   Reason: a skipped test reports no failure without running.

8. Creating a file that does not exist yet is allowed when `AGENTS.md` tells you to.
   Reason: M3 creates the schema snapshot and M9 creates the architecture test. Rules 4 and 5 apply after that.

9. When one of these rules blocks a task, stop and ask the user. Do not edit a protected file to unblock the task.
   Reason: the user owns these files, not the agent.

## Check before every commit

Run these three commands. Each must print nothing.

```
git diff --diff-filter=M --name-only HEAD -- docs/PRD.md AGENTS.md .agents/rules analysis_options.yaml test/architecture_test.dart drift_schemas
git diff --diff-filter=D --name-only HEAD -- test
grep -rn "skip:" test
```

If `git diff` fails because the repository has no commit yet, write "protected-file check not run" in your reply.
Reason: a rule the agent cannot check is a rule it can break without knowing.
