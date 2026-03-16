---
name: step
description: Walk through a multi-point topic step by step, pausing after each point to discuss with the user before continuing.
---

Break `$ARGUMENTS` into individual points. Go through ONE point at a time — explain it in detail, use `AskUserQuestion` with context-appropriate options, and wait for the user before continuing. Show progress like "**Step 3/10:**".
