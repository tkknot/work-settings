# 統合Cursor Rules
最終更新日: 2024年3月25日

## 目次
1. [shortcuts.mdc](#1-shortcutsmdc)
2. [branch.mdc](#2-branchmdc)
3. [git.mdc](#3-gitmdc)
4. [language.mdc](#4-languagemdc)
5. [directory.mdc](#5-directorymdc)
6. [development.mdc](#6-developmentmdc)

<a id="1-shortcutsmdc"></a>
## 1. shortcuts.mdc
元ファイル: `.cursor/rules/shortcuts.mdc`

---
description: 
globs: 
alwaysApply: false
---
---
description: Shortcut aliases for development commands
globs: ["**/"]
alwaysApply: true
---
# Shortcut Aliases

## Consulting Commands
- `/ask`: "Please provide a multi-faceted analysis and specific proposals for the following issue: [ISSUE]. 
  Consider the following aspects: 
  1) Pros and cons
  2) Technical feasibility
  3) Risks and countermeasures
  4) Alternative solutions. 
  Present the analysis in bullet points and conclude with a recommended solution."

- `/plan`: "Please create a detailed work plan for implementing the following feature: [FEATURE]. 
  Include: 
  1) Prerequisites and constraints
  2) Detailed work items (with time estimates)
  3) Dependencies
  4) Risks and countermeasures
  5) Success criteria. 
  Present the plan in phases with clear objectives for each phase."

## Debugging & Improvement Commands
- `/debug`: "Please perform systematic debugging for the following bug: [BUG SYMPTOMS]. 
  Steps: 
  1) List 5-7 possible causes
  2) Evaluate each cause (high/medium/low probability)
  3) Propose verification methods
  4) Narrow down to 1-2 most likely causes
  5) Present specific fix proposals. 
  Consider logs and error messages if available."

- `/refactor`: "Please refactor the following code: [CODE]. 
  Propose improvements in these aspects: 
  1) Readability
  2) Maintainability
  3) Performance
  4) Testability. 
  Include rationale for each improvement and prioritize them. 
  Show before/after code comparison."

## Documentation & Comments Commands
- `/doc`: "Please create documentation for the following code: [CODE]. 
  Include: 
  1) Overview and purpose
  2) Architecture/design explanation
  3) Key functionality details
  4) API specifications (input/output, exceptions)
  5) Usage examples
  6) Important notes. 
  Use diagrams where appropriate."

- `/cmt`: "Please add comments to the following code: [CODE]. 
  Comments should clarify: 
  1) Intent and purpose of processing
  2) Important prerequisites
  3) Special logic explanation
  4) Potential risks and considerations. 
  Keep comments concise while providing necessary information without compromising code readability."

- `/log`: "Please add logging to the following code: [CODE]. 
  Consider: 
  1) Appropriate log levels (ERROR/WARN/INFO/DEBUG)
  2) Information needed for operational monitoring
  3) Performance impact
  4) Handling of personal/confidential information. 
  Propose specific log messages and output timing."

## Code Quality Commands
- `/test`: "Please create tests for the following code: [CODE]. 
  Include these test cases: 
  1) Normal cases
  2) Error cases
  3) Boundary values
  4) Edge cases. 
  Specify test purposes and expected results, and indicate mock/stub usage strategy."

- `/review`: "Please review the following code: [CODE]. 
  Check these aspects: 
  1) Functional requirements compliance
  2) Coding standards adherence
  3) Security
  4) Performance
  5) Error handling
  6) Test coverage. 
  Provide feedback with priority levels (high/medium/low)."

- `/explain`: "Please explain the following code in detail: [CODE]. 
  Include: 
  1) Overall process flow
  2) Key variables/functions roles
  3) Algorithm explanation
  4) Design considerations
  5) Potential issues. 
  Use diagrams where appropriate."

- `/rewrite`: "Please suggest alternative implementation approaches for the following code: [CODE].
  Consider multiple different implementation patterns focusing on these aspects:
  1) Readability and maintainability improvement
  2) Efficiency and performance optimization
  3) Usage of modern language features and best practices
  4) Error handling improvement
  5) Extensibility enhancement
  6) Different implementation patterns within the same language (functional, object-oriented, etc.)
  For each implementation pattern, explain advantages, disadvantages, and when to choose it.
  Provide a recommendation on the preferred pattern and rationale."

- `/tdd`: "Please guide me through Test-Driven Development.

  TDD Process:
  0) First, create a TODO list in 'doc/tdd/todo.md' (create the file if it doesn't exist).
     Break down the feature or problem into specific, concrete tasks in this list.
  
  Repeat the following cycle for each task:
  1) Select the next task from the TODO list
  2) Write a failing test that defines the expected behavior
  3) Implement minimal code to make the test pass
  4) Verify the test passes
  5) When the test passes, use the `/commit` command to commit changes (excluding todo.md)
  6) Refactor the code while ensuring tests still pass
  7) After refactoring, use the `/commit` command again to commit changes
  8) Remove the completed task from the TODO list
  9) Repeat the above steps until all items in todo.md are completed
  
  For each cycle, provide:
  - Clear test assertions and expected outcomes
  - Implementation suggestions with minimal viable code
  - Refactoring recommendations to improve code quality
  - Considerations for edge cases and error handling
  
  Start with the simplest tasks and progressively handle more complex ones.
  Once all TODO items are completed, confirm that the development is complete."

## Git Operation Commands
- `/commit`: "Committing the following changes: [CHANGES]. 
  Create commit message with: 
  1) Prefix selection
  2) Change summary (within 50 chars)
  3) Detailed change description
  4) Related Issues/tickets. 
  Evaluate if changes should be split into logical commit units."

- `/pr`: "Creating a pull request for the following changes: [CHANGES]. 
  Include: 
  1) Change summary
  2) Detailed description
  3) Related issues/tickets
  4) Reviewers
  5) Labels/milestones. 
  Evaluate if changes should be split into logical commit units."

- `/push`: "Pushing the following changes to remote repository: [BRANCH]. 
  Pre-push checks: 
  1) Commit logic
  2) Test execution results
  3) Code review status
  4) Conflict status. 
  Evaluate need for rebase or squash."

- `/pull`: "Fetching latest changes from remote repository: [BRANCH]. 
  Execute: 
  1) Check local work status
  2) Determine fetch strategy (merge/rebase)
  3) Confirm conflict resolution policy. 
  Provide conflict resolution steps if conflicts occur."

- `/prcomment`: "Create review comments for the pull request of the current branch.
  Execute automatically with the following steps:
  1) Get the current branch name
  2) Identify the associated pull request
  3) Analyze branch changes:
     - List of modified files
     - Changes in each file (additions/deletions/modifications)
  4) Post generated comments to the pull request"

- `/checkout`: "Switching to or creating branch: [BRANCH].
  Pre-checkout checks:
  1) Current work status (uncommitted changes)
  2) Branch existence check
  3) Remote branch status
  4) Base branch selection if creating new.
  Provide stash recommendations if needed and post-checkout steps."

## Diagram Creation Commands
- `/draw`: "Please create a diagram for the following content: [CONTENT]. 
  Include these elements: 
  1) Overall structure
  2) Component relationships
  3) Data flow
  4) Key interfaces. 
  Keep the diagram concise and easy to understand, add supplementary explanations as needed."

## Utility Commands
- `/mergerules`: "Please perform the following tasks:
  1) Find all `.cursor/rules/*.mdc` files in the project
  2) Collect the contents of each file
  3) Create a new file `.cursor/doc/masterrules.md` (create directory if it doesn't exist)
  4) Consolidate all rules' Front Matter (the parts surrounded by `---`) and contents
  5) Report the path of the consolidated file and the number of rules included" 

<a id="2-branchmdc"></a>
## 2. branch.mdc
元ファイル: `.cursor/rules/branch.mdc`

---
description: Branch management rules
globs: 
alwaysApply: false
---
---
description: Branch management rules
globs: ["**/.git/**"]
alwaysApply: true
---
# Branch Management
## Branch Types
- main: "Production ready code"
- develop: "Development integration branch"
- feature/*: "New feature development branches"
- bugfix/*: "Bug fix branches"
- refactor/*: "Refactor branches"
- update/*: "Update feature branches"
- docs/*: "Documentation updates"

## Branch Protection
```
DO NOT MERGE TO MAIN/MASTER BRANCH WITHOUT PULL REQUEST AND APPROVAL
```

<a id="3-gitmdc"></a>
## 3. git.mdc
元ファイル: `.cursor/rules/git.mdc`

---
description: "
globs: 
alwaysApply: false
---
---
description: Git rules and commit prefixes
globs: ["**/.git/**", "**/.gitignore"]
alwaysApply: true
---
# Git Rules
## command
- Always add --no-pager when running Git commands
- Do not push to remote until instructed

## commit-prefixes:
- feat: "Adding new features"
- update: "Modifying features"
- fix: "Bug fixes or typo corrections"
- docs: "Adding documentation"
- style: "Formatting changes, import order adjustments, or adding comments"
- refactor: "Code refactoring without affecting functionality"
- test: "Adding or modifying tests"
- ci: "Changes related to CI/CD"
- docker: "Modifications to Dockerfile or container-related changes"
- chore: "Miscellaneous changes"
- init: "Project initialization and setup"
- build: "Changes to build system or external dependencies"
- perf: "Performance improvement changes"
- revert: "Reverting previous commits"
- i18n: "Internationalization changes"
- a11y: "Accessibility changes"
- security: "Security-related changes"

<a id="4-languagemdc"></a>
## 4. language.mdc
元ファイル: `.cursor/rules/language.mdc`

---
description: 
globs: 
alwaysApply: false
---
---
description: Language settings
globs: ["**/"]
alwaysApply: true
---
# Language Settings
All messages required in Japanese.

<a id="5-directorymdc"></a>
## 5. directory.mdc
元ファイル: `.cursor/rules/directory.mdc`

---
description: 
globs: 
alwaysApply: false
---
---
description: Directory structure rules
globs: ["**/"]
alwaysApply: true
---
# Directory Structure
TODO: Customize directory structure based on adopted technologies and project requirements

<a id="6-developmentmdc"></a>
## 6. development.mdc
元ファイル: `.cursor/rules/development.mdc`

---
description: 
globs: 
alwaysApply: false
---
---
description: Development flow and processes
globs: ["**/"]
alwaysApply: true
---
# Development Flow
## feature_development_steps
1. Create a new branch
2. Execute initialization commands (e.g., bun init, uv init)
3. Initialize git
4. Verify and create the recommended directory structure if missing
5. Install required libraries
6. Confirm readiness to start development using commands
7. Implement the feature/changes
8. Run tests
9. Fix any failing tests
10. Commit once tests pass
11. Write changelog in CHANGELOG.md
12. Write change in docs/**.md

## bug_fix_steps
1. Carefully investigate affected areas
2. Create a new branch
3. Implement the changes
4. Run tests
5. Fix any failing tests
6. Commit once tests pass
7. Write changelog in CHANGELOG.md
8. Write change in docs/**.md 