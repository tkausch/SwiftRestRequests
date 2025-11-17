# Publishing DocC Documentation

This guide explains how to build and publish the DocC documentation for SwiftRestRequests.

## Prerequisites

- Xcode 15.0 or later
- Swift 5.9 or later
- GitHub repository with Pages enabled

## Building Documentation Locally

### Quick Build

Run the helper script:

```bash
./scripts/build-docc.sh
```

### Manual Build

```bash
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target SwiftRestRequests \
  --output-path ./docs \
  --transform-for-static-hosting \
  --hosting-base-path SwiftRestRequests
```

### Preview Locally

After building, you can preview the documentation locally:

```bash
python3 -m http.server 8000 --directory docs
```

Then open in your browser: `http://localhost:8000/documentation/swiftrestrequests/`

## Publishing to GitHub Pages

Documentation is automatically built and published to GitHub Pages when you push to the `main` branch.

### One-Time Setup

1. **Enable GitHub Pages** in your repository:
   - Go to Settings → Pages
   - Under "Build and deployment":
     - Source: **GitHub Actions**
   - Save

2. **Verify Permissions**:
   - The workflow file `.github/workflows/deploy-docc.yml` has the necessary permissions configured
   - No additional repository settings changes are needed

### Automatic Deployment

The workflow runs automatically on:
- Every push to `main` branch
- Manual trigger via GitHub Actions UI

### Viewing Published Documentation

After the workflow completes, your documentation will be available at:
```
https://tkausch.github.io/SwiftRestRequests/documentation/swiftrestrequests/
```

## Documentation Structure

The documentation is organized in the `Sources/SwiftRestRequests/Documentation.docc/` directory:

```
Documentation.docc/
├── SwiftRestRequests.md              # Main landing page
├── HTTPUtil.swift                    # Additional documentation for HTTPUtil
└── Articles/
    ├── GettingStarted.md            # Getting started guide
    ├── Configuration.md             # Configuration options
    ├── ErrorHandling.md             # Error handling guide
    └── Interceptors.md              # Interceptors guide
```

## Adding New Documentation

### Adding Articles

1. Create a new `.md` file in `Sources/SwiftRestRequests/Documentation.docc/Articles/`
2. Add frontmatter and content:
   ```markdown
   # Article Title
   
   Brief description
   
   ## Overview
   
   Detailed content...
   
   ## Topics
   
   ### Related
   - ``RestApiCaller``
   - ``RestError``
   ```

3. Reference it in `SwiftRestRequests.md`:
   ```markdown
   - <doc:ArticleFileName>
   ```

### Adding Inline Documentation

Add DocC comments to your Swift files:

```swift
/// Brief description.
///
/// Extended description with more details.
///
/// - Parameters:
///   - param1: Description of parameter
///   - param2: Description of parameter
/// - Returns: Description of return value
/// - Throws: ``RestError`` if the request fails
public func myMethod(param1: String, param2: Int) async throws -> Result {
    // implementation
}
```

## Troubleshooting

### Build Fails

- Ensure you're using Xcode 15+ or Swift 5.9+
- Check that all DocC markdown files have valid syntax
- Verify that referenced types (like `RestApiCaller`) exist

### GitHub Pages Not Working

- Confirm GitHub Pages is set to "GitHub Actions" in repository settings
- Check the Actions tab for deployment errors
- Verify the workflow has appropriate permissions (should be automatic)

### Documentation Not Updating

- Clear your browser cache
- Wait a few minutes for GitHub Pages CDN to update
- Check the Actions tab to ensure the workflow completed successfully

## Resources

- [Swift-DocC Documentation](https://www.swift.org/documentation/docc/)
- [Apple DocC Tutorial](https://developer.apple.com/documentation/docc)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
