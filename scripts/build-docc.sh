#!/bin/bash

# Script to build DocC documentation locally
# Usage: ./scripts/build-docc.sh

set -e

echo "🔨 Building DocC documentation for SwiftRestRequests..."

# Create docs directory if it doesn't exist
mkdir -p docs

# Build the documentation (without hosting-base-path for local preview)
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target SwiftRestRequests \
  --output-path ./docs

echo "✅ Documentation built successfully!"
echo "📁 Output directory: ./docs"
echo ""
echo "To preview locally, run:"
echo "  python3 -m http.server 8000 --directory docs"
echo ""
echo "Then open: http://localhost:8000/documentation/swiftrestrequests/"
echo ""
echo "Note: This build is for local preview only."
echo "GitHub Actions will build with --transform-for-static-hosting for deployment."
