---
name: workstream new
description: "Generate a Workstream plan for a new software feature or software implementation. Use when planning a feature, starting a new project, or planning out implementation of workstreams. Triggers on: create a workstream, write new workstream, plan this feature, requirements for, spec out."
user-invocable: true
---

# Output from this skill:

This should create two files:
1. .workstreams/<workstream_name>/PLAN.md
2. .workstreams/<workstream_name>/tasks.json

Before writing files, ask for feedback from the user by showing its full contents to them.

# PLAN.md
Create detailed design doc that is clear, actionable, and suitable for deriving implementation tasks.

## Structure
This design doc should contain:

1. Context
  A small description of the feature and the problem it solves.
2. Scope / Boundaries
   What are should we NOT do?
3. Approach
   How will we approach the implementation?
4. Key Design Decisions
   Guiding principles and decisions that led to chosen approach.
5. Critical Files
   List of files that are critical to the implementation.
6. Testing Strategy
   How will we test the implementation?
7. Verification Steps / Success Criteria
   How will we know it's done?

## Writing Guidelines
The design doc may be a junior developer or AI agent. Therefore:

- Be explicit and unambiguous
- Avoid jargon or explain it
- Provide enough detail to understand purpose and core logic
- Number requirements for easy reference
- Use concrete examples where helpful

# tasks.json
The output of tasks.json will be based on the generated PLAN.md. First generate the PLAN.md file, then, once the user is satisfied with it, generate the tasks.json file following this blueprint:

```json
[
  {
    "category": "setup",
    "description": "Initialize project structure and dependencies",
    "steps": [
      "Create project directory structure",
      "Initialize package.json or requirements",
      "Install required dependencies",
      "Verify files load correctly"
    ],
    "passes": false
  },
  {
    "category": "feature",
    "description": "Implement main navigation component",
    "steps": [
      "Create Navigation component",
      "Add responsive styling",
      "Implement mobile menu toggle"
    ],
    "passes": false
  },
  {
    "category": "feature",
    "description": "Implement hero section with CTA",
    "steps": [
      "Create Hero component",
      "Add headline and subhead",
      "Style CTA button",
      "Center content properly"
    ],
    "passes": false
  },
  {
    "category": "testing",
    "description": "Verify all components render correctly",
    "steps": [
      "Test responsive layouts",
      "Check console for errors",
      "Verify all links work"
    ],
    "passes": false
  }
]
```
