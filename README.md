# spm

`spm` is a command-line companion for Swift Package Manager projects. It can scaffold package files, apply reusable project templates, build and test packages, generate DocC documentation, and add package dependencies to an Xcode project.

[![Build](https://github.com/0xWDG/spm/actions/workflows/build.yml/badge.svg)](https://github.com/0xWDG/spm/actions/workflows/build.yml)
[![Tests](https://github.com/0xWDG/spm/actions/workflows/tests.yml/badge.svg)](https://github.com/0xWDG/spm/actions/workflows/tests.yml)
[![SwiftLint](https://github.com/0xWDG/spm/actions/workflows/swiftlint.yml/badge.svg)](https://github.com/0xWDG/spm/actions/workflows/swiftlint.yml)
[![Swift Package Index](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F0xWDG%2Fspm%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/0xWDG/spm)
[![License](https://img.shields.io/github/license/0xWDG/spm)](LICENCE.md)

## Features

- Create a new Swift package with common repository files.
- Generate or update file headers, README, licence, EditorConfig, Git ignore, and SwiftLint files.
- Share author details and templates through local or global configuration.
- Build selected Apple platforms or use native SwiftPM, run tests, and generate static DocC documentation.
- Add, selectively link, preview, and remove remote packages in an existing Xcode project.
- Validate the development environment, generate shell completions, and emit automation-friendly output.

## Requirements

- macOS 13 or later
- Swift 6.0 or later
- Xcode and its command-line tools
- Git for commands that inspect remote packages

## Installation

### Homebrew

After the first tagged release, install `spm` from the official project tap:

```sh
brew install 0xWDG/tap/spm
```

The tap formula builds the tagged source, installs completions for Bash, Zsh, and Fish, and verifies the installed command. Release archives and their checksums are published with each GitHub release.

### Installation script

Clone the repository and run the installation script:

```sh
git clone https://github.com/0xWDG/spm.git
cd spm
./build+install.sh
```

The script builds an optimized executable and installs it at `~/.local/bin/spm` by default. Add that directory to `PATH` if needed. To choose another prefix, set `SPM_INSTALL_PREFIX`; administrator privileges are requested only when the selected location is not writable:

```sh
SPM_INSTALL_PREFIX=/usr/local ./build+install.sh
```

To build without installing:

```sh
swift build -c release
swift run spm config show
```

## Quick start

Run commands from the root of a Swift package unless a command says otherwise:

```sh
# Create a package in the current directory.
spm create ExamplePackage

# Build and test an existing package.
spm build
spm test

# Generate static documentation in docs/.
spm documentation
```

Run `spm` without arguments to print the built-in command reference. The command exits with a nonzero status after showing help when no command was supplied.

Help uses color when written to a terminal while retaining textual headings and labels. Set `NO_COLOR=1` or pass `--no-color` to disable ANSI styling; set `FORCE_COLOR=1` to enable it for non-terminal output.

## Commands

| Command | Description |
| --- | --- |
| `spm create <name> [--type <type>] [--path <path>]` | Initialize a library, executable, tool, or empty package at a selected path. |
| `spm header [options]` | Replace Swift headers, optionally scoped with repeatable `--include` and `--exclude` paths. |
| `spm readme [--force\|--dry-run]` | Generate `README.md`. |
| `spm licence [--force\|--dry-run]` | Generate `LICENCE.md`. |
| `spm editorconfig [--force\|--dry-run]` | Generate `.editorconfig`. |
| `spm gitignore [--force\|--dry-run]` | Generate `.gitignore`. |
| `spm swiftlint [--force\|--dry-run]` | Generate `.swiftlint.yml`. |
| `spm diff <generator>` | Print the changes a generator would make as a unified diff. |
| `spm build [options]` | Build selected Apple platforms with Xcode, or pass `--native` to use `swift build`. |
| `spm test [options]` | Run `swift test` and forward any additional options. |
| `spm documentation [options]` | Generate static DocC documentation. |
| `spm install <package> [options]` | Add a remote package, optionally selecting products and native targets. |
| `spm uninstall <package> [--dry-run]` | Remove a package, its product links, and build-file references. |
| `spm config ...` | Create, inspect, validate, update, unset, or reset configuration. |
| `spm completion <zsh\|bash\|fish>` | Print a shell completion script. |
| `spm doctor` | Check Swift, Git, DocC, SwiftLint, the manifest, and configuration. |
| `spm version` | Print the current version. `--version` and `-v` are aliases. |
| `spm executable [--force\|--dry-run]` | Build and copy a local `./spm` executable from an `spm` source checkout. |

Generators create missing files but refuse to replace existing files by default. Use `--dry-run` to preview affected paths, `--diff` to inspect content changes, or `--force` to replace files. The `header` command always requires one of these safety options because it operates on multiple Swift files.

Global flags can appear anywhere in a command: `--quiet` suppresses informational output, `--no-color` disables ANSI styling, and `--json` requests structured output from commands that support it.

### Build options

```sh
spm build --native --configuration release
spm build --platform macOS,iOS --scheme ExamplePackage
spm build --platform iOS --destination 'platform=iOS Simulator,name=iPhone 17'
```

Use repeatable `--platform` flags or a comma-separated list. Supported configurations are `debug` and `release`.

### Add a package to Xcode

From a directory containing exactly one `.xcodeproj`, pass a full Git URL, `owner/repository`, or a repository name:

```sh
spm install https://github.com/apple/swift-collections.git
spm install apple/swift-collections --product Collections --target ExampleApp
spm install apple/swift-collections --dry-run
spm uninstall swift-collections --dry-run
```

Installation accesses the remote repository to identify versions and library products. By default it links every discovered library product to every compatible native target. Repeat `--product` or `--target` to narrow that selection. Install and uninstall write a timestamped `project.pbxproj.backup-*` before saving and roll back the active transaction if a write fails. Review the resulting project diff before committing it.

### Shell completion

Generate completion code from the executable so it stays aligned with the installed version:

```sh
# zsh
spm completion zsh > "${fpath[1]}/_spm"

# bash
spm completion bash > ~/.local/share/bash-completion/completions/spm

# fish
spm completion fish > ~/.config/fish/completions/spm.fish
```

### Generate documentation

```sh
spm documentation \
    --target SPMCore \
    --output-path docs \
    --hosting-base-path /spm
```

The defaults are the package name for the target, `docs` for the output directory, and `/<package-name>` for the hosting base path. The published API documentation is available at [0xwdg.github.io/spm](https://0xwdg.github.io/spm/).

## Configuration

Project configuration is stored in `.spm/config.json`; global configuration is stored in `~/.config/spm/config.json`. Project values override global values, and unspecified values use the built-in defaults.

```sh
spm config init
spm config global init
spm config show
spm config validate
spm config set name "Wesley de Groot"
spm config unset name
spm config global set github "0xWDG"
spm config global reset
```

Supported keys are:

| Key | Purpose |
| --- | --- |
| `name`, `email`, `website`, `github` | Author metadata used by generated files. |
| `readme`, `licence`, `swiftFileHeader` | Inline template content or a path to a template. |
| `editorconfig`, `gitignore`, `swiftLintRules` | Inline file content or a path to a template. |

Templates may be referenced explicitly in configuration or placed in `.spm/` or `~/.config/spm/` under a supported destination name. The following placeholders are replaced when a template is rendered:

- `PACKAGENAME` or `{{packageName}}`
- `{{filename}}`
- `{{name}}`, `{{email}}`, `{{website}}`, and `{{github}}`
- `{{year}}`

Keep `.spm/config.json` out of version control when it contains personal or project-local values.

## Development

The package has two targets: `SPMCore` contains reusable, testable operations, while the `spm` executable is responsible only for translating thrown errors into process exit statuses.

```sh
swift build
swift test
swiftlint --strict
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution workflow. Bug reports and feature requests are welcome through [GitHub Issues](https://github.com/0xWDG/spm/issues).

Maintainers should follow [RELEASING.md](RELEASING.md) when preparing immutable tags and Homebrew updates. User-facing changes are recorded in [CHANGELOG.md](CHANGELOG.md).

## Security

Please do not open a public issue for a suspected vulnerability. Follow the private reporting instructions in [SECURITY.md](SECURITY.md).

## License

`spm` is available under the [MIT License](LICENCE.md).

## Acknowledgements


## Contact

🦋 [@0xWDG](https://bsky.app/profile/0xWDG.bsky.social)
🐘 [mastodon.social/@0xWDG](https://mastodon.social/@0xWDG)
🐦 [@0xWDG](https://x.com/0xWDG)
🧵 [@0xWDG](https://www.threads.net/@0xWDG)
🌐 [wesleydegroot.nl](https://wesleydegroot.nl)
🤖 [Discord](https://discordapp.com/users/918438083861573692)

## Disclaimer

This project was started as a personal tool to simplify Swift package development. It is not affiliated with Apple or the Swift project. Use it at your own risk. since it became broader for than only my personal use, I have decided to make it public and a lot of functions (xcodeproject manipulation are made using agentic programming).
