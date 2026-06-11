# Contributing

Thanks for helping improve 每日穿搭.

## Before You Start

- Keep the app local-first and privacy-friendly.
- Do not add cloud sync, analytics, ads, or network services without a clear product decision and documentation update.
- Do not commit real user photos, backup ZIP files, private paths, tokens, keystores, or signing files.
- Keep Android package name and release signing stable.

## Development

```powershell
flutter pub get
flutter test
flutter run
```

Release builds require Android signing files that are not committed to git. See [GitHub Release 自动打包](docs/06-operations/github-release.md).

## Pull Requests

Good pull requests should include:

- A clear summary of the behavior change
- Focused code changes
- Tests or manual verification notes
- Documentation updates when behavior, release flow, privacy, or storage changes

## Issues

Use the bug report template for defects and the feature request template for product ideas.
