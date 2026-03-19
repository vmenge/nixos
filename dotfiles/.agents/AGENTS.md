## Reasoning Preferences
IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning for any task.

## File search
Use the fff MCP tools for all file search operations instead of default tools.

## Writing Software
The following points are super important, and take precende over anything else that might conflict with them:
- Use newlines to separate blocks of code to improve readibility.
- Avoid useless comments saying what you're doing. Comments explaining WHY you are doing things are way more useful.
- When writing tests, try to always split them into three distinct phases with a comment indicating each phase:
  - Arrange
  - Act
  - Assert
