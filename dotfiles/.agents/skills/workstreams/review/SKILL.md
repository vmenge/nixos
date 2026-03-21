---
name: workstream-review
description: Use when reviewing executed work for a repository workstream against `design.md`, `plan.md`, `tasks.json`, and recent execution history after `workstream-execute` completes. Trigger phrases: "ws review", "workstream review".
---

# Code Review Agent

Use workstream-about skill for more context on workstreams.
You are reviewing code changes for the implementation of a workstream.

**Your task:**
1. Review what was implemented in this workstream
2. Compare against `design.md`, `plan.md`, `tasks.json`, and recent `activity.json`
3. Check code quality, architecture, testing
4. Categorize issues by severity
5. Assess production readiness
6. Write ALL findings to `review.md` if follow-up work is needed
7. Only when all previous steps are done, invoke workstream-tasks to update remaining work based on `review.md`

If the review has passed and there are no points to address, then delete `review.md`.
If the review has passed and there are no undone tasks left in `tasks.json`, output <promise>COMPLETE</promise>.
If the review finds issues, keep `review.md` and hand off to workstream-tasks.

## Review Checklist

**Code Quality:**
- Clean separation of concerns?
- Proper error handling?
- Type safety (if applicable)?
- DRY principle followed?
- Edge cases handled?

**Architecture:**
- Sound design decisions?
- Scalability considerations?
- Performance implications?
- Security concerns?

**Testing:**
- Tests actually test logic (not mocks)?
- Edge cases covered?
- Integration tests where needed?
- All tests passing?

**Requirements:**
- All `design.md` requirements met?
- All `plan.md` acceptance criteria met?
- Implementation matches spec?
- No scope creep?
- Breaking changes documented?

**Production Readiness:**
- Migration strategy (if schema changes)?
- Backward compatibility considered?
- Documentation complete?
- No obvious bugs?

## `review.md` Output Format

### Strengths
[What's well done? Be specific.]

### Issues

#### Critical (Must Fix)
[Bugs, security issues, data loss risks, broken functionality]

#### Important (Should Fix)
[Architecture problems, missing features, poor error handling, test gaps]

#### Minor (Nice to Have)
[Code style, optimization opportunities, documentation improvements]

**For each issue:**
- File:line reference
- What's wrong
- Why it matters
- How to fix (if not obvious)

### Recommendations
[Improvements for code quality, architecture, or process]

## Critical Rules

**DO:**
- Categorize by actual severity (not everything is Critical)
- Be specific (file:line, not vague)
- Explain WHY issues matter
- Acknowledge strengths
- Give clear verdict

**DON'T:**
- Say "looks good" without checking
- Mark nitpicks as Critical
- Give feedback on code you didn't review
- Be vague ("improve error handling")
- Avoid giving a clear verdict

## Example Output

```
### Strengths
- Clean database schema with proper migrations (db.ts:15-42)
- Comprehensive test coverage (18 tests, all edge cases)
- Good error handling with fallbacks (summarizer.ts:85-92)

### Issues

#### Important
1. **Missing help text in CLI wrapper**
   - File: index-conversations:1-31
   - Issue: No --help flag, users won't discover --concurrency
   - Fix: Add --help case with usage examples

2. **Date validation missing**
   - File: search.ts:25-27
   - Issue: Invalid dates silently return no results
   - Fix: Validate ISO format, throw error with example

#### Minor
1. **Progress indicators**
   - File: indexer.ts:130
   - Issue: No "X of Y" counter for long operations
   - Impact: Users don't know how long to wait

### Recommendations
- Add progress reporting for user experience
- Consider config file for excluded projects (portability)
```
