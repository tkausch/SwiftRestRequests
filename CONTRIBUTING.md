## Contributing to SwiftRestRequests

Thanks for your interest in contributing! This guide summarizes how to work with the repository so you can open high-quality pull requests quickly.

### 1. Getting Started
- Install the latest Swift toolchain (5.9 or newer) or Xcode 26 on macOS.
- Clone the repository and resolve dependencies with `swift package resolve`.
- Optional: open `SwiftRestRequests.xcworkspace` if you prefer Xcode.

### 2. Branching & Commits
- Create a feature branch off `main` for every change.
- Keep commits focused; write concise messages (`component: short description`).
- Ensure commit authorship matches the identity associated with your GitHub account.

### 3. Coding Style
- Follow Swift API Design Guidelines and prefer clarity over cleverness.
- Use async/await for new networking APIs whenever possible.
- Keep files formatted with `swift-format` or Xcode’s default formatting.
- Add minimal, focused comments only where the intent is non-obvious.

### 4. Testing
- Add or update unit tests under `Tests/SwiftRestRequestsTests` when changing behavior.
- Run `swift test` (or the Xcode `SwiftRestRequests-Package` scheme) before submitting.
- For security-related changes, include regression tests or sample usage demonstrating the fix.

### 5. Documentation
- Update `README.md` or inline doc comments when you add new features.
- Include code samples or migration notes if the change impacts the public API.
- Keep version references in docs in sync with the latest tag (`git tag --sort=-creatordate | head` is handy).

### 6. Pull Requests
- Provide a short summary, detailed description, and testing notes in the PR body.
- Link related issues or discussions.
- Expect to address review feedback—collaboration is part of the process!

### 7. Releases
- Maintainers cut releases from `main` by updating the changelog and tagging (`git tag 1.x.x && git push --tags`).
- Snapshot builds should use pre-release suffixes (e.g. `1.7.0-beta.1`) to avoid breaking dependency consumers.

### 8. Code of Conduct
- Be respectful. We follow the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

Questions? Open a GitHub discussion or reach out via issues. We’re glad to have you here!
