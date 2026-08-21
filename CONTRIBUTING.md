# Contributing to spm

Thank you for helping improve `spm`. Bug fixes, documentation improvements, tests, and focused feature proposals are welcome.

## Before you start

- Search [existing issues](https://github.com/0xWDG/spm/issues) before opening a new one.
- For a substantial behavior or interface change, open an issue first so the approach can be discussed.
- Never include credentials, private repository URLs, signing material, or personal configuration in an issue or commit.
- Report security vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## Set up the project

You need macOS 13 or later, Swift 6.0 or later, Xcode command-line tools, Git, and optionally [SwiftLint](https://github.com/realm/SwiftLint).

Swift 6.0 is the package's tools-version and compatibility baseline. New packages created by `spm` use the same baseline.

```sh
git clone https://github.com/0xWDG/spm.git
cd spm
swift build
swift test
```

## Make a change

1. Create a focused branch from `main`.
2. Keep behavior changes small and add or update tests in `Tests/spmTests`.
3. Update the README or symbol documentation when users or contributors need to know about the change.
4. Preserve the existing Swift file-header format and use the correct filename and date for new files.
5. Run the local checks before submitting your pull request.

```sh
swift build
swift test
swiftlint --strict
```

If SwiftLint is not installed, follow its upstream installation instructions or rely on the pull-request check.

## Pull requests

In the pull request description, explain the problem, the chosen solution, and how it was verified. Keep unrelated changes in separate pull requests. Screenshots are useful when output or generated documentation changes.

By submitting a contribution, you agree that it may be distributed under this repository's [MIT License](LICENCE.md).

Release preparation and Homebrew publication are documented separately in [RELEASING.md](RELEASING.md).
