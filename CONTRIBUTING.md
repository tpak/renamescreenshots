# Contributing to Screenshot Renamer

Thank you for your interest in contributing to Screenshot Renamer! This document provides guidelines and workflows for development and releases.

## Development Workflow

### Prerequisites

- **macOS 11.0 (Big Sur)** or later
- **Xcode 14+** with command line tools
- **Swift 5.7+**
- **Git**

### Setting Up

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/renamescreenshots.git
   cd renamescreenshots
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/tpak/renamescreenshots.git
   ```

### Making Changes

1. **Create a feature branch** from `main`:
   ```bash
   git checkout main
   git pull upstream main
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Follow Swift API design guidelines
   - Write clear, descriptive commit messages
   - Add/update tests for new functionality
   - Keep changes focused and atomic

3. **Update CHANGELOG.md**:
   - Add your changes under the "Unreleased" section
   - Follow the format: `- Description (#PR-number if available)`
   - Categorize under: Added, Changed, Deprecated, Removed, Fixed, or Security

4. **Run tests**:
   ```bash
   swift test
   ```
   All 45 tests must pass before submitting.

5. **Build locally**:
   ```bash
   ./Scripts/build-app.sh
   ```
   Verify the app builds and runs correctly.

6. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

7. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

8. **Create a Pull Request**:
   - Go to the original repository on GitHub
   - Click "New Pull Request"
   - Select your feature branch
   - Provide a clear description of your changes
   - Reference any related issues

## Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/) for clear, standardized commit messages:

### Format

```
<type>: <description>

[optional body]

[optional footer]
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, no logic changes)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks (dependencies, build, etc.)

### Examples

```bash
feat: add thumbnail preview toggle

fix: resolve initialization crash on launch

docs: update installation instructions

test: add duplicate filename handling tests

chore: bump version to 1.1.0
```

## Automated Builds

### Continuous Integration

Every push to `main` automatically triggers:
- **Build and test** on macOS latest
- **Creation of "latest" pre-release** with downloadable artifacts
- **Security scanning** with CodeQL

Available at: https://github.com/tpak/renamescreenshots/releases/tag/latest

### Pull Request Validation

Every PR triggers:
- Full test suite
- Build verification
- CodeQL security analysis
- 7-day artifact retention for review

## Creating a Release

### Version Numbering

We use [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes, incompatible API
- **MINOR** (1.0.0 → 1.1.0): New features, backwards compatible
- **PATCH** (1.0.0 → 1.0.1): Bug fixes, backwards compatible

### Release Process

#### 1. Update CHANGELOG.md

Move "Unreleased" changes to a new version section:

```markdown
## [Unreleased]

## [1.1.0] - 2026-01-15

### Added
- New feature description

### Fixed
- Bug fix description
```

Add comparison links at the bottom:

```markdown
[Unreleased]: https://github.com/tpak/renamescreenshots/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/tpak/renamescreenshots/compare/v1.0.0...v1.1.0
```

#### 2. Bump Version

Edit the `/VERSION` file:

```bash
echo "1.1.0" > VERSION
```

#### 3. Commit Version Bump

```bash
git add VERSION CHANGELOG.md
git commit -m "chore: bump version to 1.1.0"
```

#### 4. Create and Push Tag

```bash
git tag v1.1.0
git push origin main
git push origin v1.1.0
```

#### 5. GitHub Actions Takes Over

The `release-tag.yml` workflow automatically:
- Verifies VERSION file matches tag
- Runs full test suite
- Builds release binary
- Creates ZIP and DMG artifacts
- Generates SHA256 checksums
- Creates GitHub release with changelog
- Uploads all artifacts

#### 6. Verify Release

1. Visit https://github.com/tpak/renamescreenshots/releases
2. Verify the release was created
3. Download and test artifacts locally:
   ```bash
   # Download and verify
   shasum -a 256 -c ScreenshotRenamer.zip.sha256

   # Extract and test
   unzip ScreenshotRenamer.zip
   open ScreenshotRenamer.app
   ```
4. Edit release notes if needed

## Testing

### Running Tests

```bash
# Run all tests
swift test

# Run specific test
swift test --filter ScreenshotRenamerTests

# Run with verbose output
swift test --verbose
```

### Test Coverage

We maintain comprehensive test coverage:
- Pattern matching (13 tests)
- File validation (12 tests)
- Screenshot detection (10 tests)
- Shell command execution (5 tests)
- Screenshot renaming (5 tests)

**Total: 45 tests**

### Writing Tests

- Follow existing patterns in `Tests/ScreenshotRenamerTests/`
- Use descriptive test names: `testHandlesDuplicateFilenames()`
- Test both success and failure cases
- Clean up test files in teardown
- Use XCTest framework conventions

## Code Style

### Swift Guidelines

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep functions focused and single-purpose
- Prefer immutability (`let` over `var`)

### Project Structure

```
Sources/ScreenshotRenamer/
├── App/              # Application lifecycle and UI
├── Core/             # Core business logic
├── FileWatcher/      # File monitoring
├── Models/           # Data models
├── Utilities/        # Helper utilities
└── Resources/        # Assets and configuration
```

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/tpak/renamescreenshots/issues)
- **Discussions**: [GitHub Discussions](https://github.com/tpak/renamescreenshots/discussions)
- **Email**: Check the repository for contact information

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the issue, not the person
- Help create a welcoming environment

## License

By contributing to Screenshot Renamer, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be acknowledged in:
- Release notes
- GitHub Contributors page
- CHANGELOG.md (for significant contributions)

Thank you for contributing to Screenshot Renamer! 🎉
