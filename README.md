# spm

spm is a Swift application for handling your swift packages.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F0xWDG%2Fspm%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/0xWDG/spm)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F0xWDG%2Fspm%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/0xWDG/spm)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
![License](https://img.shields.io/github/license/0xWDG/spm)

## Requirements

- Swift 6.3+
- macOS with Xcode command line tools installed

## Run from source

Clone the repository and run the executable target with Swift Package Manager:

```sh
git clone https://github.com/0xWDG/spm.git
cd spm
swift run spm
```

Pass commands after the executable name:

```sh
swift run spm header
swift run spm readme
swift run spm licence
swift run spm documentation
swift run spm test
swift run spm install owner/repository
```

## Compile

Build the project in debug mode:

```sh
swift build
```

Build an optimized release binary:

```sh
swift build -c release
```

The release executable is written to:

```sh
.build/release/spm
```

You can also use the built-in compile command to write a local `spm` binary in the project directory:

```sh
swift run spm executable
```

## Install

After building a release binary, copy it somewhere on your `PATH`:
or use the included install script to copy it to `/usr/local/bin` (requires `sudo` for write access):

```sh
sh ./build+install.sh
```

Then run it from any Swift package directory:

```sh
spm header
spm readme
spm licence
spm documentation
spm test
```

## Documentation

Build static web documentation with DocC:

```sh
spm documentation
```

By default, documentation is written to `docs/` and uses `/<package name>` as the static hosting base path.

Customize the target, output path, or hosting base path:

```sh
spm documentation --target spm --output-path docs --hosting-base-path /spm
```

## Configuration

Create a local project configuration:

```sh
spm config init
```

Create a global user configuration:

```sh
spm config global init
```

Configuration is stored as JSON in `.spm/config.json` for a project and `~/.config/spm/config.json` globally. Local configuration overrides global configuration.

Set values with:

```sh
spm config set name "Wesley de Groot"
spm config set email "email@example.com"
spm config set website "https://example.com"
spm config set github "0xWDG"
```

Custom templates can be stored in `.spm/` or `~/.config/spm/`, including `README.md`, `LICENCE.md`, `.editorconfig`, `.gitignore`, `.swiftlint.yml`, and Swift header templates.

## Contact

🦋 [@0xWDG](https://bsky.app/profile/0xWDG.bsky.social)
🐘 [mastodon.social/@0xWDG](https://mastodon.social/@0xWDG)
🐦 [@0xWDG](https://x.com/0xWDG)
🧵 [@0xWDG](https://www.threads.net/@0xWDG)
🌐 [wesleydegroot.nl](https://wesleydegroot.nl)
🤖 [Discord](https://discordapp.com/users/918438083861573692)

Interested learning more about Swift? [Check out my blog](https://wesleydegroot.nl/blog/).
