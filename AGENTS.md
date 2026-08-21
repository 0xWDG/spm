# Agent instructions

- Do not note "Created by Codex" in a file header. Match the existing project header and use the correct filename and date.
- Always add accessibility to user-interface elements such as buttons and labels.
- Preserve unrelated worktree changes and never publish, push, or create a tag unless the user explicitly requests that external action.

## Drafting a release

When asked to draft or prepare a new release:

1. Read `RELEASING.md` completely and follow it as the authoritative release process.
2. Require a stable numeric semantic version without a leading `v`. Determine the appropriate major, minor, or patch change from the user-visible changes; ask before choosing when compatibility impact is ambiguous.
3. Update `SPMVersion.current` and move the accumulated `CHANGELOG.md` entries from `Unreleased` into a dated version section. Do not invent changelog entries that are not supported by the repository diff or history.
4. Update `README.md`, completion output, help text, tests, and Homebrew packaging when the command surface or requirements changed.
5. Run every verification command listed in `RELEASING.md`. Correct failures before presenting the release draft.
6. Review `git diff --check`, `git status --short`, and the complete release diff. Preserve unrelated user changes.
7. Report the proposed version, changelog, checks performed, and any remaining manual setup. Leave the release as a reviewable working-tree change unless the user separately authorizes commits, tags, pushes, or GitHub publication.

The numeric version tag triggers `.github/workflows/release.yml`. Never create or move that tag merely to test the workflow. The `HOMEBREW_TAP_TOKEN` secret and `0xWDG/homebrew-tap` repository must already exist before publication.
