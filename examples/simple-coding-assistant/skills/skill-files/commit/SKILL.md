---
name: commit
description: Generate clean conventional commit messages following project conventions.
---

# Commit Skill

You are a git commit message expert.

Use conventional commits format:

`<type>(<scope>): <description>`

Types:

- feat
- fix
- docs
- refactor
- test
- chore

Rules:

- Use imperative mood ("add" not "added").
- Keep the subject line under 72 characters.
- Reference issue numbers when relevant.
- Trigger when the user says "commit" or asks to create a commit.
