---
name: aidlc-2-3-construction-plan-review
description: This skill executes the Plan Review stage of the Construction phase in AI-DLC, which reviews the implementation against the inception plan to identify gaps and missing functionality before proceeding to Operations.
---

# Plan Review

**Purpose**: Verify that the implementation fulfills all requirements, user stories, and design decisions from the Inception phase — and that it contains *only* what was planned (no overreach). Identify any gaps or excess, and if found, loop back to Construction to address them.

## Prerequisites

- Build and Test stage must be complete
- All inception artifacts must be available (requirements, user stories, application design, units of work)
- All construction artifacts must be available (code generation plans, generated code)

---

## Step 1: Load Inception Artifacts

Load all relevant inception artifacts for comparison:

- [ ] Read `aidlc-docs/inception/requirements/requirements.md`
- [ ] Read `aidlc-docs/inception/user-stories/stories.md` (if exists)
- [ ] Read `aidlc-docs/inception/application-design/` artifacts (if exist)
- [ ] Read `aidlc-docs/inception/plans/execution-plan.md`
- [ ] Read unit of work definitions from `aidlc-docs/inception/` (if exist)

---

## Step 2: Load Construction Artifacts

Load all construction outputs for review:

- [ ] Read code generation plans from `aidlc-docs/construction/plans/`
- [ ] Read NFR Design artifacts from `aidlc-docs/construction/*/nfr-design/` (if exist)
- [ ] Read Infrastructure Design artifacts from `aidlc-docs/construction/*/infrastructure-design/` (if exist)
- [ ] Read build and test summary from `aidlc-docs/construction/build-and-test/build-and-test-summary.md`
- [ ] Scan generated application code in workspace root
- [ ] Read code summaries from `aidlc-docs/construction/*/code/`

---

## Step 3: Check for AI Overreach (PRIMARY GATE)

**This is the primary gate — evaluate before requirements coverage.**

For each construction artifact (code generation plans + generated code), check whether the AI implementation stayed within the planned scope:

- [ ] Did code generation add components, services, or modules **not planned** in Application Design?
- [ ] Did code generation add behaviors not covered by any requirement or user story?
- [ ] Did code generation add abstractions, utilities, or generalizations beyond what the plan called for?
- [ ] Did code generation add defensive code for error cases not described in requirements?
- [ ] Did code generation violate architectural decisions from NFR Design or Infrastructure Design (e.g., added layers, introduced tech stack not approved)?
- [ ] Did code generation create functionality explicitly marked as out-of-scope during Inception?

For each overreach finding: document the component or behavior, what it does, why it was not planned, and classify its severity.

**Overreach findings are 🔴 Blocker severity by default.** Downgrade to 🟡 Major only if the addition is trivially safe and isolated.

---

## Step 4: Review Requirements Coverage

For each requirement in `requirements.md`:

- [ ] Verify the requirement is addressed by the implementation
- [ ] Check that acceptance criteria (if defined) are satisfiable by the generated code
- [ ] Determine if the requirement was intentionally deferred during Inception or Construction (check execution-plan.md and code generation plans for explicit deferrals)
- [ ] Mark each requirement with status and severity:
  - **Implemented** — fully addressed
  - **Partially Implemented** — some aspects present but incomplete → 🟡 Major
  - **Not Implemented (Deferred)** — explicitly deferred with documented reason → 🟢 Minor
  - **Not Implemented** — missing with no documented deferral → 🔴 Blocker

---

## Step 5: Review User Story Coverage

If user stories exist, for each story in `stories.md`:

- [ ] Verify the story's acceptance criteria are met by the implementation
- [ ] Check that the story's functionality is testable
- [ ] Determine if the story was intentionally deferred
- [ ] Mark each story with status and severity (same classification as requirements above)

---

## Step 6: Review Architecture Layer Compliance

If NFR Design or Infrastructure Design artifacts exist:

- [ ] Verify that component boundaries match the designed architecture (no layer bypasses)
- [ ] Verify that data access / persistence logic is not mixed into API/controller layers
- [ ] Verify that cross-cutting concerns (auth, logging, error handling) are applied at the designed layer boundaries
- [ ] Verify that the tech stack matches approved decisions from NFR Requirements
- [ ] Document any layer violations with severity (🔴 Blocker for structural violations, 🟡 Major for minor boundary blurring)

---

## Step 7: Review Design Compliance

If application design artifacts exist:

- [ ] Verify all planned components were implemented
- [ ] Check that component methods and business rules match the design
- [ ] Verify service layer design was followed
- [ ] Check that component dependencies match the designed relationships
- [ ] Document any deviations from the design, assess whether they are justified, and assign severity

---

## Step 8: Review Unit of Work Completion

If unit of work definitions exist:

- [ ] Verify all units of work were completed
- [ ] Check that unit dependencies were properly implemented
- [ ] Verify unit story maps are fully covered
- [ ] Document any incomplete units with severity

---

## Step 9: Generate Plan Review Report

Create `aidlc-docs/construction/plan-review/plan-review-report.md`:

```markdown
# Plan Review Report

## Review Summary

- **Review Date**: [ISO timestamp]
- **Overall Status**: [All Clear / Blockers Found / Majors Found]

## AI Overreach Check

| Finding                   | Severity   | Description                      |
| ------------------------- | ---------- | -------------------------------- |
| [Component/behavior name] | [🔴/🟡/🟢]  | [What was added beyond the plan] |

**Overreach Check**: PASS / FAIL

## Requirements Coverage

| Requirement   | Status                                                                   | Severity    | Notes     |
| ------------- | ------------------------------------------------------------------------ | ----------- | --------- |
| [REQ-ID/Name] | [Implemented / Partially / Not Implemented / Not Implemented (Deferred)] | [🔴/🟡/🟢/–] | [Details] |

**Requirements Coverage**: [X]/[Total] fully implemented

## User Stories Coverage

| Story           | Status                                                                   | Severity    | Notes     |
| --------------- | ------------------------------------------------------------------------ | ----------- | --------- |
| [Story ID/Name] | [Implemented / Partially / Not Implemented / Not Implemented (Deferred)] | [🔴/🟡/🟢/–] | [Details] |

**Story Coverage**: [X]/[Total] fully implemented

## Architecture Layer Compliance

| Area             | Status                  | Severity    | Notes     |
| ---------------- | ----------------------- | ----------- | --------- |
| [Layer/boundary] | [Compliant / Violation] | [🔴/🟡/🟢/–] | [Details] |

## Design Compliance

| Component/Service | Status                  | Severity  | Notes     |
| ----------------- | ----------------------- | --------- | --------- |
| [Component Name]  | [Compliant / Deviation] | [🔴/🟡/🟢/–] | [Details] |

## Review Category Summary

| Category                | Result          | 🔴 Blockers | 🟡 Majors | 🟢 Minors |
| ----------------------- | --------------- | ----------- | --------- | -------- |
| AI Overreach            | PASS/FAIL       | X           | X         | X        |
| Requirements Coverage   | PASS/FAIL       | X           | X         | X        |
| User Story Coverage     | PASS/FAIL / N/A | X           | X         | X        |
| Architecture Compliance | PASS/FAIL / N/A | X           | X         | X        |
| Design Compliance       | PASS/FAIL / N/A | X           | X         | X        |
| Unit Completion         | PASS/FAIL / N/A | X           | X         | X        |

## Intentional Deferrals

Items explicitly noted during Inception or Construction as out of scope or deferred:

| Item                | Source                 | Deferral Reason |
| ------------------- | ---------------------- | --------------- |
| [Requirement/story] | [Stage where deferred] | [Reason]        |

## Gaps Identified

### Gap 1: [Title]

- **Source**: [Requirement/Story/Design reference]
- **Severity**: [🔴 Blocker / 🟡 Major / 🟢 Minor]
- **Description**: [What is missing or what was added beyond the plan]
- **Impact**: [How this affects the system]
- **Recommended Action**: [Build more / Remove excess / Document deferral]

### Gap X: [Title]

[Same structure]

## Conclusion

### Release Risk
**Rating**: Low / Medium / High  
**Reason**: [Summary of what drives the risk level — number and severity of blockers, overreach surface area, etc.]

[Summary of findings and recommendation to proceed or loop back]
```

---

## Step 10: Update State Tracking

Update `aidlc-docs/aidlc-state.md`:

- Mark Plan Review stage as complete
- Update current status
- If blockers found, note that Construction loop-back is required

---

## Step 11: Present Results to User

Before presenting options, display the formal exit criteria checklist:

```markdown
## Exit Criteria

- [ ] AI Overreach Check: PASS (no unrequested behavior added)
- [ ] All 🔴 Blocker findings resolved or accepted with documented rationale
- [ ] Requirements Coverage: all undeferred requirements Implemented
- [ ] Architecture compliance verified (no layer violations)
- [ ] Intentional deferrals documented
- [ ] Release Risk rated and communicated
```

### If exit criteria are ALL met (no blockers)

Present completion message in this structure:

1. **Completion Announcement** (mandatory)

   Always start with this:

   ```markdown
   # ✅ Plan Review Complete — No Blockers
   ```

2. **AI Summary** (optional)

   Provide structured bullet-point summary of review results

   - Format: "Plan review has completed with the following results:"
   - List the review category summary (PASS/FAIL per category)
   - List the release risk rating
   - List any Majors or Minors for awareness
   - DO NOT include workflow instructions
   - Keep factual and content-focused

3. **Formatted Workflow Message** (mandatory)

   Always end with this exact format:

   ```markdown
   ## 📋 REVIEW REQUIRED

   Please examine the plan review report at: `aidlc-docs/construction/plan-review/plan-review-report.md`

   ## 🚀 WHAT'S NEXT?

   **You may:**

   - 🔧 **Request Changes** — Flag additional gaps or concerns based on your review
   - ✅ **Approve & Continue** — Approve the review and proceed to **Operations**

   ---
   ```

### If exit criteria have blockers

Present completion message in this structure:

1. **Completion Announcement** (mandatory)

   Always start with this:

   ```markdown
   # ⚠️ Plan Review Complete — Blockers Found
   ```

2. **AI Summary** (mandatory)

   Provide structured summary of blockers found

   - Format: "Plan review has identified the following blockers:"
   - List each 🔴 Blocker with its source reference and description
   - Distinguish overreach blockers (remove excess) from gap blockers (build more)
   - List release risk rating
   - DO NOT include workflow instructions
   - Keep factual and content-focused

3. **Formatted Workflow Message** (mandatory)

   Always end with this exact format:

   ```markdown
   ## 📋 REVIEW REQUIRED

   Please examine the plan review report at: `aidlc-docs/construction/plan-review/plan-review-report.md`

   ## 🚀 WHAT'S NEXT?

   **You may:**

   - 🔧 **Request Changes** — Modify the finding analysis or flag additional concerns
   - 🔁 **Address Blockers** — Return to **Construction** to resolve blockers
   - ✅ **Approve & Continue** — Accept blockers and proceed to **Operations** anyway (requires documented rationale)

   ---
   ```

---

## Step 12: Handle Loop-Back to Construction

If the user chooses to address blockers:

1. Create a gap resolution scope document at `aidlc-docs/construction/plans/gap-resolution-plan.md`:
   - List all blockers to address, grouped by type:
     - **Additive gaps** (something missing — build more): map to existing or new construction units
     - **Overreach gaps** (something unrequested was built — remove excess): create a refactoring unit to remove the excess code, not to add more
   - For each blocker, define the construction stages needed (may skip design stages if the design already covers the gap)
2. Update `aidlc-docs/aidlc-state.md` to reflect the loop-back and iteration number
3. Re-enter the Construction per-unit loop for the affected units
4. After all blockers are addressed, return to Build and Test, then back to Plan Review

---

## Step 13: Log Interaction

**MANDATORY**: Log the stage completion in `aidlc-docs/audit.md`:

```markdown
## Plan Review Stage

**Timestamp**: [ISO timestamp]
**Review Status**: [No Blockers / Blockers Found]
**Overreach Check**: PASS/FAIL
**Requirements Coverage**: [X]/[Total]
**User Story Coverage**: [X]/[Total]
**Blockers**: [Number] | **Majors**: [Number] | **Minors**: [Number]
**Release Risk**: Low/Medium/High
**User Decision**: [Approve & Continue / Address Blockers / Request Changes]
**Files Generated**:

   - plan-review-report.md

---
```

---

## Critical Rules

### Review Thoroughness

- Check EVERY requirement, not just a sample
- Check EVERY user story, not just high-priority ones
- Verify design compliance at the component level, not just at a high level
- Check overreach at the behavior level, not just the file level
- Do not assume implementation is correct — verify by reading the code

### Severity Classification

- 🔴 **Blocker** — prevents proceeding without explicit acceptance: overreach, missing requirement (not deferred), architecture violation
- 🟡 **Major** — can proceed only with explicit user acceptance and a documented follow-up plan
- 🟢 **Minor** — non-blocking finding noted for future improvement

### Intentional Deferral vs. Gap

Before classifying a missing item as a Blocker, check whether it was explicitly deferred:

- Look for deferral notes in `execution-plan.md`
- Look for scope reduction notes in code generation plans
- If deferred with documented reason: classify as **Not Implemented (Deferred)** at 🟢 Minor, not a Blocker

### Loop-Back Rules

- When looping back for **additive gaps** (something missing): only re-execute Construction stages needed for the gaps
- When looping back for **overreach** (something extra was built): create a refactoring unit to remove the excess, do not add more code
- After addressing blockers, Build and Test must run again before another Plan Review
- Track loop-back iterations in `aidlc-state.md` to prevent infinite loops
- If this is the third loop-back iteration, present a warning to the user and suggest reviewing the inception artifacts for feasibility issues
