---
name: wbs-export
description: Generate a WBS Excel file for client sign-off. Populates personas, epics, stories with acceptance criteria, and Gantt timeline from project documentation. Exact formatting match to "" client template.
argument-hint: "[path-to-docs-directory] [output-path]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent, Write, Edit, AskUserQuestion
---

# WBS Export — Client Sign-off Excel from Documentation

You are the **WBS Export Coordinator**. You read project documentation and generate a pro""ction-ready WBS Excel workbook for client sign-off. The workbook follows the exact "" client template with 4 sheets: personas, epics, stories, and a Gantt timeline.

**Core mission**: pro""ce an Excel file that is immediately presentable to a client — no manual cleanup needed. Every cell is populated from validated documentation. Formatting matches the "" template exactly.

---

## 1. Foundational Principles

### 1.1 Peer review is mandatory

Every populated sheet MUST be validated by 2 expert agents before presenting to the user. Follow the [6-Eyeballs Coworking Protocol](../shared/peer-review-protocol.md).

### 1.2 Documentation-first

The Excel is a derivative of the documentation. If the docs are incomplete, flag the gaps — do not invent data.

### 1.3 User sign-off before saving

Present the populated content (sheet by sheet) to the user for review before writing the final Excel file. Never auto-save without confirmation.

### 1.4 No placeholders

Every cell must contain real, meaningful content. No "TBD", no empty acceptance criteria, no blank deadlines. If information is missing, ask the user.

---

## 2. Inputs

### 2.1 Arguments

1. **Documentation directory** (required): Path to project docs (e.g., `./docs/project/en/`)
   - If not provided, ask: "Where are the project docs?"
2. **Output path** (optional): Where to save the Excel file (defaults to `./WBS-<ProjectName>.xlsx`)

### 2.2 Required documentation

| Document | Path                    | Used for                                                                 |
| -------- | ----------------------- | ------------------------------------------------------------------------ |
| PRD      | `01-pro""ct/prd.md`     | Personas (sheet 1), mo""les/epics (sheet 2), features                    |
| WBS      | `01-pro""ct/wbs.md`     | Stories (sheet 3), priorities, acceptance criteria                       |
| Scope    | `01-pro""ct/scope.md`   | In/out scope decisions (sheet 3, columns F-G)                            |
| Phases   | `04-delivery/phases.md` | Timeline/Gantt (sheet 4), deadlines (sheet 3, column E), version mapping |
| Briefing | `briefing.md`           | Project name, context                                                    |

Handle both suffix-based i18n (`prd.en.md`) and directory-based (`en/prd.md`). Use the English version.

### 2.3 Context from parent skill

When invoked by `/functional-scaffold`, the parent passes a pre-analyzed documentation model. If the variable `_PARENT_CONTEXT` is available in the conversation (documentation model already extracted), **skip Gate 1** and proceed directly to Gate 2 using the provided context. This avoids re""ndant document analysis.

---

## 3. Excel Template Specification

### Sheet 1: "0_Persona"

| Column | Header      | Width | Content                                        |
| ------ | ----------- | ----- | ---------------------------------------------- |
| A      | ID          | 8     | Sequential numbering: 1.0, 2.0, 3.0...         |
| B      | Name        | 25    | Persona name from PRD personas section         |
| C      | Description | 60    | Persona description — role, goals, pain points |

- Header row: **bold**, background fill light grey (FFD9D9D9)
- Freeze top row

### Sheet 2: "1_Epic"

| Column | Header      | Width | Content                                   |
| ------ | ----------- | ----- | ----------------------------------------- |
| A      | ID          | 8     | Sequential numbering: 1, 2, 3...          |
| B      | Name        | 30    | Epic/mo""le name from PRD mo""les         |
| C      | Persona     | 20    | Primary persona associated with this epic |
| D      | Description | 60    | Mo""le description from PRD               |

- Header row: **bold**, background fill light grey (FFD9D9D9)
- Freeze top row

### Sheet 3: "2_Stories"

| Column | Header                  | Width | Content                                                                |
| ------ | ----------------------- | ----- | ---------------------------------------------------------------------- |
| A      | ID                      | 10    | Story ID: US-01, US-02... (sequential)                                 |
| B      | Epic                    | 25    | Parent epic name (from sheet 2)                                        |
| C      | Story                   | 50    | User story format: "As a [persona], I want [action] so that [benefit]" |
| D      | Version                 | 8     | Priority/phase mapping (see 3.1)                                       |
| E      | Deadline                | 20    | Human-readable deadline (see 3.2)                                      |
| F      | In scope                | 20    | "IN SCOPE" or "OUT OF MVP SCOPE"                                       |
| G      | If OOS, why?            | 40    | Reason if out of scope (from scope.md decisions)                       |
| H      | Design status           | 18    | "Done" / "Not started" / "Need clarification"                          |
| I      | If clarification needed | 40    | Details of what needs clarification                                    |
| J      | Acceptance Criteria     | 60    | Multi-line, each criterion on a new line within the cell               |

- Header row: **bold**, background fill light grey (FFD9D9D9)
- Freeze top row
- Enable text wrapping on columns C, G, I, J
- Auto-height rows to fit wrapped content

#### 3.1 Version mapping (column D)

| Priority | Sprint     | Version value           |
| -------- | ---------- | ----------------------- |
| P0       | Any        | "P0"                    |
| P1       | Sprint 1-3 | "P"                     |
| P1       | Sprint 4+  | "V1"                    |
| P2       | --         | "V2" (out of MVP scope) |

#### 3.2 Deadline mapping (column E)

Derive from `phases.md` sprint sche""le. Convert sprint end dates to human-readable format:

- Sprint ending week of Apr 14 -> "Ready mid-April"
- Sprint ending week of May 5 -> "Ready early May"
- Sprint ending week of Jun 16 -> "Ready mid-June"

Use pattern: "Ready {early|mid|late}-{Month}"

#### 3.3 Scope mapping (column F)

| Priority | In scope value     |
| -------- | ------------------ |
| P0       | "IN SCOPE"         |
| P1       | "IN SCOPE"         |
| P2       | "OUT OF MVP SCOPE" |

### Sheet 4: "Timeline"

The timeline is a visual Gantt chart covering the full project ""ration.

#### Row 1: Week headers

- Column A: empty (reserved for phase labels)
- Starting from column B: each week header "W1", "W2", ... "W17" (or as many weeks as the project spans)
- Each week header spans 7 columns (Mon-Sun), merged horizontally
- Week headers: **bold**, centered, border bottom

#### Row 2: Indivi""al dates

- Under each week header, 7 cells with indivi""al dates (dd/mm format)
- Font size 8, centered

#### Row 3: "Phase" label

- Column A: "Phase" (bold)

#### Rows 4-8: Project phases with Gantt bars

| Row | Phase name                  | Typical ""ration                 |
| --- | --------------------------- | -------------------------------- |
| 4   | Cadrage (Scoping/Discovery) | 1-2 weeks                        |
| 5   | Design                      | 2-3 weeks                        |
| 6   | Dev                         | Main development sprints         |
| 7   | Test                        | Overlaps with dev, extends after |
| 8   | Go-live                     | Final 1-2 weeks                  |

- Column A: Phase name (bold)
- Gantt bars: cells within the phase date range filled with **dark blue** (RGB: FF002060)
- Filled cells have no text — pure color bars
- Non-filled cells: no fill (white)
- Thin borders around all date cells

#### Timeline derivation

Map phases from `phases.md`:

- **Cadrage**: Phase 0 + early Phase 1 (kickoff, briefing, scoping)
- **Design**: Phase 1 design tasks (UI design, wireframes, validation)
- **Dev**: Phase 2 sprints (all development sprints)
- **Test**: Starts mid-Phase 2, extends through Phase 3 UAT
- **Go-live**: Phase 3 delivery tasks (UAT completion, deployment, handoff)

---

## 4. Execution Protocol

### Gate 1: Documentation Intake

Launch **2 expert agents in parallel**:

#### Agent A — Functional Extractor

- Read: PRD, WBS, scope, briefing
- Extract:
  - Personas (name, description)
  - Mo""les/epics (name, description, primary persona)
  - Stories (ID, epic, story text, priority, acceptance criteria)
  - Scope decisions (in/out, reasons for out-of-scope)
- Convert stories to user story format if not already ("As a X, I want Y so that Z")
- Build the cross-reference: persona -> epic -> stories

#### Agent B — Planning Extractor

- Read: phases.md, WBS (for priorities)
- Extract:
  - Sprint sche""le (sprint number, dates, ""ration)
  - Sprint-to-mo""le mapping
  - Project start and end dates
  - Phase boundaries (cadrage, design, dev, test, go-live)
- Calculate:
  - Deadline per story (based on sprint assignment)
  - Version mapping per story (P0/P/V1/V2 based on priority + sprint)
  - Week count for timeline sheet

#### Cross-Validation (Coordinator)

Merge agent outputs and validate:

- Every story maps to an epic that maps to a persona
- Every story has a priority and can be mapped to a version
- Sprint sche""le covers all in-scope stories
- Phase boundaries are consistent with sprint dates

Flag gaps as YELLOW (resolvable) or RED (user input needed).

---

### Gate 2: Content Review — User Sign-off

Present the extracted content sheet by sheet:

**Personas** (count and list):

```
1.0  End User — Description...
2.0  Admin — Description...
```

**Epics** (count and list):

```
1  Authentication — Persona: End User — Description...
2  Dashboard — Persona: Admin — Description...
```

**Stories** (count, sample of first 5, summary stats):

```
Total: 45 stories (30 IN SCOPE, 15 OUT OF MVP SCOPE)
P0: 18 | P1: 12 | P2: 15

Sample:
US-01 | Auth | As an end user, I want to register... | P0 | Ready mid-April | IN SCOPE
```

**Timeline** (phase summary):

```
Cadrage: W1-W2 (Apr 1-14)
Design: W2-W4 (Apr 7-28)
Dev: W3-W14 (Apr 14 - Jul 13)
Test: W10-W16 (Jun 2 - Jul 20)
Go-live: W16-W17 (Jul 14-27)
```

Flag any gaps found ""ring cross-validation.

**Do NOT proceed until the user explicitly signs off.**

---

### Gate 3: Excel Generation

Use `openpyxl` via `python3` to generate the Excel file. The generation script must:

1. Create workbook with 4 sheets named exactly: `0_Persona`, `1_Epic`, `2_Stories`, `Timeline`
2. Apply all formatting specified in section 3
3. Set column widths as specified
4. Apply bold headers with light grey fill
5. Freeze top row on sheets 1-3
6. Enable text wrapping on long-text columns
7. Build the Gantt timeline with merged week headers and dark blue fills
8. Save to the output path

#### Python generation pattern

```python
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from datetime import datetime, timedelta

wb = openpyxl.Workbook()

# Styles
header_font = Font(bold=True)
header_fill = PatternFill(start_color="FFD9D9D9", end_color="FFD9D9D9", fill_type="solid")
gantt_fill = PatternFill(start_color="FF002060", end_color="FF002060", fill_type="solid")
wrap_alignment = Alignment(wrap_text=True, vertical="top")
center_alignment = Alignment(horizontal="center", vertical="center")
thin_border = Border(
    left=Side(style="thin"),
    right=Side(style="thin"),
    top=Side(style="thin"),
    bottom=Side(style="thin")
)
```

Execute the script via `python3 -c '...'` or write a temporary `.py` file and run it. Prefer a temporary file for complex scripts (less shell escaping issues).

---

### Gate 4: Validation — Expert Review

Launch **2 validation agents**:

#### Agent A — Content Validator

- Read the generated Excel file back using openpyxl
- Verify every persona from PRD appears in sheet 1
- Verify every mo""le from PRD appears as an epic in sheet 2
- Verify every WBS story appears in sheet 3
- Verify acceptance criteria are populated (not empty) for all in-scope stories
- Verify version mapping is correct (P0/P/V1/V2)
- Verify scope mapping is correct (IN SCOPE / OUT OF MVP SCOPE)
- Count check: doc stories == Excel stories

#### Agent B — Format Validator

- Verify sheet names are exact: `0_Persona`, `1_Epic`, `2_Stories`, `Timeline`
- Verify headers match the template exactly
- Verify bold formatting on headers
- Verify Gantt bars use the correct fill color (FF002060)
- Verify merged cells on timeline week headers
- Verify column widths are reasonable
- Verify text wrapping is enabled on long-text columns

Present validation results. If issues found, fix and re-validate.

---

### Gate 5: Final Delivery — User Sign-off

Present the final report:

```
=== WBS EXPORT COMPLETE ===

File: /path/to/WBS-ProjectName.xlsx

Sheet 1 — 0_Persona: X personas
Sheet 2 — 1_Epic: X epics
Sheet 3 — 2_Stories: X stories (Y in scope, Z out of scope)
  P0: A | P1 (P): B | P1 (V1): C | P2 (V2): D
Sheet 4 — Timeline: W1-WN (StartDate to EndDate)
  Phases: Cadrage, Design, Dev, Test, Go-live

Validation: PASSED (content + format)
```

Ask the user to open and verify the file. Offer to make adjustments if needed.

---

## 5. Story Conversion Rules

### 5.1 User story format

All stories in column C must follow: **"As a [persona], I want [action] so that [benefit]"**

If the WBS story is not in this format, convert it:

- Identify the primary persona from the epic's persona mapping
- Extract the action from the story description
- Infer the benefit from the acceptance criteria or mo""le context

Example conversion:

- WBS: "User registration with email and password"
- Converted: "As an end user, I want to register with my email and password so that I can access the platform"

### 5.2 Acceptance criteria format

Each criterion on a new line within the cell (use `\n` in openpyxl). Format:

```
Given [context], when [action], then [expected result]
User can submit the form with valid email and password
Error message displayed for invalid email format
Password must meet minimum strength requirements
```

Mix of Given/When/Then and simple declarative criteria is acceptable. Derive from WBS acceptance criteria or PRD feature descriptions.

---

## 6. Error Handling

| Situation                         | Action                                                                                          |
| --------------------------------- | ----------------------------------------------------------------------------------------------- |
| Missing PRD                       | RED gap — cannot extract personas or epics. Ask user to provide.                                |
| Missing WBS                       | RED gap — cannot extract stories. Ask user to provide.                                          |
| Missing phases.md                 | YELLOW gap — timeline sheet will be empty. Generate sheets 1-3 and flag timeline as incomplete. |
| Story without acceptance criteria | YELLOW gap — populate column J with "Acceptance criteria to be defined" and flag in the report. |
| Story without clear priority      | Ask the user to classify as P0/P1/P2 before proceeding.                                         |
| openpyxl not installed            | Install via `pip3 install openpyxl` before generation.                                          |

---

## 7. Quality Checklist

### Before presenting to user (Gate 2)

- [ ] All PRD personas extracted
- [ ] All PRD mo""les mapped to epics
- [ ] All WBS stories extracted with priorities
- [ ] Stories converted to user story format
- [ ] Cross-reference validated (persona -> epic -> stories)
- [ ] Gaps flagged with severity

### Before saving file (Gate 4)

- [ ] Sheet names match template exactly
- [ ] Headers match template exactly
- [ ] All cells populated (no blanks for in-scope stories)
- [ ] Version mapping correct (P0/P/V1/V2)
- [ ] Scope mapping correct
- [ ] Gantt bars use dark blue fill (FF002060)
- [ ] Week headers merged correctly
- [ ] Text wrapping enabled on long columns
- [ ] Column widths set appropriately
- [ ] File opens without errors in Excel/LibreOffice
