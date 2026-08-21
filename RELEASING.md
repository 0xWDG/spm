# Releasing spm

Releases use an immutable numeric semantic-version tag such as `0.1.0`. Pushing that tag verifies the project, publishes a GitHub release, and updates `0xWDG/homebrew-tap`.

## One-time setup

1. Create the public repository `0xWDG/homebrew-tap` with a `Formula` directory.
2. Create a fine-grained GitHub token with contents read/write access to that repository.
3. Add the token to this repository as the Actions secret `HOMEBREW_TAP_TOKEN`.
4. Protect the `main` branch in both repositories and require their CI checks. Configure the tap rules to allow the release-token identity to update `Formula/spm.rb`.

## Prepare a release pull request

1. Choose a stable semantic version without a leading `v`.
2. Update `SPMVersion.current` in `Sources/spm/SPMVersion.swift`.
3. Move the entries under `Unreleased` in `CHANGELOG.md` to a heading containing the version and release date. Restore an empty `Unreleased` heading.
4. Confirm user-facing commands, requirements, and installation instructions in `README.md` are current.
5. Run the complete verification suite:

   ```sh
   swift build
   swift test
   swiftlint --strict
   swift build -c release
   test "$(.build/release/spm --version)" = "spm VERSION"
   git diff --check
   ```

6. Open a release pull request titled `Prepare VERSION` and include the changelog summary and verification results.

Do not create the tag from an uncommitted or unmerged worktree.

## Publish

After the release pull request is merged and `main` is green:

```sh
git switch main
git pull --ff-only
git tag -a VERSION -m "spm VERSION"
git push origin VERSION
```

The Release workflow then:

- verifies that the tag matches `SPMVersion.current`;
- runs the build, tests, and strict linting;
- computes the GitHub source archive checksum;
- renders, installs, and tests the Homebrew formula;
- updates `0xWDG/homebrew-tap`;
- publishes release notes, `SHA256SUMS`, and the rendered formula.

Confirm the workflow succeeded before announcing the release:

```sh
brew update
brew install 0xWDG/tap/spm
brew test 0xWDG/tap/spm
spm --version
```

Tags are immutable. If publication fails, fix the workflow and rerun it; never move or recreate the release tag.
