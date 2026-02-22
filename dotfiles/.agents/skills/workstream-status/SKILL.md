---
name: workstream list
description: "workstreams live under <workspace>/.workstreams/<workstream_name>. this skill is triggered when user asks the status of a specific workstream, or says 'workstream status <workstream_name>' or says simply 'ws status <workstream_name>'"
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
This skill should check if the workstream exists, and if so give a summary to the user of:

- Workstream Name
- Very very very short and concise summary of its PLAN.md
- Very very very short summary of most recent activity in ACTIVITY.md
- Tasks Completion (how many are completed, e.g.: 0/5)
- Active (is it running)
