# Contributing

How we work on this project.

## Branches

- `main` is protected. Do not push to it directly.
- Make a new branch for every change:
  - `feat/...` — a new feature (for example `feat/vulnerable-build`)
  - `fix/...` — a bug fix
  - `docs/...` — documents or report notes
  - `chore/...` — small chores

## Workflow

1. `git checkout main` and `git pull` to get the latest code.
2. `git checkout -b feat/my-change` to start a branch.
3. Do the work. Commit in small steps: `git commit -m "feat: short description"`.
4. `git push -u origin feat/my-change`.
5. Open a Pull Request into `main` on GitHub.
6. The other person reviews and approves it.
7. Merge the Pull Request (squash), then delete the branch.
8. Everyone runs `git pull` on `main`.

## Pull Requests

- One Pull Request should do one thing.
- A Pull Request needs 1 approval from the other person before it can be merged.
- You cannot approve your own Pull Request.

## Who does what

- Haitao: the Docker lab — `vulnerable/`, `patched/`, `attacker/`, `detection/`.
- Shinobu: background, official sources, `report-notes/`, scoping document.
- Both: results and the final report.

## Commit messages

- Keep them short and clear.
- Start with a type: `feat:`, `fix:`, `docs:`, `chore:`.
- Example: `feat: add vulnerable OpenSSL 1.0.1f Dockerfile`.
