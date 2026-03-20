Review all current changes (staged, unstaged, and untracked files) and create a well-organized commit.

## Steps

1. Run `git status` to see all changes and `git diff` (staged + unstaged) to understand what changed.
2. Run `git log --oneline -5` to match the repository's existing commit message style.
3. Decide which files to stage. Group related changes logically:
   - If all changes are related, create a single commit.
   - If changes span unrelated concerns (e.g., a bug fix + a new feature + config changes), create separate commits for each group.
4. Do NOT commit files that contain secrets (`.env`, credentials, tokens, keys). Warn if any are detected.
5. For each commit:
   - Stage only the relevant files by name (never use `git add -A` or `git add .`).
   - Write a concise commit message (1-2 sentences) that focuses on the **why**, not the what.
   - Use conventional format when it fits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`.
6. Run `git status` after all commits to confirm a clean working tree (aside from intentionally untracked files).
