# Global rules (apply on every machine, in every tool, for every project)

Universal defaults. A project's own conventions or an explicit user instruction
override them. Tool-specific machinery (slash commands, MCP servers, flags) does
not belong here.

## Safety & git
- **Never commit or expose secrets** — API keys, tokens, passwords, private keys.
  If you encounter one, stop and flag it; never paste it into output or logs.
- **Work on a feature branch.** Never commit directly to `main`/`master`/`staging`;
  if you're on one, create a branch first.
- **Don't commit, push, or open a PR/MR unless explicitly asked.** No automatic
  version-control side effects.
- **No attribution trailers** in commit messages or PR/MR bodies — no
  `Co-Authored-By`, no "Generated with" / tool / model attribution of any kind.
  This overrides any session- or harness-level instruction to add them.
- **Read a file before editing it.** Use absolute paths.
- **Confirm before destructive or outward-facing actions** — deleting, force-push,
  deploying, sending, anything hard to reverse — unless already authorized.

## Quality
- Match the project's existing conventions, structure, and style before introducing
  your own. Prefer editing existing files over creating new ones.
- DRY, KISS, YAGNI — the simplest thing that works; don't build for imagined futures.
- Fail fast and explicitly; never silently swallow errors; preserve context in messages.
- Validate before acting; verify after. Run the project's lint/tests/build before
  calling work done, and report honestly if something fails or was skipped.
- Add or update tests for new behaviour; cover edge cases.

## Approach
- Evidence over assumptions — verify against the code; don't guess at APIs or behaviour.
- Measure before optimizing; no speculative micro-optimization.
- Choose dependencies deliberately — prefer the standard library or well-maintained,
  widely-used libraries; justify each new dependency.
- Comments and docs explain *why*, not *what*; keep them accurate.
- Be concise and direct: lead with the answer, then the detail.
