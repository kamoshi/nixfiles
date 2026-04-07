---
name: commit-message
description: Write a concise git commit message for the current changes. Use when the user asks for a commit message, to summarize the staged diff, or to prepare a clean subject line before committing.
argument-hint: [focus]
disable-model-invocation: true
allowed-tools: Bash Read Grep Glob
---

Write a commit message for the current diff.

How to work:
- Inspect the staged diff first with `git diff --cached`.
- If nothing is staged, inspect the full working tree diff with `git diff`.
- Read enough context to understand the intent of the change before writing anything.
- If the optional argument is provided, use it as additional context, not as a replacement for reading the diff.

Message style for this repository:
- Prefer a single concise subject line.
- Match the existing history: short, lowercase, imperative, and without trailing punctuation.
- Do not force Conventional Commit prefixes unless the user explicitly asks for them.
- Focus on the user-visible or maintenance-relevant change, not the implementation trivia.
- Keep the subject specific enough to distinguish this change from nearby commits.

Output format:
- Return the proposed subject line in backticks.
- If the diff contains multiple unrelated changes, return 2 or 3 candidate subjects instead of pretending it is one clean commit.
- If the change is hard to summarize cleanly, say what is ambiguous and what to split.

Examples:
- `extract claude and codex into shared modules`
- `link claude skills from repo config`
- `pin gemini cli to 0.34.0`
