#!/bin/bash
set -e

echo "🚀 Setting up __PROJECT_NAME__ Vapor project environment..."

if command -v pre-commit >/dev/null 2>&1; then
  echo "Installing pre-commit hooks..."
  pre-commit install || true
fi

echo "Resolving Swift Package dependencies..."
swift package resolve

echo "✔ Project setup complete! Run 'make run' to start local server."
