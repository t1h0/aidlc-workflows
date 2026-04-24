---
name: aidlc-ext-google-style-guide
description: Optional AI-DLC extension. Google style guide rules that apply across applicable AI-DLC stages for each programming language detected in the project.
---

# Google Style Guide Rules

## Overview

These style guide rules are cross-cutting constraints that apply across applicable AI-DLC phases. They ensure that all code produced during the workflow conforms to the relevant Google style guide for each programming language used in the project.

**Enforcement**: At each applicable stage, the model MUST verify compliance with these rules before presenting the stage completion message to the user.

### Language Detection and Style Guide Loading

**CRITICAL**: When this extension is enabled, the model MUST:

1. Detect all programming languages present in the project during the Workspace Detection stage (or as early as possible)
2. Cross-reference detected languages against the available style guides in the `styleguides/` subfolder (located alongside this SKILL.md)
3. Load the style guide for each language that has a corresponding file in `styleguides/`
4. Apply only the loaded style guides — languages without a corresponding file are not covered by this extension

**Available style guides** (in the `styleguides/` subfolder):

| File             | Language    | Applies to                                                           |
| ---------------- | ----------- | -------------------------------------------------------------------- |
| `python.md`      | Python      | All `.py` files                                                      |
| `c-sharp.md`     | C#          | All `.cs` files                                                      |
| `objective-c.md` | Objective-C | All `.m` and `.h` files                                              |
| `R.md`           | R           | All `.R` and `.r` files                                              |
| `shell.md`       | Shell       | All `.sh`, `.bash`, `.zsh` files and shell scripts without extension |

If a language is detected but no corresponding style guide exists in the `styleguides/` subfolder, log this as an informational note in `aidlc-docs/aidlc-state.md` under `## Extension Configuration` and do not treat it as a blocking finding.

Log all detected languages and loaded style guides in `aidlc-docs/aidlc-state.md` under `## Extension Configuration`. Example:

```markdown
## Extension Configuration

- aidlc-ext-google-style-guide: ENABLED
  - Detected languages: Python, Shell
  - Loaded style guides: python.md, shell.md
  - Languages without style guide: (none)
```

### Blocking Style Guide Finding Behavior

A **blocking style guide finding** means:

1. The finding MUST be listed in the stage completion message under a "Style Guide Findings" section with the STYLE rule ID and description
2. The stage MUST NOT present the "Continue to Next Stage" option until all blocking findings are resolved
3. The model MUST present only the "Request Changes" option with a clear explanation of what needs to change
4. The finding MUST be logged in `aidlc-docs/audit.md` with the STYLE rule ID, description, and stage context

If a style guide rule is not applicable to the current project or stage (e.g., STYLE-PY-01 when no Python files exist), mark it as **N/A** in the compliance summary — this is not a blocking finding.

### Default Enforcement

All rules derived from the loaded style guides are **blocking** by default. If generated or reviewed code violates a rule from a loaded style guide, it is a blocking style guide finding — follow the blocking finding behavior defined above.

### Verification Criteria Format

Verification items in this document are plain bullet points describing compliance checks. Each item should be evaluated as compliant or non-compliant during review.

---

## Rule STYLE-01: Style Guide Compliance for Generated Code

**Rule**: All code generated during Code Generation (Part 2) MUST conform to the Google style guide for its language, as loaded from the `styleguides/` subfolder. The model MUST check each generated file against the rules of the applicable style guide before marking the file as complete.

Compliance covers, but is not limited to:

- **Naming conventions**: Variables, functions, classes, constants, and modules must follow the naming rules defined in the loaded style guide
- **Formatting**: Indentation, line length, blank lines, and whitespace must match the style guide's formatting rules
- **Imports and includes**: Ordering, grouping, and import style must follow the style guide
- **Comments and documentation**: Docstring format, inline comment style, and documentation requirements must match the style guide
- **Language-specific rules**: Any language-specific decisions (e.g., use of specific constructs, discouraged patterns) defined in the loaded style guide must be respected

**Verification**:

- Every generated source file has been checked against the applicable loaded style guide
- No generated code uses naming conventions, formatting, or patterns explicitly prohibited by the loaded style guide
- Docstrings and comments follow the format prescribed by the loaded style guide
- Import or include ordering matches the loaded style guide's requirements
- Any deviation from the style guide is explicitly documented with a rationale (e.g., framework requirement, generated code exemption)

---

## Rule STYLE-02: Style Guide Compliance During Code Review (Plan Review Stage)

**Rule**: During the Plan Review stage, all existing and generated code MUST be evaluated for compliance with the loaded Google style guides. Style violations identified during plan review are blocking findings.

**Verification**:

- Each source file reviewed has been checked against the applicable loaded style guide
- Style violations found during plan review are listed as blocking findings before the stage can complete
- If existing code (brownfield) already contains style violations, these are listed and the user is presented with the option to address them now or document a conscious deferral

---

## Rule STYLE-03: Consistent Application Across All Units

**Rule**: Style guide rules MUST be applied consistently across all units of work. The same language used in two different units must follow the same style guide rules in both.

**Verification**:

- Naming conventions are consistent across all units for the same language
- No unit introduces a conflicting style convention for a language already covered by a loaded style guide
- If multiple units use the same language, they share the same style guide compliance baseline

---

## Rule STYLE-04: Design Artifacts Reflect Style Guide Naming

**Rule**: When Functional Design or Application Design artifacts define component names, method names, variable names, or data model fields, these names MUST comply with the naming conventions of the applicable loaded style guide for the target implementation language.

This ensures that names defined during design do not need to be changed during code generation to meet style requirements.

**Verification**:

- Component and method names in design artifacts follow the naming convention for the implementation language (e.g., `snake_case` for Python functions, `PascalCase` for C# classes)
- Data model field names in design artifacts comply with the loaded style guide
- Any name in a design artifact that would violate the style guide is flagged and corrected before the design stage completes

---

## Enforcement Integration

These rules are cross-cutting constraints that apply to the following AI-DLC stages:

| Stage                        | Applicable Rules          | Enforcement                                                                 |
| ---------------------------- | ------------------------- | --------------------------------------------------------------------------- |
| Workspace Detection          | STYLE-01 (detection only) | Detect languages and log loaded style guides in aidlc-state.md              |
| Functional Design            | STYLE-04                  | Design artifact names must comply with style guide naming conventions       |
| Application Design           | STYLE-04                  | Component and service names must comply with style guide naming conventions |
| Code Generation (Generation) | STYLE-01, STYLE-03        | All generated code must comply with the loaded style guides                 |
| Plan Review                  | STYLE-02, STYLE-03        | All code reviewed must be checked against loaded style guides               |

At each applicable stage:

- Evaluate all STYLE rule verification criteria against the artifacts produced
- Include a "Style Guide Compliance" section in the stage completion summary listing each applicable rule as compliant, non-compliant, or N/A (with brief rationale for N/A determinations)
- If any rule is non-compliant, this is a blocking style guide finding — follow the blocking finding behavior defined in the Overview
- Include style guide rule references in code generation planning steps

---

## Appendix: Language Detection Quick Reference

When scanning the workspace, use the following heuristics to detect languages:

| Language    | Indicators                                                                       |
| ----------- | -------------------------------------------------------------------------------- |
| Python      | `.py` files, `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile`         |
| C#          | `.cs` files, `.csproj`, `.sln` files                                             |
| Objective-C | `.m` or `.h` files alongside `.xcodeproj` or `.xcworkspace`                      |
| R           | `.R` or `.r` files, `DESCRIPTION` file (R package indicator)                     |
| Shell       | `.sh`, `.bash`, `.zsh` files, scripts with `#!/bin/bash` or `#!/bin/sh` shebangs |

If a language is detected, check whether a corresponding file exists in the `styleguides/` subfolder. Load the file if it exists; skip silently with an informational log entry if it does not.
