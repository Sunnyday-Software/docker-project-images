#!/bin/bash

# Node.js and semantic-release configuration

# Set NPM to save exact versions by default
npm config set save-exact true

# Set NPM to not generate package-lock.json by default in CI environments
if [ "$CI" = "true" ]; then
  npm config set package-lock false
fi

# Add useful Node.js aliases
alias nr='npm run'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'

# Add semantic-release aliases
alias sr='semantic-release'
alias sr-dry='semantic-release --dry-run'
alias sr-debug='DEBUG=semantic-release:* semantic-release'

# Function to initialize a project with semantic-release
function init-semantic-release() {
  # Create .releaserc.json if it doesn't exist
  if [ ! -f .releaserc.json ]; then
    cat > .releaserc.json << EOF
{
  "branches": ["main", "master"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github",
    "@semantic-release/git"
  ]
}
EOF
    echo "Created .releaserc.json"
  fi

  # Add semantic-release to package.json if it doesn't exist
  if [ -f package.json ]; then
    if ! grep -q "semantic-release" package.json; then
      # Use temporary file to avoid issues with in-place editing
      TMP_FILE=$(mktemp)
      jq '.scripts.release = "semantic-release"' package.json > "$TMP_FILE"
      mv "$TMP_FILE" package.json
      echo "Added semantic-release script to package.json"
    fi
  else
    echo "No package.json found. Please create one first with 'npm init'."
  fi

  # Create GitHub Actions workflow file if it doesn't exist
  mkdir -p .github/workflows
  if [ ! -f .github/workflows/release.yml ]; then
    cat > .github/workflows/release.yml << EOF
name: Release
on:
  push:
    branches: [main, master]
jobs:
  release:
    name: Release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: 'lts/*'
      - name: Install dependencies
        run: npm ci
      - name: Release
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: \${{ secrets.NPM_TOKEN }}
        run: npx semantic-release
EOF
    echo "Created GitHub Actions workflow file at .github/workflows/release.yml"
  fi

  echo "Semantic-release initialization complete!"
}

# Export Node.js version
export NODE_VERSION=$(node --version)
echo "Node.js version: $NODE_VERSION"
echo "NPM version: $(npm --version)"
echo "Yarn version: $(yarn --version)"
echo "Semantic-release version: $(semantic-release --version)"

# Print available commands
echo "Available Node.js commands:"
echo "  nr - npm run"
echo "  ni - npm install"
echo "  nid - npm install --save-dev"
echo "  nig - npm install -g"
echo "  ns - npm start"
echo "  nt - npm test"
echo "  nb - npm run build"
echo "  sr - semantic-release"
echo "  sr-dry - semantic-release --dry-run"
echo "  sr-debug - DEBUG=semantic-release:* semantic-release"
echo "  init-semantic-release - Initialize a project with semantic-release"