# CLAUDE.md — Project Instructions for Claude Code

## Build & Test
- Build: `swift build`
- Test: `swift test` (75+ tests, ~5 seconds)
- Build app bundle: `./Scripts/build-app.sh`
- Lint: SwiftLint runs automatically via pre-commit hook

## Versioning Workflow
When making any code change (feature, fix, refactor):
1. Create a feature branch from main
2. Make code changes and add/update tests
3. Bump version: `./Scripts/bump-version.sh [major|minor|patch]`
   - `fix:` commits → patch
   - `feat:` commits → minor
   - Breaking changes → major
4. Update CHANGELOG.md with a new version section (Keep a Changelog format)
5. Commit, push, and create PR
6. After merge, GitHub Actions auto-creates the git tag and release

## Commit Convention
Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`

## Project Structure
- `Sources/ScreenshotRenamer/` — app source code
- `Tests/ScreenshotRenamerTests/` — unit tests
- `Scripts/` — build and version management scripts
- `VERSION` — single source of truth for version number
- `CHANGELOG.md` — Keep a Changelog format
