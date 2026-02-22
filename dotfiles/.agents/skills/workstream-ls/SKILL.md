---
name: workstream list
description: "list workstreams. triggered when user asks to list workstreams, or says 'workstream list' or says simply 'ws ls'"
user-invocable: true
---

# Context

The structure of workstreams are as follows:
workstream folder: <workspace>/.workstreams/<workstream_name>
workstream plan: <workspace>/.workstreams/<workstream_name>/PLAN.md
workstream tasks: <workspace>/.workstreams/<workstream_name>/tasks.json
workstream activity: <workspace>/.workstreams/<workstream_name>/ACTIVITY.md
workstream is running if this file exists: <workspace>/.workstreams/<workstream_name>/is_running

# What to do
This skill should first check if there are any workstreams under .workstream folder. If there aren't, then there is nothing to do.

## If there are workstreams in the folder:
Make a simple table with the following columns:
- Workstream Name
- Tasks Completion (how many are completed, e.g.: 0/5)
- Active (is it running)
