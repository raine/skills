---
name: cs
description: Commit all pending changes as separate, logical commits using git-surgeon.
---

/git-surgeon Commit all pending changes as separate, logical commits. Group
related changes together by feature, bug fix, or concern. Separate unrelated
changes into distinct commits. Keep commits atomic — each should make sense on
its own. Order commits so earlier ones don't depend on later ones when possible.
Use line ranges when a hunk contains changes belonging to different groups.
