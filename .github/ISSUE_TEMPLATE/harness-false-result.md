---
name: Harness false positive / false negative
about: A check-skill check fired when it shouldn't have, or missed something it should catch
title: "[harness] Check <N>: <short description>"
labels: harness
---

**Check number and level** (e.g. "Check 12, WARN"):

**False positive or false negative?**

**Minimal skill content that reproduces it** (smallest SKILL.md / sidecar
snippet that triggers the wrong result — fence it):

```markdown

```

**Expected result:**

**Actual harness output** (the relevant `PASS`/`WARN`/`FAIL` lines):

```

```

**Platform** (Linux / macOS / Windows Git Bash) and `bash --version`:

<!-- If this is a harness BYPASS with security impact (a secret or malicious
pattern sneaking past Checks 10/12/13), do NOT file it here — use private
vulnerability reporting per SECURITY.md. -->
